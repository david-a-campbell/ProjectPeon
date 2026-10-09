#!/usr/bin/env python3
"""Verify saved cart preview sizes at standard and Retina resolutions."""
import hashlib, pathlib, subprocess, tempfile
root=pathlib.Path(__file__).resolve().parents[2]
objects=root/'build/mac/objects'
main=hashlib.sha1(b'mac/Main.m').hexdigest()+'.o'
with tempfile.TemporaryDirectory(prefix='peon-previews-') as directory:
    binary=pathlib.Path(directory)/'check-previews'
    command=['xcrun','clang','-Wno-deprecated-declarations','-DPROJECTPEON_MAC=1','-DCC_DIRECTOR_MAC_THREAD=2','-fno-objc-arc','-fblocks']
    for path in ['mac','mac/compat','rover','rover/cocos2d','rover/PRKit','rover/Tutorial','rover/libs/kazmath/include']:
        command+=['-I',str(root/path)]
    command+=['-include',str(root/'mac/Prefix.pch'),str(root/'mac/tests/previews.m'),*[str(p) for p in objects.glob('*.o') if p.name!=main and len(p.stem)==40],'-lc++','-lz','-o',str(binary)]
    for framework in ['Cocoa','OpenGL','QuartzCore','CoreVideo','CoreData','AVFoundation','AudioToolbox','CoreGraphics','StoreKit','SystemConfiguration','Security']:
        command+=['-framework',framework]
    subprocess.run(command,check=True)
    subprocess.run([str(binary),str(root/'build/mac/Project Peon.app/Contents/Resources')],check=True)
