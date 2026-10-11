#!/usr/bin/env python3
"""Compare settled, rendered Mac/iPhone layouts and list platform-gated UI code.

Capture with PEON_UI_AUDIT=1 in a Debug build. Visit matching screens on both
platforms, let animations finish, and save their console output. Run:
  python3 tools/audit_ui.py compare mac.log iphone.log --output report.json
  python3 tools/audit_ui.py scan --output gates.json
Missing screens are reported as untested, never silently passed.
"""
import argparse
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def snapshots(path):
    result = {}
    for line in Path(path).read_text(errors='replace').splitlines():
        if line.startswith('{'):
            record = json.loads(line)
        elif 'PEON_UI_AUDIT ' in line:
            record = json.loads(line.split('PEON_UI_AUDIT ', 1)[1])
        else:
            continue
        result[record['screen']] = record
    return result


def compare(mac, iphone, tolerance):
    a, b = snapshots(mac), snapshots(iphone)
    report = {'compared': [], 'untested': sorted(a.keys() ^ b.keys()), 'differences': [], 'violations': []}
    for screen in sorted(a.keys() & b.keys()):
        report['compared'].append(screen)
        left = {r['path']: r for r in a[screen]['nodes']}
        right = {r['path']: r for r in b[screen]['nodes']}
        for path in sorted(left.keys() | right.keys()):
            x, y = left.get(path), right.get(path)
            if x is None or y is None:
                report['differences'].append({'screen': screen, 'path': path, 'reason': 'node missing', 'mac': x, 'iphone': y})
                continue
            for field in ('origin', 'axes', 'sourcePixels'):
                if field not in x or field not in y: continue
                if any(abs(m - n) > tolerance for m, n in zip(x[field], y[field])):
                    report['differences'].append({'screen': screen, 'path': path, 'field': field, 'mac': x[field], 'iphone': y[field]})
            if x.get('text') != y.get('text'):
                # Keep control text differences explicit for reviewer interpretation.
                report['differences'].append({'screen': screen, 'path': path, 'field': 'text', 'mac': x.get('text'), 'iphone': y.get('text')})
    for platform, records in [('mac', a), ('iphone', b)]:
        for screen, record in records.items():
            for row in record['nodes']:
                if row['tag'] == 9905:
                    xx, xy, yx, yy = row['axes']
                    width, height = math.hypot(xx, xy), math.hypot(yx, yy)
                    if abs(width - height) > tolerance or abs(width - 48) > tolerance:
                        report['violations'].append({'platform': platform, 'screen': screen, 'rule': 'close button must be circular and 48 points', 'size': [width, height]})
    if not report['compared']:
        report['violations'].append({'rule': 'no matching captured screens'})
    return report


def scan():
    gates, scales = [], []
    # Review application/UI code only; OS bridges and bundled engines have
    # legitimate platform conditionals. Keep findings rather than guessing intent.
    for path in sorted((ROOT / 'rover').glob('*')):
        if path.suffix not in ('.m', '.mm', '.h'):
            continue
        lines = path.read_text(errors='replace').splitlines()
        for index, line in enumerate(lines):
            if line.lstrip().startswith(('#if', '#elif')) and 'PROJECTPEON_MAC' in line:
                gates.append({'file': str(path.relative_to(ROOT)), 'line': index+1, 'context': '\n'.join(lines[index:index+8])})
            if 'SCREEN_SCALE' in line and not line.lstrip().startswith('#'):
                scales.append({'file': str(path.relative_to(ROOT)), 'line': index+1, 'code': line.strip()})
    return {'platform_gates_to_review': gates, 'pixel_dependent_layout_to_review': scales}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='mode', required=True)
    p = sub.add_parser('compare'); p.add_argument('mac'); p.add_argument('iphone'); p.add_argument('--tolerance', type=float, default=0.75); p.add_argument('--output', required=True)
    p = sub.add_parser('scan'); p.add_argument('--output', required=True)
    args = parser.parse_args()
    result = scan() if args.mode == 'scan' else compare(args.mac, args.iphone, args.tolerance)
    Path(args.output).write_text(json.dumps(result, indent=2)+'\n')
    if args.mode == 'compare':
        print(f"Compared {len(result['compared'])} screens; {len(result['differences'])} differences; {len(result['violations'])} violations; {len(result['untested'])} untested screens")
        return int(bool(result['differences'] or result['violations'] or result['untested']))
    print(f"Review {len(result['platform_gates_to_review'])} platform gates and {len(result['pixel_dependent_layout_to_review'])} pixel-dependent layouts")
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
