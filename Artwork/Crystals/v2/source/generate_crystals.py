#!/usr/bin/env python3
"""Author new v2 Blender scenes and render selected frames; never read old pixels.

Example (Blender owns execution):
  blender --background --factory-startup -t 4 --python generate_crystals.py -- \
    --kinds aqua --frames 4,1 --samples 128 --output-dir /tmp/starfall-crystal-v2-pilot
All source geometry, colors, poses and lights live in scene_settings.json.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
import sys
from pathlib import Path


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def arguments():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--settings", type=Path, default=Path(__file__).with_name("scene_settings.json"))
    parser.add_argument("--kinds", default="aqua", help="comma-separated subset: rose,aqua,amber,violet,mint or all")
    parser.add_argument("--frames", default="4,1", help="comma-separated indices 0..8; default is the bounded pilot")
    parser.add_argument("--samples", type=int, help="defaults to the configured pilot sample count")
    parser.add_argument("--seed", type=int, help="defaults to the configured fixed seed")
    parser.add_argument("--no-denoise", action="store_true", help="same-geometry sampling control")
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--overwrite", action="store_true", help="replace requested frames, scene and receipt in this output only")
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    args = parser.parse_args(argv)
    settings_bytes = args.settings.read_bytes()
    settings = json.loads(settings_bytes)
    # Freeze provenance before the first scene; long runs must not label later
    # kinds with newer on-disk settings than the values actually loaded here.
    args.settings_sha256 = hashlib.sha256(settings_bytes).hexdigest()
    args.generator_sha256 = digest(Path(__file__).resolve())
    args.samples = settings["render"]["pilot_samples"] if args.samples is None else args.samples
    args.seed = settings["render"]["seed"] if args.seed is None else args.seed
    kinds = list(settings["geometry"]["kinds"]) if args.kinds == "all" else args.kinds.split(",")
    try:
        frames = [int(value) for value in args.frames.split(",")]
    except ValueError:
        parser.error("--frames must contain integer indices")
    if not kinds or len(set(kinds)) != len(kinds) or any(k not in settings["geometry"]["kinds"] for k in kinds):
        parser.error("--kinds must be a unique subset of the five configured kinds")
    if not frames or len(set(frames)) != len(frames) or any(i not in range(9) for i in frames):
        parser.error("--frames must be unique indices from 0 through 8")
    if not 1 <= args.samples <= 4096 or not 0 <= args.seed <= 2147483647:
        parser.error("samples must be 1..4096 and seed must be 0..2147483647")
    contract = settings["contract"]
    if contract != {"frame_side_px": 256, "frame_count": 9, "neutral_index": 4, "pivot_raster_px": [128, 128]}:
        parser.error("settings must retain the 256px / nine-frame / neutral-4 / centered-pivot contract")
    if len(settings["poses"]["x_degrees"]) != 9 or len(settings["poses"]["y_degrees"]) != 9:
        parser.error("settings must declare all nine source poses")
    args.output_dir = args.output_dir.resolve()
    for ancestor in Path(__file__).resolve().parents:
        protected = ancestor / "App/Assets.xcassets"
        if (ancestor / "Sources/StarfallCore").is_dir() and protected.is_dir():
            if args.output_dir == protected or protected in args.output_dir.parents:
                parser.error("render output must not be inside the runtime asset catalog")
            break
    for kind in kinds:
        targets = [args.output_dir / "frames" / kind / f"frame_{i:02}.png" for i in frames]
        targets += [args.output_dir / "scenes" / f"{kind}.blend", args.output_dir / "metadata" / f"{kind}.json"]
        if not args.overwrite and any(path.exists() for path in targets):
            parser.error(f"{kind}: output already exists; choose a versioned directory or use --overwrite")
    return args, settings, kinds, frames


def linear_color(hex_color):
    rgb = [int(hex_color[i:i+2], 16) / 255 for i in (1, 3, 5)]
    return tuple(value / 12.92 if value <= 0.04045 else ((value + 0.055) / 1.055) ** 2.4 for value in rgb)


def profile(kind_settings):
    """Counterclockwise regular profile with explicit, planar corner cuts."""
    sides = kind_settings["sides"]
    radius = kind_settings["radius"]
    start = math.radians(kind_settings["angle_degrees"])
    vertices = [(radius * math.cos(start + i * math.tau / sides),
                 radius * math.sin(start + i * math.tau / sides)) for i in range(sides)]
    cut = kind_settings["corner_cut"]
    if cut == 0:
        return vertices
    result = []
    for i, vertex in enumerate(vertices):
        for neighbor in (vertices[(i - 1) % sides], vertices[(i + 1) % sides]):
            distance = math.dist(vertex, neighbor)
            if not 0 < cut < distance / 2:
                raise ValueError("corner cut must be positive and smaller than half an edge")
            result.append(tuple(a + (b - a) * cut / distance for a, b in zip(vertex, neighbor)))
    return result


def make_crystal(bpy, settings, kind):
    shape = settings["geometry"]["kinds"][kind]
    points = profile(shape)
    rings = settings["geometry"]["rings"]
    n = len(points)
    vertices = [(x * ring["scale"], y * ring["scale"], ring["z"]) for ring in rings for x, y in points]
    faces = [tuple(reversed(range(n)))]
    for ring in range(len(rings) - 1):
        for i in range(n):
            j = (i + 1) % n
            faces.append((ring*n+i, ring*n+j, (ring+1)*n+j, (ring+1)*n+i))
    faces.append(tuple((len(rings) - 1) * n + i for i in range(n)))
    mesh = bpy.data.meshes.new(f"{kind}_beveled_mesh_v2")
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(f"{kind}_starshard_v2", mesh)
    bpy.context.collection.objects.link(obj)
    obj.location = settings["poses"]["pivot_world"]
    obj.rotation_mode = "XYZ"
    for polygon in mesh.polygons:
        polygon.use_smooth = not settings["geometry"]["flat_faces"]

    color = linear_color(shape["color_srgb"])
    controls = settings["material"]
    material = bpy.data.materials.new(f"{kind}_candy_glass_v2")
    material.use_nodes = True
    principled = material.node_tree.nodes.get("Principled BSDF")
    principled.inputs["Base Color"].default_value = (*color, 1)
    for socket, name in (("Roughness", "roughness"), ("Metallic", "metallic"), ("IOR", "ior"),
                         ("Specular IOR Level", "specular_ior_level"), ("Transmission Weight", "transmission_weight"),
                         ("Coat Weight", "coat_weight"), ("Coat Roughness", "coat_roughness")):
        principled.inputs[socket].default_value = controls[name]
    tint = controls["coat_tint_fraction"]
    principled.inputs["Coat Tint"].default_value = (*(1 - tint + tint * c for c in color), 1)
    obj.data.materials.append(material)
    for index, (x, y) in enumerate(zip(settings["poses"]["x_degrees"], settings["poses"]["y_degrees"])):
        obj.rotation_euler = tuple(math.radians(v) for v in (x, y, settings["poses"]["z_degrees"]))
        obj.keyframe_insert(data_path="rotation_euler", frame=index)
    return obj, color


def point_at(obj, target):
    from mathutils import Vector
    obj.rotation_euler = (Vector(target) - obj.location).to_track_quat("-Z", "Y").to_euler()


def lighting(bpy, settings, color):
    world = bpy.data.worlds.new("quiet_neutral_world")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (1, 1, 1, 1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = settings["world_strength"]
    bpy.context.scene.world = world
    for name in ("key", "fill", "rim"):
        values = settings[name]
        data = bpy.data.lights.new(name, "AREA")
        data.shape = "RECTANGLE"
        data.energy, data.size, data.size_y = values["energy"], values["width"], values["height"]
        if name == "key":
            tint = values["tint_fraction"]
            data.color = tuple(1 - tint + tint * channel for channel in color)
        else:
            data.color = values["color"]
        obj = bpy.data.objects.new(name, data)
        bpy.context.collection.objects.link(obj)
        obj.location = values["position"]
        if name == "key":
            # Long strip tracks the reflection's tilt direction; the crown keeps
            # a localized diagonal reflection on both sides of neutral.
            obj.rotation_euler = (0, 0, math.radians(values["rotation_z_degrees"]))
        else:
            point_at(obj, (0, 0, 0))


def configure(bpy, settings, args):
    scene = bpy.context.scene
    render = settings["render"]
    scene.render.engine = render["engine"]
    scene.cycles.device = render["device"]
    scene.cycles.samples, scene.cycles.seed = args.samples, args.seed
    scene.cycles.use_animated_seed = False
    scene.cycles.use_adaptive_sampling = render["adaptive_sampling"]
    scene.cycles.use_denoising = render["denoising"] and not args.no_denoise
    scene.cycles.denoiser = render["denoiser"]
    for key in ("max_bounces", "diffuse_bounces", "glossy_bounces", "transmission_bounces"):
        setattr(scene.cycles, key, render[key])
    scene.cycles.filter_width = render["pixel_filter_width"]
    scene.render.resolution_x = scene.render.resolution_y = 256
    scene.render.resolution_percentage = 100
    scene.render.threads_mode = "FIXED"
    scene.render.threads = render["threads"]
    scene.render.pixel_aspect_x = scene.render.pixel_aspect_y = 1
    scene.render.film_transparent = render["film_transparent"]
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = render["color_mode"]
    scene.render.image_settings.color_depth = render["color_depth"]
    scene.render.image_settings.compression = 15
    scene.render.use_file_extension = True
    scene.render.use_compositing = False
    scene.render.use_sequencer = False
    scene.view_settings.view_transform = render["view_transform"]
    scene.view_settings.look = render["look"]
    scene.view_settings.exposure = render["exposure"]
    scene.view_settings.gamma = render["gamma"]
    scene.frame_start, scene.frame_end = 0, 8
    camera_data = bpy.data.cameras.new("orthographic_camera")
    camera_data.type, camera_data.ortho_scale = "ORTHO", settings["camera"]["ortho_scale"]
    camera = bpy.data.objects.new("orthographic_camera", camera_data)
    bpy.context.collection.objects.link(camera)
    camera.location = settings["camera"]["position"]
    point_at(camera, settings["camera"]["target"])
    scene.camera = camera
    return scene


def main():
    args, settings, kinds, frames = arguments()
    import bpy
    for kind in kinds:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        scene = configure(bpy, settings, args)
        obj, color = make_crystal(bpy, settings, kind)
        lighting(bpy, settings["lighting"], color)
        scene["starfall_authorship"] = settings["authorship"]
        scene["starfall_neutral_index"] = 4
        scene["starfall_generator_sha256"] = args.generator_sha256
        scene["starfall_settings_sha256"] = args.settings_sha256
        output = args.output_dir
        for subdir in (output / "frames" / kind, output / "scenes", output / "metadata"):
            subdir.mkdir(parents=True, exist_ok=True)
        scene.frame_set(4)
        scene.render.filepath = f"//../frames/{kind}/frame_##"
        bpy.context.preferences.filepaths.save_version = 0
        blend_path = output / "scenes" / f"{kind}.blend"
        bpy.ops.wm.save_as_mainfile(filepath=str(blend_path), check_existing=False, compress=False)
        receipt = {
            "schema": "starfall.crystal-v2-render.v1", "kind": kind,
            "authorship": settings["authorship"], "blender_version": bpy.app.version_string,
            "blender_build_hash": bpy.app.build_hash.decode(),
            "generator_sha256": args.generator_sha256, "settings_sha256": args.settings_sha256,
            "seed": args.seed, "samples": args.samples, "denoising": scene.cycles.use_denoising,
            "settings": settings, "mesh_vertices": len(obj.data.vertices), "mesh_faces": len(obj.data.polygons),
            "blend": {"path": f"scenes/{kind}.blend", "sha256": digest(blend_path)},
            "requested_frames": frames, "frames": [], "complete": False,
        }
        metadata_path = output / "metadata" / f"{kind}.json"
        metadata_path.write_text(json.dumps(receipt, indent=2) + "\n")
        for index in frames:
            scene.frame_set(index)
            relative = f"frames/{kind}/frame_{index:02}.png"
            scene.render.filepath = str(output / relative)
            bpy.ops.render.render(write_still=True)
            receipt["frames"].append({"index": index, "path": relative, "sha256": digest(output / relative)})
            metadata_path.write_text(json.dumps(receipt, indent=2) + "\n")
        receipt["complete"] = True
        metadata_path.write_text(json.dumps(receipt, indent=2) + "\n")
        print(f"STARFALL_V2_COMPLETE {kind}: {len(frames)} frames; {metadata_path}", flush=True)


if __name__ == "__main__":
    main()
