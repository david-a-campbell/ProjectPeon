"""Find baked rectangular water tint on opaque forest in planet backgrounds.

The old artwork composited 25% aqua water over solid forest, producing
115,145,123 instead of 102,119,85. Restore only that opaque composite color;
the translucent water, transparent pixels and shoreline silhouettes remain.
Run with --repair to fix the source tiles; otherwise this is a regression audit.
Requires Pillow.
"""
import argparse
from pathlib import Path
from PIL import Image

FOREST = (102, 119, 85, 255)
TINTED_FOREST = (115, 145, 123, 255)


def audit(root, repair=False):
    checked, affected = 0, []
    for path in sorted(root.glob('rover/Planet*/*_P*.png')):
        with Image.open(path) as source:
            image = source.convert('RGBA')
        checked += 1
        colors = dict((color, count) for count, color in image.getcolors(image.width * image.height))
        count = colors.get(TINTED_FOREST, 0)
        if not count or FOREST not in colors:
            continue
        affected.append((path.relative_to(root), count))
        if repair:
            pixels = image.load()
            for y in range(image.height):
                for x in range(image.width):
                    if pixels[x, y] == TINTED_FOREST:
                        pixels[x, y] = FOREST
            image.save(path)
    return checked, affected


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repair', action='store_true')
    args = parser.parse_args()
    checked, affected = audit(Path(__file__).resolve().parents[1], args.repair)
    for path, count in affected:
        print(f'{path}: {count} tinted forest pixels')
    print(f'{checked} backgrounds checked; {len(affected)} affected tiles' + (' repaired' if args.repair else ''))
    raise SystemExit(bool(affected) and not args.repair)
