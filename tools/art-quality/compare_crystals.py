#!/usr/bin/env python3
"""Compare original/candidate crystal pixels without editing either input family."""
from __future__ import annotations

import argparse
import hashlib
import io
import json
import math
import platform
import shutil
import tempfile
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, __version__ as PILLOW_VERSION

from inspect_crystals import (COUNT, KINDS, NEUTRAL, PIVOT, SIDE, composite,
                              label, metrics)

ROOT = Path(__file__).resolve().parents[2]
CONTRACT = {"frame_side_px": SIDE, "frame_count": COUNT,
            "frame_indices_left_to_right": list(range(COUNT)),
            "neutral_index": NEUTRAL, "authored_pivot_px": list(PIVOT)}


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def relative(kind: str) -> Path:
    return Path(f"StarshardFamily{kind.title()}.imageset/{kind}_tilt_atlas.png")


def write_json(path: Path, value: dict) -> None:
    path.write_text(json.dumps(value, indent=2, sort_keys=True, allow_nan=False) + "\n")


def read_family(root: Path) -> tuple[dict, dict, list[str]]:
    records, frames, errors = {}, {}, []
    for kind in KINDS:
        path = root / relative(kind)
        record = {"path": str(relative(kind))}
        records[kind] = record
        try:
            raw = path.read_bytes()
            record["file_sha256"] = sha(raw)
            record["bytes"] = len(raw)
            with Image.open(io.BytesIO(raw)) as image:
                record.update(size=list(image.size), mode=image.mode, format=image.format)
                if image.format != "PNG" or image.mode != "RGBA" or image.size != (SIDE * COUNT, SIDE):
                    raise ValueError("expected RGBA PNG, 2304x256, nine horizontal 256x256 frames")
                image.load()
                atlas = image.copy()
            frames[kind] = [atlas.crop((i * SIDE, 0, (i + 1) * SIDE, SIDE)) for i in range(COUNT)]
            for i, frame in enumerate(frames[kind]):
                box = frame.getchannel("A").getbbox()
                if box is None:
                    errors.append(f"{kind}[{i}]: empty frame")
                elif min(box[0], box[1], SIDE - box[2], SIDE - box[3]) < 1:
                    errors.append(f"{kind}[{i}]: nontransparent outer border")
        except (OSError, ValueError, SyntaxError) as error:
            errors.append(f"{kind}: {error}")
    return records, frames, errors


def freeze(source: Path, destination: Path) -> int:
    if destination == source or source in destination.parents:
        raise ValueError("baseline destination must not be inside the input catalog")
    if destination.exists():
        raise ValueError("baseline destination already exists; refusing to overwrite frozen bytes")
    records, _, errors = read_family(source)
    if errors:
        raise ValueError("cannot freeze invalid baseline: " + "; ".join(errors))
    destination.mkdir(parents=True)
    for kind in KINDS:
        target = destination / relative(kind)
        target.parent.mkdir()
        shutil.copyfile(source / relative(kind), target)
        if sha(target.read_bytes()) != records[kind]["file_sha256"]:
            raise ValueError(f"source changed during freeze: {kind}; discard incomplete baseline")
    write_json(destination / "manifest.json", {
        "schema": "starfall.crystal-baseline.v1", "contract": CONTRACT,
        "source": str(source.relative_to(ROOT)) if source.is_relative_to(ROOT) else str(source), "kinds": records,
        "note": "Original PNG bytes; no atlas pixels, metadata, scale or alpha changed."})
    print(f"Frozen five original atlases: {destination}")
    return 0


def verify_baseline(root: Path, records: dict) -> list[str]:
    errors = []
    try:
        manifest = json.loads((root / "manifest.json").read_text())
        if not isinstance(manifest, dict):
            raise ValueError("manifest must be a JSON object")
        if manifest.get("schema") != "starfall.crystal-baseline.v1" or manifest.get("contract") != CONTRACT:
            errors.append("baseline manifest schema/geometry/order/pivot contract differs")
        for kind in KINDS:
            if manifest["kinds"][kind]["file_sha256"] != records[kind].get("file_sha256"):
                errors.append(f"baseline {kind}: frozen hash mismatch")
    except (OSError, ValueError, KeyError, TypeError) as error:
        errors.append(f"baseline manifest invalid: {error}")
    return errors


def grain_proxy(frame: Image.Image) -> dict:
    # Encoded luma residual from the four immediate neighbors. Opaque interiors
    # only; this still responds to intended facet/highlight edges, not just noise.
    px = frame.load()
    residuals = []
    def luma(p):
        return (0.2126 * p[0] + 0.7152 * p[1] + 0.0722 * p[2]) / 255
    for y in range(1, SIDE - 1):
        for x in range(1, SIDE - 1):
            values = [px[x, y], px[x-1, y], px[x+1, y], px[x, y-1], px[x, y+1]]
            if min(p[3] for p in values) >= 250:
                residuals.append(abs(luma(values[0]) - sum(luma(p) for p in values[1:]) / 4))
    residuals.sort()
    return {"samples": len(residuals),
            "mean_abs_encoded_luma_residual": round(sum(residuals) / max(1, len(residuals)), 7),
            "p90_abs_encoded_luma_residual": round(residuals[int(.9 * (len(residuals)-1))], 7) if residuals else None}


def frame_comparison(before: Image.Image, after: Image.Image) -> dict:
    old, new = metrics(before), metrics(after)
    alpha0, alpha1 = before.getchannel("A"), after.getchannel("A")
    a0, a1 = alpha0.tobytes(), alpha1.tobytes()
    raw0, raw1 = before.tobytes(), after.tobytes()
    alpha_changed = sum(a != b for a, b in zip(a0, a1))
    support_changed = sum((a > 0) != (b > 0) for a, b in zip(a0, a1))
    rgba_changed = visible_changed = visible_total = hidden_rgb_changed = 0
    for i in range(SIDE * SIDE):
        offset = i * 4
        changed = raw0[offset:offset+4] != raw1[offset:offset+4]
        rgba_changed += changed
        if max(a0[i], a1[i]) > 0:
            visible_total += 1
            visible_changed += changed
        elif raw0[offset:offset+3] != raw1[offset:offset+3]:
            hidden_rgb_changed += 1
    delta = {}
    for name in ("near_white_pct", "bright_low_chroma_pct", "mean_encoded_luma", "mean_hsv_saturation"):
        if name in old and name in new:
            delta[name] = round(new[name] - old[name], 7)
    centroid_delta = None
    if "alpha_centroid_px" in old and "alpha_centroid_px" in new:
        centroid_delta = [round(b-a, 4) for a, b in zip(old["alpha_centroid_px"], new["alpha_centroid_px"])]
    return {
        "original": old, "candidate": new,
        "original_alpha_sha256": sha(a0), "candidate_alpha_sha256": sha(a1),
        "alpha_exact": a0 == a1, "nonzero_mask_exact": support_changed == 0,
        "alpha_changed_pixels": alpha_changed, "nonzero_mask_changed_pixels": support_changed,
        "max_alpha_sample_delta": max(abs(a-b) for a, b in zip(a0, a1)),
        "bounds_exact": old["alpha_bounds"] == new["alpha_bounds"],
        "alpha_centroid_delta_px": centroid_delta,
        "rgba_changed_pixels": rgba_changed, "visible_changed_pixels": visible_changed,
        "visible_changed_pct": round(100 * visible_changed / max(1, visible_total), 4),
        "changed_rgb_under_zero_alpha_pixels": hidden_rgb_changed,
        "advisory_highlight_delta": delta,
        "advisory_high_frequency_original": grain_proxy(before),
        "advisory_high_frequency_candidate": grain_proxy(after),
    }


def comparison_sheets(output: Path, old: dict, new: dict, visible_pt: float) -> list[str]:
    artifacts = []
    def scale(kind, px_per_pt):
        box = old[kind][NEUTRAL].getchannel("A").getbbox()
        return visible_pt * px_per_pt / max(box[2]-box[0], box[3]-box[1])
    # Each index pair uses the identical original-derived scale and canvas pivot.
    sheet = Image.new("RGBA", (1510, 1550), "#090E2B")
    label(sheet, (20, 16), "ORIGINAL / CANDIDATE · all frames at 3 px per modeled point", 23)
    label(sheet, (20, 48), f"{visible_pt:g} pt original neutral span; fixed 128/128 pivot. Offline pixels, not an iOS capture.", 15)
    for i in range(COUNT):
        label(sheet, (170+i*148, 81), f"{i}" + (" neutral" if i == NEUTRAL else ""), 15)
    for row, kind in enumerate(KINDS):
        y = 142 + row * 285
        label(sheet, (16, y), kind.title(), 18)
        for offset, name, frames in ((0, "Original", old), (125, "Candidate", new)):
            label(sheet, (16, y+offset+26), name, 13)
            for i in range(COUNT):
                composite(sheet, frames[kind][i], (205+i*148, y+offset+28), scale(kind, 3))
    sheet.convert("RGB").save(output / "all-frames-paired.png")
    artifacts.append("all-frames-paired.png")

    sheet = Image.new("RGBA", (1500, 1010), "#11182F")
    label(sheet, (20, 15), "Neutral pairs: ORIGINAL left / CANDIDATE right", 24)
    label(sheet, (20, 46), "Same scale and authored pivot. Viewer zoom does not establish physical phone size.", 15)
    for col, kind in enumerate(KINDS):
        label(sheet, (190+col*270, 80), kind.title(), 17)
    rows = [("#090E2B", "1 px/pt", 1, False), ("#090E2B", "midnight", 3, False),
            ("#2E1A4A", "plum", 3, False), ("#E5E5E5", "light", 3, False),
            ("#090E2B", "grayscale", 3, True)]
    for row, (background, title, factor, gray) in enumerate(rows):
        y = 110 + row*178
        ImageDraw.Draw(sheet).rectangle((0, y, 1500, y+177), fill=background)
        label(sheet, (14, y+20), title, 14, "#222222" if title == "light" else "#DEE7FF")
        if factor == 3:
            label(sheet, (14, y+40), "3 px/pt", 13, "#222222" if title == "light" else "#DEE7FF")
        for col, kind in enumerate(KINDS):
            for offset, frames in ((-65, old), (65, new)):
                composite(sheet, frames[kind][NEUTRAL], (245+col*270+offset, y+91), scale(kind, factor), grayscale=gray)
    sheet.convert("RGB").save(output / "neutral-paired.png")
    artifacts.append("neutral-paired.png")

    for index in (NEUTRAL, 1):
        pitch = visible_pt / .74
        board_side = math.ceil(7 * pitch * 3)
        sheet = Image.new("RGBA", (2*board_side+72, board_side+135), "#090E2B")
        label(sheet, (22, 15), f"Same 7x7 visual fixture / frame {index} / original left, candidate right", 23)
        label(sheet, (22, 47), "3 px per modeled point. Fixed original scale; not a reachable game or native screen.", 15)
        for panel, frames in enumerate((old, new)):
            ox, oy = 24+panel*(board_side+24), 108
            label(sheet, (ox, 80), "Original" if panel == 0 else "Candidate", 16)
            ImageDraw.Draw(sheet).rectangle((ox, oy, ox+board_side, oy+board_side), fill="#131B37")
            for row in range(7):
                for col in range(7):
                    kind = KINDS[((row//2)*2+col//3) % 5]
                    composite(sheet, frames[kind][index], (ox+(col+.5)*pitch*3, oy+(row+.5)*pitch*3), scale(kind, 3))
        name = f"board-frame-{index}-paired.png"
        sheet.convert("RGB").save(output / name)
        artifacts.append(name)
    return artifacts


def compare(baseline: Path, candidate: Path, output: Path, visible_pt: float) -> int:
    for source in (baseline, candidate):
        if output == source or source in output.parents:
            raise ValueError("comparison output must not be inside either input family")
    original_records, old, errors0 = read_family(baseline)
    candidate_records, new, errors1 = read_family(candidate)
    errors = ["original: " + e for e in errors0] + ["candidate: " + e for e in errors1]
    errors += verify_baseline(baseline, original_records)
    output.mkdir(parents=True, exist_ok=True)
    report = {"schema": "starfall.crystal-comparison.v1", "contract": CONTRACT,
              "python_version": platform.python_version(), "pillow_version": PILLOW_VERSION,
              "comparator_sha256": sha(Path(__file__).read_bytes()),
              "inspector_sha256": sha(Path(__file__).with_name("inspect_crystals.py").read_bytes()),
              "baseline_manifest_sha256": sha((baseline / "manifest.json").read_bytes()) if (baseline / "manifest.json").is_file() else None,
              "original": original_records, "candidate": candidate_records,
              "visible_pt": visible_pt, "frames": {}, "artifacts": {}, "errors": errors,
              "limits": ["Exact alpha samples are strict, including antialiasing changes; no automatic tolerance.",
                         "Index continuity is checked through per-index alpha; semantic angle/pivot intent cannot be inferred from PNGs.",
                         "All composites preserve original neutral scale and declared canvas pivot; no image is recentered.",
                         "Highlight/luma/saturation/high-frequency measures are advisory, not perceptual or native acceptance.",
                         "High-frequency residual also measures intentional facets/highlights; a lower number is not proof of less grain."]}
    if not errors0 and not errors1:
        for kind in KINDS:
            measured = []
            original_alpha = [sha(frame.getchannel("A").tobytes()) for frame in old[kind]]
            for i in range(COUNT):
                item = frame_comparison(old[kind][i], new[kind][i])
                item["index"] = i
                item["candidate_alpha_matches_original_indices"] = [j for j, digest in enumerate(original_alpha) if digest == item["candidate_alpha_sha256"]]
                if not item["alpha_exact"]:
                    errors.append(f"{kind}[{i}]: alpha samples differ; geometry/antialiasing/order requires explicit review")
                measured.append(item)
            report["frames"][kind] = measured
        for name in comparison_sheets(output, old, new, visible_pt):
            report["artifacts"][name] = sha((output/name).read_bytes())
    report["structural_pass"] = not errors
    report["art_acceptance"] = "pending human review; never granted by this comparator"
    write_json(output / "report.json", report)
    write_json(output / "manifest.json", {"schema": "starfall.crystal-comparison-files.v1",
               "report.json": sha((output / "report.json").read_bytes()), **report["artifacts"]})
    print(json.dumps({"structural_pass": not errors, "errors": errors, "report": str(output / "report.json")}, indent=2))
    return 1 if errors else 0


def self_test() -> int:
    # Small deterministic pixel fixtures make the checks meaningful without
    # invoking native rendering or changing any repository asset.
    with tempfile.TemporaryDirectory(prefix="starfall-compare-tests-") as directory:
        root = Path(directory)
        original = Image.new("RGBA", (SIDE, SIDE), (0, 0, 0, 0))
        ImageDraw.Draw(original).rectangle((80, 70, 169, 179), fill=(50, 140, 220, 255))
        same = frame_comparison(original, original)
        assert same["alpha_exact"] and same["rgba_changed_pixels"] == 0
        color = original.copy()
        color.putpixel((100, 100), (255, 255, 255, 255))
        changed = frame_comparison(original, color)
        assert changed["alpha_exact"] and changed["visible_changed_pixels"] == 1
        assert changed["advisory_highlight_delta"]["near_white_pct"] > 0
        shifted = ImageChops.offset(original, 1, 0)
        shift = frame_comparison(original, shifted)
        assert not shift["alpha_exact"] and shift["alpha_centroid_delta_px"] == [1.0, 0.0]
        soft = original.copy()
        soft.putpixel((100, 100), (50, 140, 220, 254))
        result = frame_comparison(original, soft)
        assert not result["alpha_exact"] and result["nonzero_mask_exact"] and result["bounds_exact"]
        family = root / "family"
        family.mkdir()
        atlas = Image.new("RGBA", (SIDE*COUNT, SIDE))
        for i in range(COUNT):
            atlas.paste(ImageChops.offset(original, i, 0), (i*SIDE, 0))
        for kind in KINDS:
            path = family / relative(kind)
            path.parent.mkdir()
            atlas.save(path)
        records, frames, errors = read_family(family)
        assert not errors and len(frames) == 5
        freeze(family, root / "baseline")
        assert not verify_baseline(root / "baseline", records)
        (root / "baseline" / relative("rose")).write_bytes(b"tampered")
        tampered, _, _ = read_family(root / "baseline")
        assert verify_baseline(root / "baseline", tampered)
        path = family / relative("rose")
        for invalid in (Image.new("RGB", atlas.size), Image.new("RGBA", (256, 256)), Image.new("RGBA", atlas.size)):
            invalid.save(path)
            assert read_family(family)[2]
        path.write_bytes(b"not a PNG")
        assert read_family(family)[2]
        path.unlink()
        assert read_family(family)[2]
        border = atlas.copy()
        border.putpixel((0, 0), (255, 255, 255, 1))
        border.save(path)
        assert any("outer border" in e for e in read_family(family)[2])
        assert not frame_comparison(atlas.crop((0, 0, SIDE, SIDE)), atlas.crop((SIDE, 0, 2*SIDE, SIDE)))["alpha_exact"]
        assert compare(root / "baseline", family, root / "invalid-output", 34) == 1
        invalid_report = json.loads((root / "invalid-output/report.json").read_text())
        assert not invalid_report["structural_pass"] and invalid_report["artifacts"] == {}
        (root / "baseline/manifest.json").write_text("[]")
        assert verify_baseline(root / "baseline", records)
        try:
            compare(root / "baseline", family, family / "output", 34)
            raise AssertionError("input directory must be protected")
        except ValueError:
            pass
    print("PASS: self/color/shift/alpha-only/order, frozen hash, mode/size/empty/corrupt/missing/border checks")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("self-test")
    freezing = sub.add_parser("freeze")
    freezing.add_argument("--assets", type=Path, default=ROOT / "App/Assets.xcassets")
    freezing.add_argument("--baseline", type=Path, required=True)
    comparing = sub.add_parser("compare")
    comparing.add_argument("--baseline", type=Path, required=True)
    comparing.add_argument("--candidate", type=Path, required=True)
    comparing.add_argument("--output", type=Path, required=True)
    comparing.add_argument("--visible-pt", type=float, default=34)
    args = parser.parse_args()
    try:
        if args.command == "self-test":
            return self_test()
        if args.command == "freeze":
            return freeze(args.assets.resolve(), args.baseline.resolve())
        if not math.isfinite(args.visible_pt) or not 16 <= args.visible_pt <= 40:
            parser.error("--visible-pt must be finite and between 16 and 40")
        return compare(args.baseline.resolve(), args.candidate.resolve(), args.output.resolve(), args.visible_pt)
    except (OSError, ValueError) as error:
        parser.error(str(error))


if __name__ == "__main__":
    raise SystemExit(main())
