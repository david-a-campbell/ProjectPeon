#!/usr/bin/env python3
"""Exercise compressed pivots against the bundled physics engine."""
import json
import pathlib
import subprocess
import tempfile

root = pathlib.Path(__file__).resolve().parents[2]
active = json.loads((root / 'build/mac/objects.json').read_text())
with tempfile.TemporaryDirectory(prefix='peon-pivots-') as directory:
    binary = pathlib.Path(directory) / 'check-pivots'
    subprocess.run([
        'xcrun', 'clang++', '-std=c++11', '-O2',
        '-I', str(root / 'rover'), '-I', str(root / 'rover/libs'),
        str(root / 'mac/tests/pivot_compression.cpp'),
        *[path for source, path in active.items() if source.startswith('rover/libs/Box2D/')],
        '-o', str(binary),
    ], check=True)
    subprocess.run([str(binary)], check=True)
