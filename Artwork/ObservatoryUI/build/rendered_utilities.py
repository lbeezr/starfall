#!/usr/bin/env python3
"""Export unchanged ImageGen utility masters through the existing offline Sharp pipeline.

Input: masters/utilities-v2/{story,...,trace}.png and PROMPTS.json. The provenance
document uses version 1, generator "Built-in ImageGen", and one assets entry per
glyph with key, master (filename), source, sourceSHA256, and the exact prompt.

Registration uses the alpha >= 16 visible-subject bounds plus four source pixels
of antialiasing bleed. That crop is fitted proportionally into 20 points on a
transparent 24-point canvas. Retained pixel colors/alpha are untouched before
resampling; low-alpha pixels discarded outside the crop are counted explicitly.
No matte removal, recoloring, painting, or per-icon correction occurs.

By default this writes only source-kit exports and their manifest. Explicit
--catalog-root replaces the twenty registered image sets after the entire family
passes validation. Historical SVG masters, PDFs, and glyph exports are untouched.
"""

import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile


ROOT = Path(__file__).resolve().parents[1]
GLYPHS = (
    "story", "freeplay", "tutorial", "settings", "back", "next", "play", "pause",
    "sound", "haptic", "calm", "home", "replay", "help", "close", "list", "check",
    "lock", "direction", "trace",
)
POINTS = 24
PADDING = 2
SUBJECT_ALPHA = 16
SOURCE_BLEED = 4
DENSITIES = (1, 2, 3)
MAX_MASTER_BYTES = 32 * 1024 * 1024
MAX_ALL_MASTER_BYTES = 256 * 1024 * 1024
MAX_EXPORT_BYTES = 64 * 1024
MAX_ALL_EXPORT_BYTES = 1024 * 1024
MANIFEST_NAME = "rendered-utility-manifest.json"
EXPORT_FOLDER = Path("exports/utilities-v2")
PREVIEW_FOLDER = Path("previews")


def asset_name(key):
    return "ObservatoryGlyph" + key[0].upper() + key[1:]


def digest(data):
    return hashlib.sha256(data).hexdigest()


def validate_root_path(root):
    """Reject linked project parents before canonicalizing; permit macOS OS aliases."""
    system_aliases = {Path("/tmp"): Path("/private/tmp"), Path("/var"): Path("/private/var")}
    for part in (root.absolute(), *root.absolute().parents):
        if part.is_symlink() and system_aliases.get(part) != part.resolve():
            raise ValueError(f"Root must not traverse a symlink: {part}")


def read_provenance(source_root):
    """Reject incomplete/changed masters before any export or catalog mutation."""
    if source_root.is_symlink() or not source_root.is_dir():
        raise ValueError(f"Master directory must be a real directory: {source_root}")
    provenance_path = source_root / "PROMPTS.json"
    if provenance_path.is_symlink():
        raise ValueError("PROMPTS.json must not be a symlink")
    provenance_bytes = provenance_path.read_bytes()
    document = json.loads(provenance_bytes)
    if document.get("version") != 1 or document.get("generator") != "Built-in ImageGen":
        raise ValueError("Expected provenance version 1 and generator Built-in ImageGen")
    entries = document.get("assets")
    if not isinstance(entries, list) or len(entries) != len(GLYPHS):
        raise ValueError("Provenance must contain exactly twenty utility assets")
    keyed = {}
    for entry in entries:
        if not isinstance(entry, dict) or entry.get("key") not in GLYPHS:
            raise ValueError("Unknown provenance utility")
        key = entry["key"]
        if key in keyed:
            raise ValueError(f"Duplicate provenance utility: {key}")
        if entry.get("master") != f"{key}.png":
            raise ValueError(f"{key}: master must be the standalone filename {key}.png")
        for field in ("source", "sourceSHA256", "prompt"):
            if not isinstance(entry.get(field), str) or not entry[field].strip():
                raise ValueError(f"{key}: missing {field}")
        keyed[key] = entry
    actual_pngs = {path.name for path in source_root.glob("*.png")}
    if actual_pngs != {f"{key}.png" for key in GLYPHS}:
        raise ValueError("Master PNG roster must match the twenty registered glyphs exactly")
    total = 0
    records = []
    for key in GLYPHS:
        entry = keyed[key]
        path = source_root / entry["master"]
        if path.is_symlink() or not path.is_file():
            raise ValueError(f"{key}: master must be a regular file")
        size = path.stat().st_size
        if size > MAX_MASTER_BYTES:
            raise ValueError(f"{key}: master exceeds {MAX_MASTER_BYTES} bytes")
        data = path.read_bytes()
        total += len(data)
        if total > MAX_ALL_MASTER_BYTES:
            raise ValueError("Master family exceeds the encoded source budget")
        if not data.startswith(b"\x89PNG\r\n\x1a\n"):
            raise ValueError(f"{key}: master is not PNG")
        if digest(data) != entry["sourceSHA256"]:
            raise ValueError(f"{key}: master differs from recorded original source bytes")
        records.append({
            "key": key, "assetName": asset_name(key), "path": str(path),
            "master": entry["master"], "source": entry["source"],
            "sourceSHA256": entry["sourceSHA256"], "prompt": entry["prompt"],
            "encodedBytes": len(data),
        })
    return records, digest(provenance_bytes), total


# Sharp is already used by build_rasters.mjs. Python owns validation/publication;
# Node owns decoding and ordinary proportional raster export, with no art edits.
WORKER = r"""
const fs = require('node:fs/promises');
const path = require('node:path');
const crypto = require('node:crypto');
(async () => {
  let input = '';
  for await (const chunk of process.stdin) input += chunk;
  const config = JSON.parse(input);
  const sharp = require(config.nodeModules ? path.join(config.nodeModules, 'sharp') : 'sharp');
  sharp.cache(false);
  sharp.concurrency(1);
  const hash = value => crypto.createHash('sha256').update(value).digest('hex');
  const round = value => Math.round(value * 10000) / 10000;
  function measure(data, width, height, threshold = 1) {
    let left = width, top = height, right = 0, bottom = 0;
    let count = 0, alpha = 0, cx = 0, cy = 0;
    for (let y = 0; y < height; y++) for (let x = 0; x < width; x++) {
      const a = data[(y * width + x) * 4 + 3];
      if (a < threshold) continue;
      left = Math.min(left, x); top = Math.min(top, y);
      right = Math.max(right, x + 1); bottom = Math.max(bottom, y + 1);
      count++; alpha += a; cx += (x + .5) * a; cy += (y + .5) * a;
    }
    return {
      bounds: count ? [left, top, right, bottom] : null,
      visiblePixels: count,
      alphaCentroid: count ? [round(cx / alpha), round(cy / alpha)] : null,
      padding: count ? [top, left, height - bottom, width - right] : null
    };
  }
  const assets = [], totals = {encodedBytes: 0, decodedRGBABytes: 0, byDensity: {}};
  for (const source of config.sources) {
    const bytes = await fs.readFile(source.path);
    if (hash(bytes) !== source.sourceSHA256) throw Error(`${source.key}: source changed during export`);
    const meta = await sharp(bytes, {limitInputPixels: 16777216}).metadata();
    if (meta.format !== 'png' || !meta.hasAlpha || (meta.pages || 1) !== 1 ||
        meta.width < 72 || meta.height < 72 || meta.width > 4096 || meta.height > 4096)
      throw Error(`${source.key}: expected one alpha PNG, 72–4096 pixels per edge`);
    if (meta.space !== 'srgb') throw Error(`${source.key}: source must already be sRGB`);
    const raw = await sharp(bytes).toColourspace('srgb').raw().toBuffer({resolveWithObject: true});
    if (raw.info.channels !== 4) throw Error(`${source.key}: expected RGBA after decoding`);
    const master = measure(raw.data, raw.info.width, raw.info.height);
    const subject = measure(raw.data, raw.info.width, raw.info.height, config.subjectAlpha);
    const solid = measure(raw.data, raw.info.width, raw.info.height, 128);
    if (!subject.bounds || !solid.bounds || subject.padding.some(value => value < 1))
      throw Error(`${source.key}: visible subject needs a clear outer frame; alpha >= ${config.subjectAlpha} touches an edge`);
    const [sl, st, sr, sb] = subject.bounds;
    const crop = [Math.max(0, sl - config.sourceBleed), Math.max(0, st - config.sourceBleed),
      Math.min(meta.width, sr + config.sourceBleed), Math.min(meta.height, sb + config.sourceBleed)];
    const [left, top, right, bottom] = crop;
    const cropWidth = right - left, cropHeight = bottom - top;
    if (Math.max(cropWidth, cropHeight) < 60)
      throw Error(`${source.key}: source silhouette is too small for 3x export`);
    let discardedPixels = 0, discardedAlphaMax = 0, discardedAlphaSum = 0;
    for (let y = 0; y < meta.height; y++) for (let x = 0; x < meta.width; x++) {
      if (x >= left && x < right && y >= top && y < bottom) continue;
      const alpha = raw.data[(y * meta.width + x) * 4 + 3];
      if (!alpha) continue;
      discardedPixels++; discardedAlphaSum += alpha;
      discardedAlphaMax = Math.max(discardedAlphaMax, alpha);
    }
    if (discardedAlphaMax >= config.subjectAlpha) throw Error(`${source.key}: crop removes visible subject pixels`);
    const record = {
      key: source.key, assetName: source.assetName,
      source: {master: source.master, original: source.source, sha256: source.sourceSHA256,
        encodedBytes: source.encodedBytes, dimensions: [meta.width, meta.height],
        alpha: master, alphaAt16: subject, alphaAt128: solid,
        discardedOutsideCrop: {pixelCount: discardedPixels, maximumAlpha: discardedAlphaMax,
          alphaSum: discardedAlphaSum}},
      registration: {canvasPoints: [config.points, config.points],
        minimumPaddingPoints: config.padding, renderingIntent: 'original',
        subjectAlphaThreshold: config.subjectAlpha, sourceBleedPixels: config.sourceBleed,
        cropPixels: crop, alignment: 'center; odd pixel remainder goes right/bottom'},
      exports: []
    };
    for (const density of config.densities) {
      const side = config.points * density;
      const contentSide = (config.points - 2 * config.padding) * density;
      const ratio = contentSide / Math.max(cropWidth, cropHeight);
      const width = Math.max(1, Math.round(cropWidth * ratio));
      const height = Math.max(1, Math.round(cropHeight * ratio));
      const x = Math.floor((side - width) / 2), y = Math.floor((side - height) / 2);
      const png = await sharp(bytes).extract({left, top, width: cropWidth, height: cropHeight})
        .resize(width, height, {fit: 'fill', kernel: 'lanczos3'})
        .extend({left: x, top: y, right: side - width - x, bottom: side - height - y,
          background: {r: 0, g: 0, b: 0, alpha: 0}})
        .withIccProfile('srgb')
        .png({compressionLevel: 9, adaptiveFiltering: false, palette: false})
        .toBuffer();
      const decoded = await sharp(png).ensureAlpha().raw().toBuffer({resolveWithObject: true});
      const alpha = measure(decoded.data, side, side);
      if (decoded.info.width !== side || decoded.info.height !== side ||
          decoded.info.channels !== 4 || !alpha.bounds ||
          alpha.padding.some(value => value < config.padding * density))
        throw Error(`${source.key}@${density}x: invalid size, alpha, or transparent padding`);
      if (png.length > config.maxExportBytes) throw Error(`${source.key}: export exceeds byte budget`);
      const filename = `${source.key}@${density}x.png`;
      await fs.writeFile(path.join(config.stage, filename), png);
      const decodedBytes = side * side * 4;
      record.exports.push({filename, density, dimensions: [side, side], sha256: hash(png),
        encodedBytes: png.length, decodedRGBABytes: decodedBytes, alpha,
        alphaAt128: measure(decoded.data, side, side, 128),
        fit: {scale: round(ratio), sizePixels: [width, height], originPixels: [x, y]}});
      totals.encodedBytes += png.length; totals.decodedRGBABytes += decodedBytes;
      const total = totals.byDensity[density] ||= {encodedBytes: 0, decodedRGBABytes: 0};
      total.encodedBytes += png.length; total.decodedRGBABytes += decodedBytes;
    }
    assets.push(record);
  }
  if (totals.encodedBytes > config.maxAllExportBytes) throw Error('Utility exports exceed family byte budget');
  // Review furniture only: original export colors on a flat field, no art edits.
  const previews = [];
  const escape = value => String(value).replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
  async function specimen(kind) {
    const raw = kind === 'raw-sources';
    const width = 1000, height = raw ? 1010 : 900, layers = [], labels = [];
    const text = (value, x, y, size = 14, color = '#B5C0D2') => labels.push(
      `<text x="${x}" y="${y}" font-size="${size}" fill="${color}">${escape(value)}</text>`);
    text(raw ? 'OBSERVATORY / RETAINED SOURCE MASTERS' : 'OBSERVATORY / RENDERED UTILITIES',
      28, 38, 22, '#F4ECD9');
    text(raw ? 'Full original canvases fitted into 160 px review boxes; not native icon registration.'
      : 'Actual export colors at 20 / 24 / 28 points; one specimen pixel equals one reference point.', 28, 66);
    text(raw ? 'Original PNGs and alpha remain unchanged. Source preview is separate from small-size acceptance.'
      : '24 pt uses the exact 1x export. 20 and 28 pt resample the registered 3x export. View at 100%.', 28, 88);
    for (let index = 0; index < assets.length; index++) {
      const asset = assets[index], columns = raw ? 5 : 4;
      const cellWidth = raw ? 195 : 240, cellHeight = raw ? 214 : 150;
      const x = 24 + (index % columns) * cellWidth, y = 120 + Math.floor(index / columns) * cellHeight;
      text(asset.key, x + 8, y + 18, 16, '#F4ECD9');
      if (raw) {
        const source = config.sources[index];
        const image = await sharp(source.path).resize(160, 160, {fit: 'contain',
          background: {r: 0, g: 0, b: 0, alpha: 0}, kernel: 'lanczos3'}).png().toBuffer();
        layers.push({input: image, left: x + 12, top: y + 32});
      } else {
        for (const [column, points] of [20, 24, 28].entries()) {
          const source = path.join(config.stage, `${asset.key}@${points === 24 ? 1 : 3}x.png`);
          const image = points === 24 ? await fs.readFile(source)
            : await sharp(source).resize(points, points, {kernel: 'lanczos3'}).png().toBuffer();
          const center = x + 40 + column * 72;
          layers.push({input: image, left: center - points / 2, top: y + 66 - points / 2});
          text(`${points} pt`, center - 16, y + 108, 12);
        }
      }
    }
    text('Offline raster specimen only; native readability, interaction and device acceptance remain separate.',
      28, height - 22, 13);
    const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}">`
      + `<g font-family="Arial, sans-serif">${labels.join('')}</g></svg>`;
    layers.push({input: Buffer.from(svg), left: 0, top: 0});
    const png = await sharp({create: {width, height, channels: 4, background: '#091326'}})
      .composite(layers).withIccProfile('srgb')
      .png({compressionLevel: 9, adaptiveFiltering: false, palette: false}).toBuffer();
    const filename = `rendered-utilities-${kind}.png`;
    await fs.writeFile(path.join(config.stage, filename), png);
    previews.push({filename, dimensions: [width, height], encodedBytes: png.length,
      sha256: hash(png), role: raw ? 'Retained source-canvas review; not runtime'
        : 'Small-size export review at 20/24/28 reference points; not runtime'});
  }
  await specimen('small-sizes');
  await specimen('raw-sources');
  process.stdout.write(JSON.stringify({assets, totals, previews, toolchain: {
    node: process.versions.node, sharp: sharp.versions.sharp, vips: sharp.versions.vips
  }}));
})().catch(error => { process.stderr.write(error.message + '\n'); process.exitCode = 1; });
"""


def catalog_contents(key):
    return {
        "images": [
            {"filename": f"{key}@{density}x.png", "idiom": "universal", "scale": f"{density}x"}
            for density in DENSITIES
        ],
        "info": {"author": "xcode", "version": 1},
        "properties": {"template-rendering-intent": "original"},
    }


def validate_catalog(catalog_root):
    """Never delete unknown files or reach through a symlink during replacement."""
    if catalog_root.is_symlink() or not catalog_root.is_dir():
        raise ValueError("Catalog root must be an existing real directory")
    for key in GLYPHS:
        folder = catalog_root / f"{asset_name(key)}.imageset"
        if folder.is_symlink() or not folder.is_dir():
            raise ValueError(f"Missing registered image set: {folder.name}")
        allowed = {"Contents.json", "glyph.pdf"} | {f"{key}@{d}x.png" for d in DENSITIES}
        for child in folder.iterdir():
            if child.is_symlink() or not child.is_file() or child.name not in allowed:
                raise ValueError(f"Unowned catalog entry: {child}")


def write_atomic(destination, data):
    destination.parent.mkdir(parents=True, exist_ok=True)
    if destination.is_symlink():
        raise ValueError(f"Refusing symlink output: {destination}")
    with tempfile.NamedTemporaryFile(dir=destination.parent, prefix=".utility-", delete=False) as handle:
        temporary = Path(handle.name)
        try:
            handle.write(data)
            handle.close()
            os.replace(temporary, destination)
        finally:
            temporary.unlink(missing_ok=True)


def publish(stage, output_root, manifest, catalog_root=None):
    files = [(output_root / EXPORT_FOLDER / export["filename"], stage / export["filename"])
             for asset in manifest["assets"] for export in asset["exports"]]
    files += [(output_root / PREVIEW_FOLDER / preview["filename"], stage / preview["filename"])
              for preview in manifest["previews"]]
    if catalog_root is not None:
        validate_catalog(catalog_root)
        files += [(catalog_root / f"{asset['assetName']}.imageset" / export["filename"],
                   stage / export["filename"])
                  for asset in manifest["assets"] for export in asset["exports"]]
    # Check every destination before changing any catalog/source-kit payload.
    for destination, _ in files:
        for part in (destination, *destination.parents):
            if part.is_symlink():
                raise ValueError(f"Refusing symlink output: {part}")
    manifest_path = output_root / MANIFEST_NAME
    if manifest_path.is_symlink():
        raise ValueError("Refusing symlink manifest")
    for destination, source in files:
        write_atomic(destination, source.read_bytes())
    if catalog_root is not None:
        for key in GLYPHS:
            folder = catalog_root / f"{asset_name(key)}.imageset"
            write_atomic(folder / "Contents.json", json_bytes(catalog_contents(key)))
            (folder / "glyph.pdf").unlink(missing_ok=True)
    write_atomic(manifest_path, json_bytes(manifest))


def json_bytes(value):
    return (json.dumps(value, indent=2, ensure_ascii=False) + "\n").encode("utf-8")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--source-root", type=Path, default=ROOT / "masters/utilities-v2")
    parser.add_argument("--output-root", type=Path, default=ROOT)
    parser.add_argument("--node", default=shutil.which("node") or "node")
    parser.add_argument("--node-modules", type=Path)
    parser.add_argument("--catalog-root", type=Path, help="Explicitly replace the twenty registered native image sets")
    parser.add_argument("--check-only", action="store_true", help="Validate and resize in temporary storage; publish nothing")
    args = parser.parse_args()
    # Inspect lexical parents before resolution would erase their symlink identity.
    for root in (args.source_root, args.output_root, args.catalog_root):
        if root is not None:
            validate_root_path(root)
    source_root, output_root = args.source_root.resolve(), args.output_root.resolve()
    catalog_root = args.catalog_root.resolve() if args.catalog_root else None
    sources, provenance_hash, source_bytes = read_provenance(source_root)
    if catalog_root is not None:
        validate_catalog(catalog_root)
    with tempfile.TemporaryDirectory(prefix="starfall-rendered-utilities-") as temporary:
        stage = Path(temporary)
        config = {
            "sources": sources, "stage": str(stage), "points": POINTS, "padding": PADDING,
            "subjectAlpha": SUBJECT_ALPHA, "sourceBleed": SOURCE_BLEED,
            "densities": DENSITIES,
            "nodeModules": str(args.node_modules.resolve()) if args.node_modules else None,
            "maxExportBytes": MAX_EXPORT_BYTES, "maxAllExportBytes": MAX_ALL_EXPORT_BYTES,
        }
        result = subprocess.run([args.node, "-e", WORKER], input=json.dumps(config), text=True,
                                capture_output=True, timeout=180, check=True)
        export = json.loads(result.stdout)
        manifest = {
            "version": 1, "family": "Observatory rendered utilities v2",
            "generator": "Built-in ImageGen", "provenance": {
                "file": os.path.relpath(source_root / "PROMPTS.json", output_root),
                "sha256": provenance_hash,
                "masterEncodedBytes": source_bytes,
            },
            "exporterSHA256": digest(Path(__file__).read_bytes()),
            "normalization": {
                "alphaBoundsThreshold": SUBJECT_ALPHA, "sourceBleedPixels": SOURCE_BLEED,
                "coordinates": "top-left; right and bottom exclusive",
                "paddingOrder": ["top", "left", "bottom", "right"], "kernel": "lanczos3",
                "colorSpace": "sRGB", "sourcePolicy": "Unchanged original RGBA masters",
                "allowedOperations": ["crop visible alpha bounds plus source bleed",
                                      "proportional resize", "transparent canvas registration"],
                "cropPolicy": "Pixels outside the crop must have alpha below 16; report their count and maximum. Preserve every retained pixel before resampling.",
                "nativeRenderingIntent": "original",
            },
            "budgets": {
                "maximumMasterBytesEach": MAX_MASTER_BYTES, "maximumAllMasterBytes": MAX_ALL_MASTER_BYTES,
                "maximumExportBytesEach": MAX_EXPORT_BYTES, "maximumAllExportBytes": MAX_ALL_EXPORT_BYTES,
                "decodedRGBABytesAllDensities": len(GLYPHS) * sum((POINTS * d) ** 2 * 4 for d in DENSITIES),
                "decodedRGBABytes3xSelection": len(GLYPHS) * (POINTS * 3) ** 2 * 4,
            },
            "validation": {"sourceHashes": "passed", "completeRoster": 20, "exports": 60,
                           "sourceVisibleFrames": "passed", "exportAlphaFrames": "passed",
                           "pointRegistration": "passed",
                           "encodedBudget": "passed", "nativeAppearance": "not established by export"},
            **export,
        }
        if not args.check_only:
            publish(stage, output_root, manifest, catalog_root)
        print(json.dumps({"checkOnly": args.check_only, "assets": len(export["assets"]),
                          "exports": 60, "catalogReplaced": bool(catalog_root and not args.check_only),
                          "totals": export["totals"]}, indent=2))


if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as error:
        sys.exit((error.stderr or "Sharp export failed").strip())
    except (ValueError, OSError, subprocess.TimeoutExpired) as error:
        sys.exit(str(error))
