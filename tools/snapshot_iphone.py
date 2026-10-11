#!/usr/bin/env python3
"""Request the current game framebuffer from a running development iPhone build."""
import argparse
import json
import pathlib
import subprocess
import tempfile
import time
import uuid

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--device', required=True, help='CoreDevice identifier from devicectl list devices')
parser.add_argument('--output', type=pathlib.Path, required=True)
args = parser.parse_args()
base = ['xcrun', 'devicectl', 'device', 'copy']
container = ['--device', args.device, '--domain-type', 'appDataContainer',
             '--domain-identifier', 'com.digitalfury.rover']

def copy(direction, source, destination):
    return subprocess.run(base + [direction] + container + ['--source', str(source),
                          '--destination', str(destination)], capture_output=True, text=True)

with tempfile.TemporaryDirectory(prefix='peon-snapshot-') as temp:
    temp = pathlib.Path(temp)
    request_id = str(uuid.uuid4())
    request = temp / 'request.txt'
    request.write_text(request_id)
    sent = copy('to', request, 'tmp/PeonSnapshotRequest.txt')
    if sent.returncode:
        raise SystemExit(sent.stderr or sent.stdout)
    deadline = time.monotonic() + 15
    receipt = temp / 'receipt.json'
    while time.monotonic() < deadline:
        received = copy('from', 'tmp/PeonLiveSnapshot.json', receipt)
        if received.returncode == 0:
            metadata = json.loads(receipt.read_text())
            if metadata.get('request') == request_id:
                args.output.parent.mkdir(parents=True, exist_ok=True)
                captured = copy('from', 'tmp/PeonLiveSnapshot.png', args.output)
                if captured.returncode:
                    raise SystemExit(captured.stderr or captured.stdout)
                args.output.with_suffix('.json').write_text(json.dumps(metadata, indent=2))
                print(f"Captured {metadata['scene']}: {args.output.resolve()}")
                break
        time.sleep(0.3)
    else:
        request.write_text('')
        copy('to', request, 'tmp/PeonSnapshotRequest.txt')
        raise SystemExit('No fresh frame received. Unlock the phone and keep the development game in the foreground.')
