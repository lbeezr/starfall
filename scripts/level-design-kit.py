#!/usr/bin/env python3
"""Generate technical authoring guides from the app's exported geometry.

Default: compile/run export_level_layouts.swift with the already-built Core module.
Offline: --layouts-json /path/to/export.json (records that supplied snapshot's hash).
Requires Pillow. No generated paintings are read, resampled, or modified.
"""

from __future__ import annotations

import argparse
import base64
import hashlib
import html
import json
import math
import os
import re
from pathlib import Path
import subprocess
import tempfile

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "docs/design/level-design-kit"
SUNNY = ROOT / "App/Assets.xcassets/SkyPieceSunny.imageset/body.png"
SOURCES = (
    "App/LandingGeometry.swift", "scripts/export_level_layouts.swift",
    "App/FallingSkyView.swift", "App/FallingSkyHUD.swift",
    "App/SkyDialogueBubble.swift", "App/ObservatoryArtwork.swift",
    "App/RestorationEnvironment.swift",
    "App/SkyFlowCeremony.swift", "App/StarfallTheme.swift",
    "App/FallingSkyMotion.swift", "App/StarCast.swift", "App/SkyPiece.swift",
    "App/Assets.xcassets/SkyPieceSunny.imageset/body.png",
    "scripts/level-design-kit.py",
)
REFERENCES = {
    "phone": ("iPhone", 887, 1774),
    "ipad-portrait": ("iPad portrait", 1086, 1448),
    "ipad-landscape": ("iPad landscape", 1448, 1086),
}
PALETTE = {
    "page": "#101b2c", "panel": "#152638", "world": "#164a50",
    "worldLine": "#49c7ba", "board": "#602f41", "boardLine": "#ed8e9e",
    "bleed": "#987034", "bleedLine": "#ffd68a", "ui": "#523b79",
    "uiLine": "#c7b1f8", "text": "#f5f6f7", "muted": "#bdcbd8",
    "grid": "#a56478", "crop": "#304153", "cropLine": "#d4dce6",
}
BLEED_FRACTION = 0.15


def swift_scalar(path: str, name: str) -> float:
    source = (ROOT / path).read_text()
    matches = re.findall(r"static let " + re.escape(name) + r"(?:\s*:\s*[A-Za-z]+)?\s*=\s*([0-9.]+)(?:\s|$)", source)
    if len(matches) != 1:
        raise ValueError(f"Expected one numeric production constant: {path}:{name}")
    return float(matches[0])


# Read the production owners; the guide must not retain independent growth sizing.
BODY_FRACTIONS = {
    "normal": 2 * swift_scalar("App/FallingSkyMotion.swift", "pieceRadius"),
    "grown": 2 * swift_scalar("App/FallingSkyMotion.swift", "grownPieceRadius"),
}
RASTER_SIDE = swift_scalar("App/StarCast.swift", "rasterSide")
SILHOUETTE_SIDE = swift_scalar("App/StarCast.swift", "silhouetteSide")
SUNNY_IMAGE = Image.open(SUNNY).convert("RGBA")
SUNNY_BOUNDS = SUNNY_IMAGE.getbbox()
if SUNNY_IMAGE.size != (RASTER_SIDE, RASTER_SIDE) or SUNNY_BOUNDS is None:
    raise ValueError("SkyPieceSunny no longer matches the shared centered raster registration")
SUNNY_EXTENT = max(SUNNY_BOUNDS[2] - SUNNY_BOUNDS[0], SUNNY_BOUNDS[3] - SUNNY_BOUNDS[1])
VISIBLE_FRACTIONS = {key: value * SUNNY_EXTENT / SILHOUETTE_SIDE for key, value in BODY_FRACTIONS.items()}


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def exported_layouts(args: argparse.Namespace) -> tuple[dict, dict]:
    if args.layouts_json:
        raw = Path(args.layouts_json).read_bytes()
        provenance = {
            "method": "supplied-export-snapshot",
            "inputSHA256": hashlib.sha256(raw).hexdigest(),
            "inputPath": str(Path(args.layouts_json).resolve()),
            "sourceOwnership": "unverified-offline-snapshot",
            "limitation": "Original source hashes, when supplied, are preserved. Generation-time hashes do not validate these rectangles; compile a fresh export before native authoring acceptance.",
        }
    else:
        products = Path(args.core_products).resolve()
        cache = Path(tempfile.gettempdir()) / "starfall-guide-module-cache"
        cache.mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(prefix="starfall-level-guide-") as temporary:
            binary = Path(temporary) / "export-level-layouts"
            command = ["swiftc", "-module-cache-path", str(cache), "-I", str(products),
                       "-L", str(products), "-lStarfallCore", "App/LandingGeometry.swift",
                       "scripts/export_level_layouts.swift", "-o", str(binary)]
            subprocess.run(command, cwd=ROOT, check=True, timeout=60)
            environment = os.environ.copy()
            environment["DYLD_LIBRARY_PATH"] = str(products) + os.pathsep + environment.get("DYLD_LIBRARY_PATH", "")
            raw = subprocess.run([str(binary)], cwd=ROOT, env=environment, check=True,
                                 timeout=15, capture_output=True).stdout
        provenance = {"method": "compiled-app-geometry", "inputSHA256": hashlib.sha256(raw).hexdigest(),
                      "sourceOwnership": "compiled-current-sources",
                      "command": "swiftc -module-cache-path <temporary-cache> -I <core-products> -L <core-products> -lStarfallCore App/LandingGeometry.swift scripts/export_level_layouts.swift -o <temporary-exporter>",
                      "coreProducts": str(products)}
    exported = json.loads(raw)
    layouts = exported["layouts"]
    if len(layouts) != 6 or not set(REFERENCES).issubset({item["id"] for item in layouts}):
        raise ValueError("Expected three normal references plus three expanded/accessibility layouts")
    for layout in layouts:
        if len(layout["cells"]) != 49 or len({(c["row"], c["column"]) for c in layout["cells"]}) != 49:
            raise ValueError(f"Incomplete native grid: {layout['id']}")
        for cell in layout["cells"]:
            frame, board = cell["frame"], layout["board"]
            if not (board["x"] - 1e-6 <= frame["x"] and board["y"] - 1e-6 <= frame["y"]
                    and frame["x"] + frame["width"] <= board["x"] + board["width"] + 1e-6
                    and frame["y"] + frame["height"] <= board["y"] + board["height"] + 1e-6):
                raise ValueError(f"Cell outside exported board: {layout['id']}")
    return exported, provenance


def rect(x: float, y: float, width: float, height: float) -> dict:
    return dict(x=x, y=y, width=width, height=height)


def inset(frame: dict, amount: float) -> dict:
    return rect(frame["x"] + amount, frame["y"] + amount,
                frame["width"] - 2 * amount, frame["height"] - 2 * amount)


def source_mapping(layout: dict, width: int, height: int) -> dict:
    # Authoring conversion only. Native game rectangles always come from Swift.
    scale = max(layout["width"] / width, layout["height"] / height)
    origin_x = (layout["width"] - width * scale) / 2
    origin_y = (layout["height"] - height * scale) / 2
    return {"sourceWidth": width, "sourceHeight": height, "nativePointsPerArtPixel": scale,
            "imageOriginInNativePoints": {"x": origin_x, "y": origin_y},
            "visibleSourceRect": rect(-origin_x / scale, -origin_y / scale,
                                      layout["width"] / scale, layout["height"] / scale),
            "method": "center-cover baseline, not the runtime focal-adjusted transform"}


def mapped_rect(frame: dict, mapping: dict) -> dict:
    scale, origin = mapping["nativePointsPerArtPixel"], mapping["imageOriginInNativePoints"]
    return rect((frame["x"] - origin["x"]) / scale, (frame["y"] - origin["y"]) / scale,
                frame["width"] / scale, frame["height"] / scale)


def font(size: float, bold: bool = False) -> ImageFont.FreeTypeFont:
    choices = (["/System/Library/Fonts/Supplemental/Arial Bold.ttf"] if bold else
               ["/System/Library/Fonts/Supplemental/Arial.ttf"])
    choices += ["/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"]
    for path in choices:
        if Path(path).exists():
            return ImageFont.truetype(path, max(1, round(size)))
    return ImageFont.load_default(size=max(1, round(size)))


class Drawing:
    """One set of diagram primitives writes both SVG and a Pillow preview."""

    def __init__(self, width: int, height: int, title: str):
        self.width, self.height = width, height
        self.image = Image.new("RGB", (width, height), PALETTE["page"])
        self.draw = ImageDraw.Draw(self.image)
        self.parts = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}" role="img">',
                      f"<title>{html.escape(title)}</title>",
                      '<desc>Technical authoring guide. Board and cells are exported from LandingGeometry. UI edge markers are schematic responsibilities, not measured coverage. Colored composition recommendations are not native acceptance evidence.</desc>']
        self.rectangle(rect(0, 0, width, height), PALETTE["page"])

    def rectangle(self, frame: dict, fill: str, stroke: str | None = None, line: float = 1):
        x, y, w, h = (frame[k] for k in ("x", "y", "width", "height"))
        self.parts.append(f'<rect x="{x:.4f}" y="{y:.4f}" width="{w:.4f}" height="{h:.4f}" fill="{fill}" stroke="{stroke or "none"}" stroke-width="{line}"/>')
        self.draw.rectangle((x, y, x + w, y + h), fill=None if fill == "none" else fill,
                            outline=stroke, width=max(1, round(line)))

    def line(self, points: list[tuple[float, float]], color: str, width: float = 1):
        self.parts.append('<polyline points="' + " ".join(f"{x:.4f},{y:.4f}" for x, y in points)
                          + f'" fill="none" stroke="{color}" stroke-width="{width}"/>')
        self.draw.line(points, fill=color, width=max(1, round(width)))

    def text(self, x: float, y: float, message: str, size: float = 16, color: str | None = None,
             bold: bool = False, anchor: str = "left"):
        color = color or PALETTE["text"]
        align = {"left": "start", "center": "middle", "right": "end"}[anchor]
        self.parts.append(f'<text x="{x:.4f}" y="{y:.4f}" fill="{color}" font-family="Arial, sans-serif" font-size="{size}" font-weight="{700 if bold else 400}" text-anchor="{align}" dominant-baseline="hanging">{html.escape(message)}</text>')
        self.draw.text((x, y), message, font=font(size, bold), fill=color,
                       anchor={"left": "lt", "center": "mt", "right": "rt"}[anchor])

    def sunny(self, x: float, y: float, nominal_width: float, opacity: float = 1):
        # The authored shell uses SkyPiece.makeNode's radius-to-raster formula.
        # Native LivingLight interior composition and shader are deliberately omitted.
        # Alpha bounds are measured for annotation only, never stretched to fill a cell.
        data = SUNNY.read_bytes()
        scale = nominal_width / SILHOUETTE_SIDE
        width, height = SUNNY_IMAGE.width * scale, SUNNY_IMAGE.height * scale
        left, top = x - width / 2, y - height / 2
        if not getattr(self, "sunny_defined", False):
            self.parts.append(f'<defs><image id="sky-piece-sunny" width="{SUNNY_IMAGE.width}" height="{SUNNY_IMAGE.height}" href="data:image/png;base64,{base64.b64encode(data).decode()}"/></defs>')
            self.sunny_defined = True
        self.parts.append(f'<use href="#sky-piece-sunny" transform="translate({left:.4f} {top:.4f}) scale({scale:.6f})" opacity="{opacity}"/>')
        resized = SUNNY_IMAGE.resize((round(width), round(height)), Image.Resampling.LANCZOS)
        if opacity < 1:
            resized.putalpha(resized.getchannel("A").point(lambda value: round(value * opacity)))
        self.image.paste(resized, (round(left), round(top)), resized)

    def paste(self, other: "Drawing", x: float, y: float, scale: float):
        self.parts.append(f'<g transform="translate({x} {y}) scale({scale})">')
        self.parts.extend(other.parts[2:])
        self.parts.append("</g>")
        resized = other.image.resize((round(other.width * scale), round(other.height * scale)), Image.Resampling.LANCZOS)
        self.image.paste(resized, (round(x), round(y)))

    def save_svg(self, path: Path):
        path.write_text("\n".join(self.parts + ["</svg>"]) + "\n")


def draw_layout(layout: dict, mapping: dict | None = None) -> Drawing:
    title = REFERENCES[layout["id"]][0]
    width = mapping["sourceWidth"] if mapping else layout["width"]
    height = mapping["sourceHeight"] if mapping else layout["height"]
    canvas = Drawing(width, height, title + (" source artwork guide" if mapping else " native geometry guide"))
    canvas.rectangle(rect(0, 0, width, height), PALETTE["world"])
    convert = (lambda value: mapped_rect(value, mapping)) if mapping else (lambda value: value)
    scale = 1 / mapping["nativePointsPerArtPixel"] if mapping else 1
    board = convert(layout["board"])
    bleed = layout["cellStep"] * BLEED_FRACTION * scale
    canvas.rectangle(board, PALETTE["bleed"], PALETTE["bleedLine"], 1.4 * scale)
    canvas.rectangle(inset(board, bleed), PALETTE["board"])
    for cell in layout["cells"]:
        frame = convert(cell["frame"])
        canvas.rectangle(frame, "none", PALETTE["grid"], 0.7 * scale)
        grown = cell["row"] == 5 and cell["column"] == 4
        side = frame["width"] * BODY_FRACTIONS["grown" if grown else "normal"]
        canvas.sunny(frame["x"] + frame["width"] / 2, frame["y"] + frame["height"] / 2,
                     side, 1 if grown else 0.42)
    # The current HUD and guide use measured SwiftUI content at viewport edges.
    # LandingGeometry's former chrome rectangles are not their coverage. Use
    # schematic markers rather than inventing safe insets or fixed text heights.
    for y, label_y, label in (
        (85, 62, "TOP HUD · inset and height vary"),
        (layout["height"] - 49, layout["height"] - 40, "BOTTOM GUIDE / ACTIONS · height varies"),
    ):
        first = convert(rect(12, y, 0, 0))
        last = convert(rect(layout["width"] - 12, y, 0, 0))
        middle = convert(rect(layout["width"] / 2, label_y, 0, 0))
        canvas.line([(first["x"], first["y"]), (last["x"], last["y"])],
                    PALETTE["uiLine"], 2 * scale)
        canvas.text(middle["x"], middle["y"], label, 11 * scale,
                    color=PALETTE["uiLine"], bold=True, anchor="center")
    point = convert(rect(layout["width"] / 2, layout["height"] - 23, 0, 0))
    canvas.text(point["x"], point["y"], "UI markers are schematic, not coverage bounds", 9 * scale,
                color=PALETTE["uiLine"], anchor="center")
    # Labels are authoring annotations, never an instruction to paint a gap.
    point = convert(rect(layout["width"] / 2, 14, 0, 0))
    canvas.text(point["x"], point["y"], title, 18 * scale, bold=True, anchor="center")
    units = f'{width} × {height} art px · center-cover' if mapping else f'{width} × {height} native pt'
    point = convert(rect(layout["width"] / 2, 36, 0, 0))
    canvas.text(point["x"], point["y"], units, 11 * scale, anchor="center")
    point = convert(rect(layout["width"] / 2, max(110, layout["board"]["y"] / 2), 0, 0))
    canvas.text(point["x"], point["y"], "Build rich connected world here", 14 * scale,
                color=PALETTE["worldLine"], bold=True, anchor="center")
    canvas.text(board["x"] + board["width"] / 2, board["y"] + board["height"] / 2 - 9 * scale,
                "CONTRAST PRIORITY", 14 * scale, bold=True, anchor="center")
    canvas.text(board["x"] + board["width"] / 2, board["y"] + board["height"] / 2 + 10 * scale,
                "Continue the world; keep stars readable", 10 * scale, anchor="center")
    if mapping:
        visible = mapping["visibleSourceRect"]
        margins = [rect(0, 0, visible["x"], height),
                   rect(visible["x"] + visible["width"], 0, width - visible["x"] - visible["width"], height),
                   rect(visible["x"], 0, visible["width"], visible["y"]),
                   rect(visible["x"], visible["y"] + visible["height"], visible["width"], height - visible["y"] - visible["height"])]
        for margin in margins:
            if margin["width"] < 0.01 or margin["height"] < 0.01:
                continue
            canvas.rectangle(margin, PALETTE["crop"], PALETTE["cropLine"], 1)
            # Short diagonal marks stay inside the cropped margin.
            pitch = 16 * scale
            x, y, w, h = (margin[k] for k in ("x", "y", "width", "height"))
            for offset in range(0, math.ceil(h + w), max(1, round(pitch))):
                start_x, start_y = x + max(0, offset - h), y + min(h, offset)
                end_x, end_y = x + min(w, offset), y + max(0, offset - w)
                canvas.line([(start_x, start_y), (end_x, end_y)], PALETTE["cropLine"], scale * 0.6)
        canvas.rectangle(visible, "none", PALETTE["text"], scale)
    return canvas


def overview(layouts: dict[str, dict], panels: dict[str, Drawing]) -> Drawing:
    canvas = Drawing(1800, 1300, "Starfall level authoring: native geometry and composition priorities")
    canvas.text(48, 35, "Compose a whole place around the playable sky", 42, bold=True)
    canvas.text(48, 91, "Exact app geometry + provisional art direction. These are guides, not masks or native visual acceptance.", 24, PALETTE["muted"])
    legends = [
        ("world", "CONNECTED WORLD", ["Layer architecture, terrain and paths.", "Teal is opportunity, not a fill quota."]),
        ("board", "CONTRAST PRIORITY", ["Keep pieces and silhouettes distinct.", "Red does not mean blank or cut out."]),
        ("bleed", "SOFT EDGE BLEED", ["Up to 0.15 cell inside board edge.", "Provisional; never obscure bodies."]),
        ("ui", "VIEWPORT-EDGE UI", ["Markers show placement, not bounds.", "Measure actual HUD, guide and actions."]),
    ]
    for index, (color, title, lines) in enumerate(legends):
        x = 48 + index * 440
        canvas.rectangle(rect(x, 149, 26, 26), PALETTE[color], PALETTE["text"])
        canvas.text(x + 38, 150, title, 20, bold=True)
        for line, message in enumerate(lines):
            canvas.text(x, 190 + line * 28, message, 19, PALETTE["muted"])
    positions = {"phone": (48, 322, 0.80), "ipad-portrait": (430, 322, 0.665),
                 "ipad-landscape": (995, 322, 0.74)}
    for key, (x, y, scale) in positions.items():
        layout = layouts[key]
        canvas.text(x, 271, f'{REFERENCES[key][0]}  ·  {layout["width"]} × {layout["height"]} pt', 23, bold=True)
        canvas.paste(panels[key], x, y, scale)
        board = layout["board"]
        lines = [f'Board: ({board["x"]:g}, {board["y"]:g}) · {board["width"]:g} pt square',
                 f'Cell: {layout["cellStep"]:.2f} pt · edge bleed ≤ {layout["cellStep"] * BLEED_FRACTION:.2f} pt',
                 "Independent preview scales."]
        for index, message in enumerate(lines):
            canvas.text(x, 1030 + index * 28, message, 19, PALETTE["muted"])
    canvas.line([(48, 1134), (1752, 1134)], PALETTE["muted"])
    notes = ["Protect one completion landmark and its light recipient from cells and UI; keep the rest of the world generous.",
             "Result UI uses a central column up to 480 pt wide. Its height and scenery clearance vary; check the actual result.",
             "Expanded / accessibility UI reflows outside the scrolling board. Six geometry exports are in native-layouts.json.",
             "Artwork guides use center-cover baseline crops. Runtime focal adjustment can shift the whole painting; verify each registered asset."]
    for index, message in enumerate(notes):
        canvas.text(48, 1151 + index * 32, message, 21, PALETTE["muted"])
    return canvas


def scale_reference() -> Drawing:
    canvas = Drawing(1600, 1060, "Starfall gameplay piece and environmental prop scale reference")
    canvas.text(48, 36, "Use the authored shell to check gameplay piece scale", 39, bold=True)
    canvas.text(48, 91, "Unchanged SkyPieceSunny shell at production sizing; native living-light fill, shader, aura and deformation are omitted.", 23, PALETTE["muted"])
    canvas.text(48, 137, f"Nominal diameters: ordinary {BODY_FRACTIONS['normal']:.2f} cell · grown {BODY_FRACTIONS['grown']:.2f} cell. Visible extents: {VISIBLE_FRACTIONS['normal']:.3f} / {VISIBLE_FRACTIONS['grown']:.3f}; aura extends farther.", 23, PALETTE["muted"])
    cell = 160
    for x, fraction, label in ((100, BODY_FRACTIONS["normal"], "Ordinary"), (360, BODY_FRACTIONS["grown"], "Grown")):
        canvas.rectangle(rect(x, 205, cell, cell), PALETTE["board"], PALETTE["boardLine"], 2)
        canvas.sunny(x + cell / 2, 285, cell * fraction)
        canvas.text(x + cell / 2, 389, f'{label} · {fraction:.2f} cell', 24, bold=True, anchor="center")
    canvas.text(615, 207, "A star is a scale anchor, not a prop-size ceiling.", 29, bold=True)
    canvas.text(615, 255, "Let large structures establish a place; repeat smaller", 23, PALETTE["muted"])
    canvas.text(615, 289, "details to give it craft, depth and a sense of habitation.", 23, PALETTE["muted"])
    canvas.text(615, 337, "Below, 1 normal-star body width = 80 diagram px.", 23, PALETTE["muted"])
    canvas.line([(48, 450), (1552, 450)], PALETTE["muted"])
    canvas.text(48, 479, "Suggested starting bands for environmental props", 31, bold=True)
    bands = [("Detail", "0.5–1 star", 0.5, 1, "Small lamps, flowers, trim and fittings"),
             ("Secondary", "2–3 stars", 2, 3, "Benches, planters, gates and small platforms"),
             ("Hero", "4–6 stars", 4, 6, "The identifying structure or restoration feature")]
    for index, (title, label, minimum, maximum, examples) in enumerate(bands):
        y = 555 + index * 126
        canvas.text(48, y, title, 26, bold=True)
        canvas.text(48, y + 36, label, 23, PALETTE["worldLine"])
        canvas.sunny(320, y + 27, 80 * SILHOUETTE_SIDE / SUNNY_EXTENT)
        canvas.rectangle(rect(410, y + 2, maximum * 80, 54), PALETTE["world"], PALETTE["worldLine"], 2)
        canvas.rectangle(rect(410, y + 2, minimum * 80, 54), "#266d6b", PALETTE["worldLine"], 2)
        canvas.text(930, y + 12, examples, 21, PALETTE["muted"])
    canvas.line([(48, 951), (1552, 951)], PALETTE["muted"])
    canvas.text(48, 972, "Recommendations, not hard quotas: a bridge, tree canopy or terrace can exceed the hero band when composition calls for it.", 22, PALETTE["muted"])
    canvas.text(48, 1007, "Judge visual hierarchy at real native scale. Preserve silhouettes, touch readability and the completion landmark through every stage.", 22, PALETTE["muted"])
    return canvas


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--layouts-json", type=Path, help="Use a previously captured Swift exporter JSON; no native formula is recreated")
    parser.add_argument("--core-products", type=Path, default=ROOT / ".build/out/Products/Debug", help="Existing StarfallCore module/library directory for Swift exporter")
    parser.add_argument("--output", type=Path, default=OUTPUT)
    args = parser.parse_args()
    exported, provenance = exported_layouts(args)
    layouts = {layout["id"]: layout for layout in exported["layouts"]}
    args.output.mkdir(parents=True, exist_ok=True)
    panels, mappings = {}, {}
    for key, (_, width, height) in REFERENCES.items():
        panels[key] = draw_layout(layouts[key])
        panels[key].save_svg(args.output / f"{key}.svg")
        mappings[key] = source_mapping(layouts[key], width, height)
        source_panel = draw_layout(layouts[key], mappings[key])
        source_panel.save_svg(args.output / f"source-{key}.svg")
        source_panel.image.save(args.output / f"source-{key}.png")
    overview(layouts, panels).image.save(args.output / "overview.png")
    plate = scale_reference()
    plate.save_svg(args.output / "scale-reference.svg")
    plate.image.save(args.output / "scale-reference.png")
    generation_hashes = {path: digest(ROOT / path) for path in SOURCES}
    source_hashes = (generation_hashes if provenance["method"] == "compiled-app-geometry"
                     else exported.get("sourceSHA256", {}))
    report = {**exported, "guideSchemaVersion": 4, "status": "technical authoring guide; not native visual acceptance",
              "geometryExport": provenance, "sourceSHA256": source_hashes,
              "generationSourceSHA256": generation_hashes,
              "units": {"nativeLayouts": "points", "sourcePanels": "artwork pixels", "origin": "top-left; positive y downward; Core row 0 is the bottom row"},
              "sourcePanelMappings": mappings,
              "recommendations": {
                  "softBleedCellFraction": BLEED_FRACTION,
                  "softBleedStatus": "provisional maximum inside the perimeter, not permission to cover gameplay pieces or bright silhouettes",
                  "nativeBodyWidthFractions": BODY_FRACTIONS,
                  "bodyScaleStatus": "authored SkyPieceSunny shell at production sizing; native LivingLight fill/shader, aura and deformation are omitted",
                  "pieceScale": {"material": str(SUNNY.relative_to(ROOT)), "rasterSide": RASTER_SIDE,
                                 "registeredSilhouetteSide": SILHOUETTE_SIDE, "alphaBounds": SUNNY_BOUNDS,
                                 "visibleMaximumCellFractions": VISIBLE_FRACTIONS,
                                 "radiusOwner": "App/FallingSkyMotion.swift:StarfallMotion",
                                 "materialOwner": "App/SkyPiece.swift:makeNode",
                                 "registrationOwner": "App/StarCast.swift"},
                  "propSizeBandsInNormalStarBodies": {"detail": [0.5, 1], "secondary": [2, 3], "hero": [4, 6]},
                  "propScaleStatus": "starting bands, not hard quotas or a cap on whole scenery",
                  "world": "Build a rich connected place; continuity, supporting structures and depth remain behind all overlays",
                  "board": "Contrast priority, not a blank area, mask, crop or compositing seam",
                  "landmark": "Place the completion landmark and recipient away from native cells, label allocations and result coverage",
                  "ui": "Violet viewport-edge markers are schematic, not measured coverage bounds. FallingSkyView places a ViewThatFits HUD at the safe top and a dynamically measured dialogue/action group at the safe bottom. Insets, text, forecast mode and Observatory skins affect actual coverage; inspect native captures.",
                  "legacyGeometryReservations": "LandingGeometry crownFrame, communicationContentFrame and actionFrame values are retained only as unused geometry references. They do not locate the current HUD, dialogue or action controls and are not drawn as protected UI rectangles.",
                  "result": "Central column up to 480 pt; height is content/Dynamic-Type dependent. Heading clearance uses the resolved scenery anchor and a 230 pt baseline; inspect actual result UI",
                  "expanded": "Reading-heavy and accessibility layouts put the HUD above a scrolling board and the guide/actions after it. Legacy reservation rectangles do not describe this flow. Wide 1024×1200 uses portrait restoration art",
                  "crop": "Hatched margins are cropped by the center-cover reference only. Do not place essential story details there; runtime uses focal-adjusted whole-image placement",
              }}
    (args.output / "native-layouts.json").write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")
    reviewer_contract = {
        "schemaVersion": 1,
        "status": "composition review with authored shells; no native LivingLight fill/shader, aura, UI or motion acceptance",
        "geometryExport": provenance["sourceOwnership"],
        "sourceSHA256": source_hashes,
        "layouts": {key: {"width": value["width"], "height": value["height"],
                          "board": value["board"], "cellStep": value["cellStep"]}
                    for key, value in layouts.items() if key in REFERENCES},
        "piece": {"assetPrefix": "SkyPiece", "rasterSide": RASTER_SIDE,
                  "silhouetteSide": SILHOUETTE_SIDE, "diameterFractions": BODY_FRACTIONS},
    }
    (args.output / "reference-layouts.js").write_text(
        "// Generated by scripts/level-design-kit.py. Native owners and source hashes are retained.\n"
        + "window.STARFALL_LEVEL_DESIGN_KIT = "
        + json.dumps(reviewer_contract, indent=2, sort_keys=True) + ";\n")
    print(json.dumps({"output": str(args.output), "layouts": len(exported["layouts"]),
                      "nativePanels": len(panels), "sourcePanels": len(mappings),
                      "geometryMethod": provenance["method"], "sunnySHA256": digest(SUNNY)}, indent=2))


if __name__ == "__main__":
    main()
