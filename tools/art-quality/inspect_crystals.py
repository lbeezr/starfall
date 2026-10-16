#!/usr/bin/env python3
"""Inspect existing Starfall PNG pixels; never repaint or replace source artwork."""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, __version__ as PILLOW_VERSION

SIDE, COUNT, NEUTRAL = 256, 9, 4
KINDS = ("rose", "aqua", "amber", "violet", "mint")
SHAPES = ("circle", "diamond", "up triangle", "hexagon", "square")
PIVOT = (128, 128)
ROOT = Path(__file__).resolve().parents[2]
BACKGROUNDS = {"midnight": "#090E2B", "plum": "#2E1A4A", "light": "#E5E5E5"}


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def rounded(value: float) -> float:
    return round(value, 4)


def bounds_union(bounds: list[tuple]) -> list[int]:
    return [min(b[0] for b in bounds), min(b[1] for b in bounds),
            max(b[2] for b in bounds), max(b[3] for b in bounds)]


def metrics(frame: Image.Image) -> dict:
    alpha = frame.getchannel("A")
    bounds = alpha.getbbox()
    if bounds is None:
        return {"alpha_bounds": None, "error": "empty frame"}
    # Use pixel centers, in top-left raster coordinates. No alpha-box recentering.
    weighted_x = weighted_y = weight = 0.0
    opaque = near_white = bright_low_chroma = transparent_rgb = 0
    luminance = saturation = 0.0
    pixels = frame.get_flattened_data() if hasattr(frame, "get_flattened_data") else frame.getdata()
    for offset, (r, g, b, a) in enumerate(pixels):
        if a == 0:
            transparent_rgb += int(max(r, g, b) != 0)
            continue
        weight += a / 255
        weighted_x += (offset % SIDE + 0.5) * a / 255
        weighted_y += (offset // SIDE + 0.5) * a / 255
        if a < 128:
            continue
        opaque += 1
        near_white += int(min(r, g, b) >= 235 and max(r, g, b) - min(r, g, b) <= 20)
        bright_low_chroma += int(min(r, g, b) >= 210 and max(r, g, b) - min(r, g, b) <= 45)
        luminance += (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255
        saturation += (max(r, g, b) - min(r, g, b)) / max(1, max(r, g, b))
    x0, y0, x1, y1 = bounds
    return {
        "rgba_sha256": sha(frame.tobytes()), "alpha_bounds": list(bounds),
        "alpha_span_px": [x1 - x0, y1 - y0],
        "minimum_padding_px": min(x0, y0, SIDE - x1, SIDE - y1),
        "bounds_center_px": [(x0 + x1) / 2, (y0 + y1) / 2],
        "alpha_centroid_px": [rounded(weighted_x / weight), rounded(weighted_y / weight)],
        "alpha_area_px": rounded(weight), "opaque_pixel_count": opaque,
        "near_white_pct": rounded(100 * near_white / max(1, opaque)),
        "bright_low_chroma_pct": rounded(100 * bright_low_chroma / max(1, opaque)),
        "mean_encoded_luma": rounded(luminance / max(1, opaque)),
        "mean_hsv_saturation": rounded(saturation / max(1, opaque)),
        "nonblack_rgb_under_zero_alpha_pixels": transparent_rgb,
    }


def inspect(asset_dir: Path, visible_pt: float) -> tuple[dict, dict, list[str]]:
    report, frames_by_kind, errors = {}, {}, []
    for kind in KINDS:
        relative = Path(f"StarshardFamily{kind.title()}.imageset/{kind}_tilt_atlas.png")
        path = asset_dir / relative
        item = {"path": str(relative), "errors": []}
        report[kind] = item
        try:
            raw = path.read_bytes()
            with Image.open(path) as original:
                item.update(file_sha256=sha(raw), bytes=len(raw), mode=original.mode,
                            format=original.format, size=list(original.size))
                if original.format != "PNG" or original.mode != "RGBA" or original.size != (SIDE * COUNT, SIDE):
                    raise ValueError("expected RGBA PNG, 2304 x 256, nine horizontal full frames")
                atlas = original.copy()
            frames = [atlas.crop((i * SIDE, 0, (i + 1) * SIDE, SIDE)) for i in range(COUNT)]
            measured = [dict(index=i, **metrics(frame)) for i, frame in enumerate(frames)]
            item["frames"] = measured
            for frame in measured:
                if frame["alpha_bounds"] is None:
                    item["errors"].append(f"frame {frame['index']}: empty")
                elif frame["minimum_padding_px"] < 1:
                    item["errors"].append(f"frame {frame['index']}: nontransparent outer border")
            if item["errors"]:
                errors.extend(f"{kind}: {error}" for error in item["errors"])
                continue
            neutral = measured[NEUTRAL]
            scale = visible_pt / max(neutral["alpha_span_px"])
            union = bounds_union([f["alpha_bounds"] for f in measured])
            neutral_center = neutral["bounds_center_px"]
            item["summary"] = {
                "source_px_to_pt": rounded(scale),
                "canvas_side_pt": rounded(SIDE * scale),
                "neutral_span_pt": [rounded(v * scale) for v in neutral["alpha_span_px"]],
                "motion_union_bounds": union,
                "motion_span_pt": [rounded((union[2] - union[0]) * scale), rounded((union[3] - union[1]) * scale)],
                "neutral_bounds_offset_from_pivot_pt": [rounded((v - 128) * scale) for v in neutral_center],
                "neutral_alpha_centroid_offset_from_pivot_pt": [rounded((v - 128) * scale) for v in neutral["alpha_centroid_px"]],
                "max_bounds_center_displacement_from_neutral_pt": rounded(max(
                    math.dist(f["bounds_center_px"], neutral_center) * scale for f in measured)),
                "neutral_alpha_area_pt2": rounded(neutral["alpha_area_px"] * scale * scale),
                "minimum_padding_px": min(f["minimum_padding_px"] for f in measured),
                "near_white_pct_range": [min(f["near_white_pct"] for f in measured), max(f["near_white_pct"] for f in measured)],
                "bright_low_chroma_pct_range": [min(f["bright_low_chroma_pct"] for f in measured), max(f["bright_low_chroma_pct"] for f in measured)],
                "unique_rgba_frames": len({f["rgba_sha256"] for f in measured}),
            }
            frames_by_kind[kind] = frames
        except (OSError, ValueError) as error:
            item["errors"].append(str(error))
            errors.append(f"{kind}: {error}")
    return report, frames_by_kind, errors


def font(size: int) -> ImageFont.ImageFont:
    # Pillow's bundled font keeps output independent of installed system fonts.
    return ImageFont.load_default(size=size)


def label(image: Image.Image, xy: tuple[int, int], text: str, size: int = 16, color="#DEE7FF") -> None:
    ImageDraw.Draw(image).text(xy, text, fill=color, font=font(size))


def composite(image: Image.Image, frame: Image.Image, center: tuple[float, float],
              scale: float, silhouette: bool = False, grayscale: bool = False) -> None:
    copy = frame.copy()
    if silhouette:
        copy = Image.new("RGBA", frame.size, "#DAE8FF")
        copy.putalpha(frame.getchannel("A"))
    elif grayscale:
        copy = frame.convert("L").convert("RGBA")
        copy.putalpha(frame.getchannel("A"))
    # A fractional destination transform preserves the authored pivot and canvas
    # size. Pillow RGBa uses premultiplied alpha for resampling.
    cx, cy = center
    left, top = math.floor(cx - 128 * scale) - 1, math.floor(cy - 128 * scale) - 1
    right, bottom = math.ceil(cx + 128 * scale) + 1, math.ceil(cy + 128 * scale) + 1
    transformed = copy.convert("RGBa").transform(
        (right - left, bottom - top), Image.Transform.AFFINE,
        (1 / scale, 0, 128 + (left - cx) / scale, 0, 1 / scale, 128 + (top - cy) / scale),
        Image.Resampling.BILINEAR,
    ).convert("RGBA")
    image.alpha_composite(transformed, (left, top))


def sheets(output: Path, report: dict, frames: dict, visible_pt: float) -> None:
    def scale(kind: str, pixels_per_point: int) -> float:
        return visible_pt * pixels_per_point / max(report[kind]["frames"][NEUTRAL]["alpha_span_px"])

    # Comparison at 1 pixel/point plus 3-pixel/point raster representations.
    sheet = Image.new("RGBA", (1040, 1000), "#11182F")
    label(sheet, (24, 18), "STARFALL / existing crystal pixels", 26)
    label(sheet, (24, 52), f"Neutral frame 4; longest neutral span {visible_pt:g} pt; original 128/128 pivots", 16)
    label(sheet, (24, 78), "Offline comparison only. Display zoom does not establish physical phone size.", 14)
    for col, (kind, shape) in enumerate(zip(KINDS, SHAPES)):
        cx = 200 + col * 180
        label(sheet, (cx - 52, 114), kind.title(), 19)
        label(sheet, (cx - 52, 140), shape, 13)
        composite(sheet, frames[kind][NEUTRAL], (cx, 192), scale(kind, 1))
    label(sheet, (16, 180), "1 px/pt", 14)
    rows = (("midnight", False, False), ("plum", False, False),
            ("light", False, False), ("midnight", False, True), ("midnight", True, False))
    for row, (background, silhouette, grayscale) in enumerate(rows):
        y = 242 + row * 145
        ImageDraw.Draw(sheet).rectangle((0, y, sheet.width, y + 144), fill=BACKGROUNDS[background])
        row_name = "silhouette" if silhouette else "grayscale" if grayscale else background
        label(sheet, (16, y + 16), row_name, 14, "#222222" if background == "light" else "#DEE7FF")
        label(sheet, (16, y + 38), "3 px/pt", 14, "#222222" if background == "light" else "#DEE7FF")
        for col, kind in enumerate(KINDS):
            composite(sheet, frames[kind][NEUTRAL], (200 + col * 180, y + 74), scale(kind, 3), silhouette, grayscale)
    sheet.convert("RGB").save(output / "neutral-review.png")

    sheet = Image.new("RGBA", (1530, 1010), BACKGROUNDS["midnight"])
    label(sheet, (22, 18), f"All 45 frames / {visible_pt:g} pt longest neutral span at 3 px/pt", 24)
    label(sheet, (22, 50), "No per-frame scale/anchor corrections. Current tap: 4,3,2,1,2,3,4; clear: 4,3,2,1.", 15)
    for index in range(COUNT):
        label(sheet, (170 + index * 153, 85), f"{index}" + (" neutral" if index == NEUTRAL else ""), 16)
    for row, kind in enumerate(KINDS):
        cy = 192 + row * 175
        label(sheet, (16, cy - 10), kind.title(), 18)
        for index, frame in enumerate(frames[kind]):
            cx = 205 + index * 153
            ImageDraw.Draw(sheet).rectangle((cx - 70, cy - 70, cx + 70, cy + 70), outline="#252C48")
            composite(sheet, frame, (cx, cy), scale(kind, 3))
            pct = report[kind]["frames"][index]["bright_low_chroma_pct"]
            label(sheet, (cx - 50, cy + 73), f"bright {pct:.1f}%", 12)
    sheet.convert("RGB").save(output / "tilt-review.png")

    # Two fixed 7x7 visual fixtures; neither asserts a reachable game state.
    pitch = visible_pt / 0.74
    board_side = round(7 * pitch * 3)
    sheet = Image.new("RGBA", (board_side * 2 + 72, board_side + 136), BACKGROUNDS["midnight"])
    label(sheet, (24, 18), "7 x 7 density / static visual fixture / 3 px per point", 24)
    label(sheet, (24, 52), "Same 0.37 x pitch radius and full-canvas centered anchors as the family renderer.", 16)
    for panel, grayscale in enumerate((False, True)):
        ox, oy = 24 + panel * (board_side + 24), 108
        label(sheet, (ox, 80), "Neutral color" if not grayscale else "Neutral grayscale", 16)
        ImageDraw.Draw(sheet).rectangle((ox, oy, ox + board_side, oy + board_side), fill="#131B37")
        for row in range(7):
            for col in range(7):
                kind = KINDS[((row // 2) * 2 + col // 3) % len(KINDS)]
                center = (ox + (col + 0.5) * pitch * 3, oy + (row + 0.5) * pitch * 3)
                composite(sheet, frames[kind][NEUTRAL], center, scale(kind, 3), grayscale=grayscale)
    sheet.convert("RGB").save(output / "board-review.png")

    sheet = Image.new("RGBA", (1380, 410), BACKGROUNDS["midnight"])
    label(sheet, (20, 16), "Neutral source canvas / alpha bounds + authored pivot / 1 source pixel = 1 pixel", 22)
    label(sheet, (20, 47), "Yellow: nonzero alpha box. Cyan: pivot (128,128). No shifting or trimming applied.", 15)
    for col, kind in enumerate(KINDS):
        x, y = 20 + col * 272, 108
        label(sheet, (x, 80), kind.title(), 18)
        sheet.alpha_composite(frames[kind][NEUTRAL], (x, y))
        draw = ImageDraw.Draw(sheet)
        x0, y0, x1, y1 = report[kind]["frames"][NEUTRAL]["alpha_bounds"]
        draw.rectangle((x, y, x + SIDE - 1, y + SIDE - 1), outline="#404863")
        draw.rectangle((x + x0, y + y0, x + x1 - 1, y + y1 - 1), outline="#FFE27C")
        draw.line((x + 120, y + 128, x + 136, y + 128), fill="#76E4FF", width=1)
        draw.line((x + 128, y + 120, x + 128, y + 136), fill="#76E4FF", width=1)
        label(sheet, (x, y + 268), f"alpha box {x0},{y0},{x1},{y1}", 13)
    sheet.convert("RGB").save(output / "geometry-review.png")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--assets", type=Path, default=ROOT / "App/Assets.xcassets")
    parser.add_argument("--output", type=Path, default=Path(__file__).parent / "output")
    parser.add_argument("--visible-pt", type=float, default=34.0)
    args = parser.parse_args()
    if not math.isfinite(args.visible_pt) or not 16 <= args.visible_pt <= 40:
        parser.error("--visible-pt must be finite and between 16 and 40 (fixed review-sheet spacing)")
    assets, output = args.assets.resolve(), args.output.resolve()
    if output == assets or assets in output.parents:
        parser.error("--output must not be inside the source asset catalog")
    output.mkdir(parents=True, exist_ok=True)
    measurements, frames, errors = inspect(assets, args.visible_pt)
    report = {
        "schema": "starfall.crystal-quality.v1", "pillow_version": PILLOW_VERSION,
        "inspector_sha256": sha(Path(__file__).read_bytes()),
        "contract": {"frame_side_px": SIDE, "frame_count": COUNT, "neutral_index": NEUTRAL,
                     "authored_pivot_px": list(PIVOT), "longest_neutral_span_pt": args.visible_pt,
                     "raster_coordinates": "top-left origin; bounds right/bottom exclusive",
                     "resampling": "Pillow premultiplied-alpha bilinear; not a SpriteKit capture",
                     "near_white": "alpha >= 128; min RGB >= 235; max RGB - min RGB <= 20",
                     "bright_low_chroma": "alpha >= 128; min RGB >= 210; max RGB - min RGB <= 45",
                     "highlight_denominator": "pixels with alpha >= 128; encoded RGB, not linear luminance",
                     "guarantee": "structural checks only; metrics are advisory, no art or native acceptance"},
        "structural_pass": not errors, "errors": errors, "kinds": measurements,
    }
    if not errors:
        sheets(output, measurements, frames, args.visible_pt)
        report["artifacts"] = {p.name: sha(p.read_bytes()) for p in sorted(output.glob("*-review.png"))}
    (output / "report.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps({"structural_pass": not errors, "frames": len(frames) * COUNT,
                      "errors": errors, "report": str(output / "report.json")}, indent=2))
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
