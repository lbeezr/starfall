#!/usr/bin/env python3
"""Open the delivered Blender scenes and reproduce their neutral frame.

Run with Blender --background --disable-autoexec --python-exit-code 1 --python verify_scenes.py --
  --package /path/to/v2 --output-dir /tmp/crystal-scene-check
The output directory must be outside the package. This never saves scene edits.
"""
import argparse
from array import array
import hashlib
import json
import math
from pathlib import Path
import sys


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def decoded_pixels(bpy, path):
    """Compare decoded samples; Blender PNG text includes time/date metadata."""
    image = bpy.data.images.load(str(path), check_existing=False)
    try:
        assert tuple(image.size) == (256, 256) and image.channels == 4
        pixels = array("f", [0]) * len(image.pixels)
        image.pixels.foreach_get(pixels)
        return pixels
    finally:
        bpy.data.images.remove(image)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--package", type=Path, default=Path(__file__).resolve().parent)
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:])
    root, output = args.package.resolve(), args.output_dir.resolve()
    if output == root or root in output.parents or output.exists():
        parser.error("choose a new verification directory outside the package")
    output.mkdir(parents=True)
    import bpy
    settings = json.loads((root / "source/scene_settings.json").read_text())
    report = {"schema": "starfall.crystal-native-reproduction.v1",
              "blender_version": bpy.app.version_string,
              "blender_build_hash": bpy.app.build_hash.decode(), "scenes": [],
              "passed": False, "limits": "Offline Blender reproduction only; no native-game or device acceptance."}
    for kind in ("rose", "aqua", "amber", "violet", "mint"):
        scene_file = root / "renders/scenes" / f"{kind}.blend"
        before_hash = sha(scene_file)
        bpy.ops.wm.open_mainfile(filepath=str(scene_file), load_ui=False)
        scene = bpy.context.scene
        mesh_objects = [obj for obj in scene.objects if obj.type == "MESH"]
        assert len(mesh_objects) == 1, f"{kind}: expected one editable mesh"
        obj = mesh_objects[0]
        assert obj.data.vertices and obj.data.polygons, f"{kind}: empty mesh"
        assert not bpy.data.libraries, f"{kind}: external library dependency"
        assert not any(im.source in {"FILE", "MOVIE", "SEQUENCE"} and not im.packed_file for im in bpy.data.images), f"{kind}: unpacked image dependency"
        assert scene.render.engine == "CYCLES" and scene.cycles.device == "CPU"
        assert scene.render.film_transparent and scene.render.image_settings.color_mode == "RGBA"
        assert (scene.render.resolution_x, scene.render.resolution_y, scene.render.resolution_percentage) == (256, 256, 100)
        assert scene.camera.data.type == "ORTHO"
        assert scene.frame_current == 4 and (scene.frame_start, scene.frame_end) == (0, 8)
        assert scene.render.filepath == f"//../frames/{kind}/frame_##"
        poses = []
        for index in range(9):
            scene.frame_set(index)
            rotation = [math.degrees(angle) for angle in obj.rotation_euler]
            expected = [settings["poses"]["x_degrees"][index], settings["poses"]["y_degrees"][index], settings["poses"]["z_degrees"]]
            assert all(abs(a - b) < 0.0001 for a, b in zip(rotation, expected)), f"{kind}: pose {index} differs"
            poses.append(rotation)
        scene.frame_set(4)
        destination = output / f"{kind}_frame_04.png"
        scene.render.filepath = str(destination)
        bpy.ops.render.render(write_still=True)
        original_file = root / "renders/frames" / kind / "frame_04.png"
        original_hash = sha(original_file)
        original_pixels = decoded_pixels(bpy, original_file)
        reproduced_pixels = decoded_pixels(bpy, destination)
        item = {"kind": kind, "scene_sha256": before_hash, "mesh_vertices": len(obj.data.vertices),
                "mesh_faces": len(obj.data.polygons), "poses_degrees": poses,
                "samples": scene.cycles.samples, "seed": scene.cycles.seed,
                "denoising": scene.cycles.use_denoising,
                "original_png_sha256": original_hash, "reproduced_png_sha256": sha(destination),
                "byte_identical_png": original_hash == sha(destination),
                "original_decoded_rgba_float_sha256": hashlib.sha256(original_pixels.tobytes()).hexdigest(),
                "reproduced_decoded_rgba_float_sha256": hashlib.sha256(reproduced_pixels.tobytes()).hexdigest(),
                "decoded_pixels_identical": original_pixels == reproduced_pixels,
                "png_metadata_note": "Blender embeds date and render timing; file bytes can differ while pixels match.",
                "scene_file_unchanged": before_hash == sha(scene_file)}
        report["scenes"].append(item)
        (output / "report.json").write_text(json.dumps(report, indent=2) + "\n")
        assert item["decoded_pixels_identical"] and item["scene_file_unchanged"], f"{kind}: reproduction differs; inspect output"
    report["passed"] = True
    (output / "report.json").write_text(json.dumps(report, indent=2) + "\n")
    print("STARFALL_SCENES_VERIFIED " + str(output / "report.json"), flush=True)


if __name__ == "__main__":
    main()
