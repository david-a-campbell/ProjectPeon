"""Verify audit capture hooks are absent from the built iPhone Release binary."""
import argparse
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
MARKERS = ('PeonSnapshotRequest.txt', 'PeonLiveSnapshot', 'PeonUIAudit.jsonl',
           'PEON_UI_AUDIT', 'PEON_UI_AUDIT_CAPTURE', 'PEON_UI_AUDIT_FIXTURES')


def strings(path):
    return subprocess.check_output(['strings', str(path)], text=True).splitlines()


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--release', type=Path, default=ROOT / 'build/ios/device/Build/Products/Release-iphoneos/rover.app/rover')
    parser.add_argument('--development', type=Path)
    args = parser.parse_args()
    release = strings(args.release)
    leaked = [marker for marker in MARKERS if any(marker in value for value in release)]
    if leaked:
        raise SystemExit(f'Production binary contains audit hooks: {leaked}')
    if args.development:
        development = strings(args.development)
        missing = [marker for marker in MARKERS if not any(marker in value for value in development)]
        if missing:
            raise SystemExit(f'Development binary lost audit hooks: {missing}')
    print('Production audit hooks absent' + ('; development hooks retained' if args.development else ''))
