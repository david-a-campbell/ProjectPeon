#!/usr/bin/env python3
"""Render the real PRFilledPolygon code and check its pixels on a 64-bit Mac."""
import hashlib, pathlib, subprocess, tempfile
root=pathlib.Path(__file__).resolve().parents[2]
objects=root/'build/mac/objects'
main=hashlib.sha1(b'mac/Main.m').hexdigest()+'.o'
with tempfile.TemporaryDirectory(prefix='peon-terrain-') as directory:
    binary=pathlib.Path(directory)/'check-terrain'
    command=['xcrun','clang','-Wno-deprecated-declarations','-DPROJECTPEON_MAC=1','-DCC_DIRECTOR_MAC_THREAD=2','-fno-objc-arc','-fblocks']
    for path in ['mac','mac/compat','rover','rover/cocos2d','rover/PRKit','rover/libs/kazmath/include']:
        command+=['-I',str(root/path)]
    command+=['-include',str(root/'mac/Prefix.pch'),str(root/'mac/tests/terrain.m'),*[str(p) for p in objects.glob('*.o') if p.name!=main and len(p.stem)==40],'-lc++','-lz','-o',str(binary)]
    for framework in ['Cocoa','OpenGL','QuartzCore','CoreVideo','CoreData','AVFoundation','VideoToolbox','CoreMedia','AudioToolbox','CoreGraphics','StoreKit','SystemConfiguration','Security']:
        command+=['-framework',framework]
    subprocess.run(command,check=True)
    subprocess.run([str(binary)],check=True)
