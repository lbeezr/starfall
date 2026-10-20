#!/usr/bin/env python3
"""Export the deliberately small, validated Observatory utility SVG vocabulary."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import xml.etree.ElementTree as ET

from PIL import Image, ImageChops, ImageDraw, ImageFont, ImageStat
import pypdfium2 as pdfium
from reportlab.pdfgen import canvas


ROOT = Path(__file__).resolve().parents[1]
REPO = ROOT.parents[1]
SVG_NS = "{http://www.w3.org/2000/svg}"
ROLES = {
    "story": ("Story mode", "Lantern; story navigation only."),
    "freeplay": ("Free play", "Four-point comet with three open trails; no orbital ring."),
    "tutorial": ("Tutorial", "Connected constellation with a destination star."),
    "settings": ("Settings", "Orbital adjustment dial; three settings points."),
    "back": ("Back", "Back navigation or previous item."),
    "next": ("Next", "Forward navigation or next item."),
    "play": ("Play", "Begin or resume an action; label supplies the exact verb."),
    "pause": ("Pause", "Pause the active sky."),
    "sound": ("Sound", "Sound preference; state is conveyed by the associated control."),
    "haptic": ("Haptics", "Haptic preference; state is conveyed by the associated control."),
    "calm": ("Calmer effects", "Calmer visual effects preference, using a moon and star."),
    "home": ("Home", "Return to the Observatory home screen."),
    "replay": ("Replay / restart", "Repeat or start again; label supplies the exact consequence."),
    "help": ("Help / hint", "Contextual explanation or tutorial hint."),
    "close": ("Close", "Dismiss the current temporary surface."),
    "list": ("List / steps", "A list of destinations or tutorial steps, with a visible label."),
    "check": ("Complete", "Completion or selection indicator; not a standalone action."),
    "lock": ("Locked", "Unavailable destination; pair with the actual lock reason."),
    "direction": ("Flow direction", "Direction adjustment affordance, not a drag-instruction label."),
    "trace": ("Trace", "Five connected points; associated label explains the actual-star rule."),
}
NUMBER = r"[-+]?(?:\d*\.\d+|\d+\.?\d*)(?:[eE][-+]?\d+)?"
TOKEN = re.compile(r"[MLHVCZ]|" + NUMBER)
COUNTS = {"M": 2, "L": 2, "H": 1, "V": 1, "C": 6, "Z": 0}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def path_commands(data):
    """Reject unsupported SVG syntax instead of approximating its appearance."""
    if re.sub(r"[\s,]+", "", TOKEN.sub("", data)):
        raise ValueError(f"Unsupported path vocabulary: {data}")
    tokens = TOKEN.findall(data)
    index = 0
    while index < len(tokens):
        command = tokens[index]
        if command not in COUNTS:
            raise ValueError("Use explicit absolute commands in these SVG masters")
        count = COUNTS[command]
        numbers = tokens[index + 1:index + 1 + count]
        if len(numbers) != count or any(n in COUNTS for n in numbers):
            raise ValueError(f"Incomplete {command} command")
        yield command, [float(n) for n in numbers]
        index += count + 1


def validate_master(path):
    element = ET.parse(path).getroot()
    expected = {
        "width": "24", "height": "24", "viewBox": "0 0 24 24",
        "fill": "none", "stroke": "currentColor", "stroke-width": "1.5",
        "stroke-linecap": "round", "stroke-linejoin": "round",
    }
    assert element.tag == SVG_NS + "svg", path
    assert set(element.attrib) <= set(expected) | {"role", "aria-labelledby"}, path
    for key, value in expected.items():
        assert element.get(key) == value, (path, key)
    titles = element.findall(SVG_NS + "title")
    assert len(titles) == 1 and titles[0].get("id") == element.get("aria-labelledby"), path
    allowed = {
        "title": {"id"}, "path": {"d"},
        "circle": {"cx", "cy", "r"},
        "rect": {"x", "y", "width", "height", "rx"},
    }
    for child in element:
        tag = child.tag.removeprefix(SVG_NS)
        assert tag in allowed and set(child.attrib) <= allowed[tag], (path, tag)
        assert not list(child), path
        if tag == "path":
            list(path_commands(child.attrib["d"]))
    return element


def vector_pdf(element, target, title):
    """Translate only our validated paths, circles and rounded rectangles."""
    pdf = canvas.Canvas(str(target), pagesize=(24, 24), invariant=1, pageCompression=0)
    pdf.setTitle(f"Starfall — {title}")
    pdf.setAuthor("Starfall / original Observatory UI glyph family")
    pdf.translate(0, 24)
    pdf.scale(1, -1)
    pdf.setStrokeColorRGB(0, 0, 0)
    pdf.setLineWidth(1.5)
    pdf.setLineCap(1)
    pdf.setLineJoin(1)
    for child in element:
        tag = child.tag.removeprefix(SVG_NS)
        a = child.attrib
        if tag == "path":
            shape = pdf.beginPath()
            x = y = start_x = start_y = 0.0
            for command, n in path_commands(a["d"]):
                if command == "M":
                    x, y = start_x, start_y = n
                    shape.moveTo(x, y)
                elif command == "L":
                    x, y = n
                    shape.lineTo(x, y)
                elif command == "H":
                    x = n[0]
                    shape.lineTo(x, y)
                elif command == "V":
                    y = n[0]
                    shape.lineTo(x, y)
                elif command == "C":
                    shape.curveTo(*n)
                    x, y = n[-2:]
                else:
                    shape.close()
                    x, y = start_x, start_y
            pdf.drawPath(shape, stroke=1, fill=0)
        elif tag == "circle":
            pdf.circle(float(a["cx"]), float(a["cy"]), float(a["r"]), stroke=1, fill=0)
        elif tag == "rect":
            pdf.roundRect(*(float(a[k]) for k in ("x", "y", "width", "height")),
                          radius=float(a.get("rx", 0)), stroke=1, fill=0)
    pdf.showPage()
    pdf.save()
    content = target.read_bytes()
    assert b"/Subtype /Image" not in content
    assert b"/MediaBox [ 0 0 24 24 ]" in content


def rasterize(node, modules, jobs, job_path):
    job_path.write_text(json.dumps(jobs))
    script = """
const fs = require('fs');
const sharp = require('sharp');
const jobs = JSON.parse(fs.readFileSync(process.argv[1], 'utf8'));
(async () => {
  for (const j of jobs) {
    const svg = fs.readFileSync(j.source, 'utf8').replaceAll('currentColor', j.color);
    await sharp(Buffer.from(svg), {density: 72 * j.size / 24})
      .resize(j.size, j.size).ensureAlpha().png({compressionLevel: 9}).toFile(j.target);
  }
  process.stdout.write(JSON.stringify({sharp: sharp.versions.sharp, librsvg: sharp.versions.rsvg}));
})().catch(error => { console.error(error); process.exit(1); });
"""
    env = os.environ.copy()
    if modules:
        env["NODE_PATH"] = modules
    result = subprocess.run([node, "-e", script, str(job_path)], check=True,
                            env=env, capture_output=True, text=True)
    return json.loads(result.stdout)


def rgba_metrics(path):
    with Image.open(path) as image:
        assert image.mode == "RGBA", path
        alpha = image.getchannel("A")
        bounds = alpha.getbbox()
        minimum, maximum = alpha.getextrema()
        assert bounds and minimum == 0 and maximum > 0, path
        assert all(image.getchannel(channel).getextrema() == (0, 0) for channel in "RGB"), path
        # No alpha reaches the export frame, including antialiasing.
        assert bounds[0] > 0 and bounds[1] > 0, (path, bounds)
        assert bounds[2] < image.width and bounds[3] < image.height, (path, bounds)
        return list(bounds)


def compare_pdf(svg_raster, pdf_path, output):
    """Check independent renderers agree, allowing ordinary edge antialiasing."""
    with pdfium.PdfDocument(pdf_path) as document:
        assert len(document) == 1, pdf_path
        page = document[0]
        assert page.get_size() == (24, 24), pdf_path
        bitmap = page.render(scale=12, fill_color=(0, 0, 0, 0))
        rendered = bitmap.to_pil().convert("RGBA")
        rendered.save(output)
        bitmap.close()
        page.close()
    bounds = rgba_metrics(output)
    with Image.open(svg_raster) as source:
        a = source.getchannel("A")
    b = rendered.getchannel("A")
    intersection = ImageStat.Stat(ImageChops.darker(a, b)).sum[0]
    union = ImageStat.Stat(ImageChops.lighter(a, b)).sum[0]
    overlap = intersection / union
    assert overlap >= .95, (pdf_path, overlap)
    return dict(scale=12, weighted_alpha_iou=round(overlap, 6), pdf_alpha_bounds_px=bounds)


def preview(temporary, target, font_path, bold_path):
    page = Image.new("RGB", (1400, 1480), "#080f1a")
    draw = ImageDraw.Draw(page)
    title_font = ImageFont.truetype(font_path, 32)
    label_font = ImageFont.truetype(bold_path, 17)
    note_font = ImageFont.truetype(font_path, 14)
    tiny_font = ImageFont.truetype(font_path, 12)
    draw.text((40, 26), "OBSERVATORY  /  UTILITY GLYPHS", font=title_font, fill="#f0e9da")
    draw.text((40, 72), "Original 24-unit masters · 1.5-unit round stroke · actual 20 / 24 / 32 px samples",
              font=note_font, fill="#c2b494")
    for i, (name, (label, _)) in enumerate(ROLES.items()):
        x = 40 + i % 4 * 340
        y = 114 + i // 4 * 222
        draw.rounded_rectangle((x, y, x + 320, y + 204), radius=10,
                               fill="#101c2c", outline="#645642", width=1)
        draw.text((x + 15, y + 12), label, font=label_font, fill="#f0e9da")
        draw.text((x + 15, y + 37), name + ".svg", font=tiny_font, fill="#aaa190")
        draw.rounded_rectangle((x + 12, y + 123, x + 308, y + 192), radius=5, fill="#e9e4da")
        for column, size in enumerate((20, 24, 32)):
            center = x + 59 + column * 101
            draw.text((center, y + 61), str(size), font=tiny_font, fill="#b7afa1", anchor="mt")
            for theme, center_y in (("dark", y + 98), ("light", y + 160)):
                icon = Image.open(temporary / f"{name}-{theme}-{size}.png")
                page.paste(icon, (center - size // 2, center_y - size // 2), icon)
    draw.text((40, 1234), "VECTOR EXPORT CHECK  /  SVG → PNG vs independent PDF rendition, enlarged for inspection", font=label_font, fill="#f0e9da")
    for i, name in enumerate(("freeplay", "settings", "calm")):
        x = 40 + i * 450
        draw.text((x, 1270), ROLES[name][0], font=note_font, fill="#c2b494")
        for offset, suffix, label in ((130, "bounds", "SVG"), (264, "pdf", "PDF")):
            source = Image.open(temporary / f"{name}-{suffix}.png")
            alpha = source.getchannel("A").resize((96, 96), Image.Resampling.LANCZOS)
            ink = Image.new("RGBA", (96, 96), "#f0e9da")
            ink.putalpha(alpha)
            page.paste(ink, (x + offset, 1300), ink)
            draw.text((x + offset + 48, 1403), label, font=tiny_font, fill="#aaa190", anchor="mt")
    draw.text((40, 1443), "Template assets only. Native optical size, touch targets, VoiceOver and device contrast still require app validation.",
              font=note_font, fill="#aaa190")
    page.save(target, optimize=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--node", default="node")
    parser.add_argument("--node-modules", default=None)
    parser.add_argument("--font", default="/System/Library/Fonts/Supplemental/Arial.ttf")
    parser.add_argument("--bold-font", default="/System/Library/Fonts/Supplemental/Arial Bold.ttf")
    args = parser.parse_args()
    masters = ROOT / "masters/glyphs"
    exports = ROOT / "exports/glyphs"
    previews = ROOT / "previews"
    exports.mkdir(parents=True, exist_ok=True)
    previews.mkdir(parents=True, exist_ok=True)
    assert {p.stem for p in masters.glob("*.svg")} == set(ROLES)
    entries = []
    with tempfile.TemporaryDirectory(prefix="starfall-glyphs-") as temp_name:
        temp = Path(temp_name)
        jobs = []
        for name, (label, description) in ROLES.items():
            source = masters / f"{name}.svg"
            element = validate_master(source)
            vector_pdf(element, exports / f"{name}.pdf", label)
            for scale in (1, 2, 3):
                jobs.append(dict(source=str(source), target=str(exports / f"{name}@{scale}x.png"),
                                 color="#000000", size=24 * scale))
            jobs.append(dict(source=str(source), target=str(temp / f"{name}-bounds.png"),
                             color="#000000", size=288))
            for size in (20, 24, 32):
                for theme, color in (("dark", "#f0e9da"), ("light", "#172638")):
                    jobs.append(dict(source=str(source), target=str(temp / f"{name}-{theme}-{size}.png"),
                                     color=color, size=size))
        versions = rasterize(args.node, args.node_modules, jobs, temp / "jobs.json")
        for name, (label, description) in ROLES.items():
            high_bounds = rgba_metrics(temp / f"{name}-bounds.png")
            comparison = compare_pdf(temp / f"{name}-bounds.png", exports / f"{name}.pdf", temp / f"{name}-pdf.png")
            files = []
            for scale in (1, 2, 3):
                file = exports / f"{name}@{scale}x.png"
                bounds = rgba_metrics(file)
                with Image.open(file) as image:
                    assert image.size == (24 * scale, 24 * scale), file
                files.append(dict(path=str(file.relative_to(ROOT)), scale=scale,
                                  pixels=[24 * scale, 24 * scale], alpha_bounds_px=bounds,
                                  sha256=digest(file)))
            master = masters / f"{name}.svg"
            pdf = exports / f"{name}.pdf"
            entries.append(dict(id=name, role=label, usage=description,
                                svg=dict(path=str(master.relative_to(ROOT)), sha256=digest(master)),
                                pdf=dict(path=str(pdf.relative_to(ROOT)), points=[24, 24], sha256=digest(pdf)),
                                png=files, ink_bounds_24=[round(n / 12, 4) for n in high_bounds],
                                svg_pdf_comparison=comparison))
        preview(temp, previews / "glyphs.png", args.font, args.bold_font)
    ancestor = REPO / "docs/design/interface/atlas-2026-10-19/glyphs.svg"
    manifest = {
        "schema_version": 1, "family": "Starfall Observatory utility glyphs", "count": len(entries),
        "authored_date": "2026-10-19", "canvas": [24, 24], "stroke_width": 1.5,
        "line_cap": "round", "line_join": "round", "fill": "none",
        "color_behavior": {
            "svg": "currentColor; no baked glow, background, text or palette",
            "png": "black RGB with antialiased alpha; 24-point templates at 1x, 2x and 3x",
            "pdf": "black stroked vector paths on a transparent 24-by-24-point page",
            "native_intent": "Template rendering with a semantic foreground tint; app membership is not added by this kit",
        },
        "provenance": {
            "original_work": True, "authoring": "Original assistant-authored SVG geometry, refined for this Starfall utility family; no icon library or generated bitmap source",
            "concept_source": str(ancestor.relative_to(REPO)), "concept_source_sha256": digest(ancestor),
            "production_source": "masters/glyphs/*.svg are authoritative; exports are derived",
            "refinements": "Open comet trails, simpler interiors, separated trace points, consistent stroke weight and safe frame margins",
        },
        "bounds_method": "Nonzero-alpha support rasterized at 12x, divided by 12; approximate stroked ink bounds, not path control bounds. Max edges are exclusive.",
        "generator": "build/glyphs.py", "renderer_versions": versions,
        "validation": {
            "xml": "20 standalone SVGs parsed; explicit absolute paths, circles and rounded rectangles only",
            "png": "60 RGBA exports checked for dimensions, nonempty alpha, black template ink and transparent outer frame",
            "pdf": "20 single-page 24-point PDFs checked for vector-only content, page bounds, transparent frame and independent PDFium rendering at 12x; weighted alpha overlap with SVG rendering is at least 0.95",
            "native": "Not imported, built or tested in the app. 20/24/32 preview pixels are optical specimens, not verified native dimensions or touch targets.",
        },
        "preview": "previews/glyphs.png", "glyphs": entries,
    }
    (ROOT / "glyph-manifest.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n")
    print(f"Validated {len(entries)} SVG masters, {len(entries) * 3} template PNGs, {len(entries)} vector PDFs; wrote manifest and preview.")


if __name__ == "__main__":
    main()
