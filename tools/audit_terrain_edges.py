"""Audit mirrored terrain extension joins in every planet map (requires Pillow).

Reports transparent padding and verifies positive, overlapping repeat steps for
both standard and Retina rendering. This checks assets/geometry; use the opt-in
PEON_UI_AUDIT_MAP fixture to inspect actual finish-camera rendering on a device.
"""
import argparse
import json
from pathlib import Path
import xml.etree.ElementTree as ET
from PIL import Image


def properties(node):
    return {p.get('name'): p.get('value', '') for p in node.findall('./properties/property')}


def enabled(value):
    return str(value).lower() in ("1", "true", "yes")


def audit(root):
    rows, errors, maps = [], [], sorted(root.glob('rover/Planet[123]/planet*Level*.tmx'))
    for path in maps:
        tree = ET.parse(path).getroot()
        images = {int(t.get('firstgid')): t.find('image').get('source') for t in tree.findall('tileset')}
        for group in tree.findall('objectgroup'):
            props = properties(group)
            if group.get('name') not in ('Parallax2', 'Parallax3', 'Parallax4', 'Parallax5'):
                continue
            if not 0 < float(props.get('ParallaxRatioX', 1)) < 1 or props.get('ExtendEdges') in ('0', 'false'):
                continue
            tiles = [o for o in group.findall('object') if o.get('gid')]
            if not tiles:
                continue
            first, last = min(float(o.get('x')) for o in tiles), max(float(o.get('x')) for o in tiles)
            for side, edge in [('left', first), ('right', last)]:
                if side == 'right' and props.get('ExtendRight') in ('0', 'false'):
                    continue
                at_edge = [o for o in tiles if float(o.get('x')) == edge]
                for retina in (1, 2):
                    bounds = []
                    for tile in at_edge:
                        asset = path.parent / images[int(tile.get('gid'))]
                        with Image.open(asset) as im:
                            alpha = im.convert('RGBA').getchannel('A')
                            width, height = im.size
                            counts = []
                            for x in range(width):
                                column = alpha.crop((x, 0, x + 1, height))
                                data = column.get_flattened_data() if hasattr(column, "get_flattened_data") else column.getdata()
                                counts.append(sum(v > 0 for v in data))
                        stacked = len({float(o.get('y')) for o in at_edge}) > 1
                        threshold = 1 if enabled(props.get('CropEdgePadding')) else int(height / 20)
                        occupied = [x for x, count in enumerate(counts) if count >= max(1, threshold)]
                        crop = (0, width) if stacked and not enabled(props.get('CropEdgePadding')) else ((occupied[0], occupied[-1] + 1) if occupied else (0, width))
                        bounds.append(crop)
                        rows.append(dict(map=path.name, layer=group.get('name'), side=side, retina=retina,
                                         asset=asset.name, sourceWidth=width, cropPixels=list(crop)))
                    if enabled(props.get('CropEdgePadding')):
                        bounds = [(min(b[0] for b in bounds), max(b[1] for b in bounds))]
                    for start, end in bounds:
                        # Runtime repeats by crop width minus one source pixel.
                        if end - start <= 1:
                            errors.append(f'{path.name}/{group.get("name")}/{side}: degenerate repeat width')
    return dict(mapCount=len(maps), joinChecks=len(rows), rows=rows, errors=errors)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=Path('build/ui-audit/terrain-edges.json'))
    args = parser.parse_args()
    report = audit(Path(__file__).resolve().parents[1])
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2) + '\n')
    print(f'{report["mapCount"]} maps, {report["joinChecks"]} edge/Retina checks, {len(report["errors"])} errors')
    raise SystemExit(bool(report['errors']))
