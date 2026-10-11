"""Find decorative beam layers mistakenly extended as reflected terrain.

Uses the actual tile alpha/color data, covering every Earth, Moon and Mars map.
Light beams may remain inside their original map extent, but must not be copied
or mirrored into the widescreen margins or the ship area.
"""
import json
from pathlib import Path
import xml.etree.ElementTree as ET
from PIL import Image


def audit(root):
    cache, rows, errors = {}, [], []
    for path in sorted(root.glob('rover/Planet*/planet*Level*.tmx')):
        tree = ET.parse(path).getroot()
        tiles = {t.get('firstgid'): (path.parent / t.find('image').get('source')).resolve()
                 for t in tree.findall('tileset')}
        for group in tree.findall('objectgroup'):
            if group.get('name') not in ('Parallax2', 'Parallax3', 'Parallax4', 'Parallax5'):
                continue
            beams = []
            for obj in group.findall('object'):
                file = tiles.get(obj.get('gid'))
                if file is None or not file.exists():
                    continue
                if file not in cache:
                    with Image.open(file) as image:
                        colors = image.convert('RGBA').getcolors(4096) or []
                    visible = sum(n for n, color in colors if color[3])
                    white = sum(n for n, color in colors
                                if color[:3] == (255, 255, 255) and 0 < color[3] < 255)
                    cache[file] = bool(visible and white / visible > .99)
                if cache[file]:
                    beams.append(file.name)
            if not beams:
                continue
            props = {p.get('name'): p.get('value') for p in group.findall('./properties/property')}
            finite = props.get('ExtendEdges', '').lower() in ('0', 'false')
            rows.append({'map': path.name, 'layer': group.get('name'), 'beams': beams, 'finite': finite})
            if not finite:
                errors.append(f'{path.name}: {group.get("name")} repeats light beams')
    return {'layers': rows, 'errors': errors}


if __name__ == '__main__':
    report = audit(Path(__file__).resolve().parents[1])
    print(json.dumps(report, indent=2))
    raise SystemExit(bool(report['errors']))
