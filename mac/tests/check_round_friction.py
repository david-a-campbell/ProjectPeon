#!/usr/bin/env python3
"""Verify pair-specific friction through the game's contact listener."""
import json
import pathlib
import subprocess
import tempfile

root = pathlib.Path(__file__).resolve().parents[2]
active = json.loads((root / 'build/mac/objects.json').read_text())
with tempfile.TemporaryDirectory(prefix='peon-friction-') as directory:
    binary = pathlib.Path(directory) / 'check-friction'
    command = ['xcrun', 'clang++', '-std=c++11', '-Wno-deprecated-declarations',
               '-DPROJECTPEON_MAC=1', '-DCC_DIRECTOR_MAC_THREAD=2', '-fno-objc-arc', '-fblocks']
    includes = [root / 'mac', root / 'mac/compat', root / 'rover', root / 'rover/libs',
                root / 'rover/libs/kazmath/include']
    includes += sorted({path.parent for path in (root / 'rover').rglob('*.h')
                        if 'boost.framework' not in str(path)})
    for path in includes:
        command += ['-I', str(path)]
    command += ['-include', str(root / 'mac/Prefix.pch'),
                str(root / 'mac/tests/round_friction.mm'),
                *[path for source, path in active.items() if source != 'mac/Main.m'],
                '-lc++', '-lz', '-o', str(binary)]
    for framework in ['Cocoa', 'OpenGL', 'QuartzCore', 'CoreVideo', 'CoreData',
                      'AVFoundation', 'VideoToolbox', 'CoreMedia', 'AudioToolbox',
                      'CoreGraphics', 'StoreKit', 'SystemConfiguration', 'Security']:
        command += ['-framework', framework]
    subprocess.run(command, check=True)
    subprocess.run([str(binary)], check=True)
