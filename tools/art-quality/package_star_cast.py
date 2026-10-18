#!/usr/bin/env python3
"""Package generated transparent cast bodies; never synthesize character art."""
import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image
from PIL import ImageFilter

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'Artwork/StarCast/crystal-glow-bodies.png'
NAMES = ['Spark', 'Sunny', 'Pip', 'Twinkle', 'Nova', 'Dusk']


def isolated_body(cell):
    """Keep the largest connected alpha island, excluding stray neighboring glints."""
    width, height = cell.size
    alpha = cell.getchannel('A')
    support = bytearray(value >= 128 for value in alpha.tobytes())
    largest = []
    for start in range(len(support)):
        if not support[start]:
            continue
        support[start] = 0
        component = [start]
        for pixel in component:
            x, y = pixel % width, pixel // width
            for neighbor in (pixel - 1 if x else -1, pixel + 1 if x < width - 1 else -1,
                             pixel - width if y else -1, pixel + width if y < height - 1 else -1):
                if neighbor >= 0 and support[neighbor]:
                    support[neighbor] = 0
                    component.append(neighbor)
        if len(component) > len(largest):
            largest = component
    mask = bytearray(width * height)
    for pixel in largest:
        mask[pixel] = 255
    coverage = Image.frombytes('L', (width, height), bytes(mask)).filter(ImageFilter.MaxFilter(5))
    cell.putalpha(Image.frombytes('L', (width, height), bytes(
        a if keep else 0 for a, keep in zip(alpha.tobytes(), coverage.tobytes()))))
    return cell


def package_body(cell, name):
    alpha = cell.getchannel('A')
    # Ignore near-transparent edge haze when fitting the body. Keep original alpha.
    bounds = alpha.point(lambda value: 255 if value >= 128 else 0).getbbox()
    assert bounds and bounds[2] - bounds[0] > 200
    body = cell.crop(bounds)
    # Normalize the source's existing alpha range (the six-body plate peaks at 254).
    peak = body.getchannel('A').getextrema()[1]
    body.putalpha(body.getchannel('A').point(lambda value: round(value * 255 / peak)))
    body.thumbnail((208, 208), Image.Resampling.LANCZOS)
    canvas = Image.new('RGBA', (256, 256))
    canvas.paste(body, ((256 - body.width) // 2, (256 - body.height) // 2))
    destination = ROOT / f'App/Assets.xcassets/StarCast{name}.imageset'
    destination.mkdir(exist_ok=True)
    output = destination / 'body.png'
    canvas.save(output)
    (destination / 'Contents.json').write_text(json.dumps({
        'images': [{'filename': 'body.png', 'idiom': 'universal', 'scale': '1x'}],
        'info': {'author': 'xcode', 'version': 1}
    }, indent=2) + '\n')
    return {'sourceBounds': bounds, 'bodySize': list(body.size),
                              'sha256': hashlib.sha256(output.read_bytes()).hexdigest()}

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--opal', action='store_true', help='Package only the selected Opal Orb source')
    parser.add_argument('--gravity', action='store_true', help='Package the magnetic crystal and gravity hole sources')
    args = parser.parse_args()
    if args.gravity:
        receipt = {'generator': 'built-in image_gen', 'frames': {}}
        for name in ['Magnet', 'Hole']:
            source = ROOT / f'Artwork/StarCast/{name.lower()}-body-v1.png'
            cell = Image.open(source).convert('RGBA')
            assert cell.getchannel('A').getextrema()[0] == 0, 'Real transparency required'
            assert cell.getpixel((cell.width // 2, cell.height // 2))[3] >= 250, 'Opaque body center required'
            frame = package_body(isolated_body(cell), name)
            frame['sourceSHA256'] = hashlib.sha256(source.read_bytes()).hexdigest()
            receipt['frames'][name] = frame
        (ROOT / 'Artwork/StarCast/gravity-packaging.json').write_text(json.dumps(receipt, indent=2) + '\n')
        return
    if args.opal:
        source = ROOT / 'Artwork/StarCast/opal-body-v1.png'
        cell = Image.open(source).convert('RGBA')
        assert cell.getchannel('A').getextrema()[0] == 0, 'Real transparency required'
        receipt = {'sourceSHA256': hashlib.sha256(source.read_bytes()).hexdigest(),
                   'frames': {'Opal': package_body(isolated_body(cell), 'Opal')}}
        (ROOT / 'Artwork/StarCast/opal-packaging.json').write_text(json.dumps(receipt, indent=2) + '\n')
        return
    plate = Image.open(SOURCE).convert('RGBA')
    assert plate.size == (1536, 1024), 'Unexpected production plate layout'
    assert plate.getchannel('A').getextrema()[0] == 0, 'Real transparency required'
    receipt = {'sourceSHA256': hashlib.sha256(SOURCE.read_bytes()).hexdigest(), 'frames': {}}
    for index, name in enumerate(NAMES):
        x, y = index % 3 * 512, index // 3 * 512
        cell = isolated_body(plate.crop((x, y, x + 512, y + 512)))
        receipt['frames'][name] = package_body(cell, name)
    (ROOT / 'Artwork/StarCast/packaging.json').write_text(json.dumps(receipt, indent=2) + '\n')


if __name__ == '__main__':
    main()
