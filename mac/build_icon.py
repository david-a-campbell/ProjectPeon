#!/usr/bin/env python3
"""Package the game's original app icon artwork for macOS."""
import pathlib
import subprocess
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[1]

def build_icon(destination):
    destination = pathlib.Path(destination)
    with tempfile.TemporaryDirectory(prefix='peon-icon-') as directory:
        iconset = pathlib.Path(directory) / 'ProjectPeon.iconset'
        iconset.mkdir()
        for size in (16, 32, 128, 256, 512):
            for scale in (1, 2):
                pixels = size * scale
                source = ROOT / 'rover' / ('Icon512.png' if pixels <= 512 else 'Icon1024.png')
                name = f'icon_{size}x{size}' + ('@2x' if scale == 2 else '') + '.png'
                subprocess.run(['sips', '-z', str(pixels), str(pixels), str(source), '--out', str(iconset / name)],
                               check=True, stdout=subprocess.DEVNULL)
        subprocess.run(['iconutil', '-c', 'icns', str(iconset), '-o', str(destination)], check=True)

if __name__ == '__main__':
    build_icon(ROOT / 'mac/Assets/ProjectPeon.icns')
