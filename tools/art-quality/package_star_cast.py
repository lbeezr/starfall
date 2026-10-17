#!/usr/bin/env python3
"""Package the generated transparent six-body plate; never synthesize character art."""
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
    alpha = cell.getchannel('A')
    support = bytearray(value >= 128 for value in alpha.tobytes())
    largest = []
    for start in range(len(support)):
        if not support[start]:
            continue
        support[start] = 0
        component = [start]
        for pixel in component:
            x, y = pixel % 512, pixel // 512
            for neighbor in (pixel - 1 if x else -1, pixel + 1 if x < 511 else -1,
                             pixel - 512 if y else -1, pixel + 512 if y < 511 else -1):
                if neighbor >= 0 and support[neighbor]:
                    support[neighbor] = 0
                    component.append(neighbor)
        if len(component) > len(largest):
            largest = component
    mask = bytearray(512 * 512)
    for pixel in largest:
        mask[pixel] = 255
    coverage = Image.frombytes('L', (512, 512), bytes(mask)).filter(ImageFilter.MaxFilter(5))
    cell.putalpha(Image.frombytes('L', (512, 512), bytes(
        a if keep else 0 for a, keep in zip(alpha.tobytes(), coverage.tobytes()))))
    return cell


def main():
    plate = Image.open(SOURCE).convert('RGBA')
    assert plate.size == (1536, 1024), 'Unexpected production plate layout'
    assert plate.getchannel('A').getextrema()[0] == 0, 'Real transparency required'
    receipt = {'sourceSHA256': hashlib.sha256(SOURCE.read_bytes()).hexdigest(), 'frames': {}}
    for index, name in enumerate(NAMES):
        x, y = index % 3 * 512, index // 3 * 512
        cell = isolated_body(plate.crop((x, y, x + 512, y + 512)))
        alpha = cell.getchannel('A')
        # Ignore near-transparent edge haze when fitting the body. Keep original alpha.
        bounds = alpha.point(lambda value: 255 if value >= 128 else 0).getbbox()
        assert bounds and bounds[2] - bounds[0] > 200
        body = cell.crop(bounds)
        # The generator capped alpha at 254; normalize its existing coverage range.
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
        receipt['frames'][name] = {'sourceBounds': bounds, 'bodySize': list(body.size),
                                  'sha256': hashlib.sha256(output.read_bytes()).hexdigest()}
    (ROOT / 'Artwork/StarCast/packaging.json').write_text(json.dumps(receipt, indent=2) + '\n')


if __name__ == '__main__':
    main()
