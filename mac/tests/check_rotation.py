#!/usr/bin/env python3
"""Verify Mac part rotation pivots, limits, connections and editing guards."""
import hashlib, pathlib, subprocess, tempfile
root=pathlib.Path(__file__).resolve().parents[2]
objects=root/'build/mac/objects'
main=hashlib.sha1(b'mac/Main.m').hexdigest()+'.o'
with tempfile.TemporaryDirectory(prefix='peon-rotation-') as directory:
    binary=pathlib.Path(directory)/'check-rotation'
    command=['xcrun','clang++','-std=c++11','-Wno-deprecated-declarations','-DPROJECTPEON_MAC=1','-DCC_DIRECTOR_MAC_THREAD=2','-fno-objc-arc','-fblocks']
    for path in ['mac','mac/compat','rover','rover/libs','rover/cocos2d','rover/cocos2d/Support','rover/PRKit','rover/Tutorial','rover/libs/kazmath/include']:
        command+=['-I',str(root/path)]
    
    for path in sorted({f.parent for f in (root/'rover').rglob('*.h')}):
        command+=['-I',str(path)]
    command+=['-include',str(root/'mac/Prefix.pch')]
    native=pathlib.Path(directory)/'mac-input.o'
    native_command=['xcrun','clang',*[flag for flag in command[2:] if flag!='-std=c++11'], '-Dmain=PeonApplicationMain','-c',str(root/'mac/Main.m'),'-o',str(native)]
    subprocess.run(native_command,check=True)
    command+=[str(native),str(root/'mac/tests/rotation.mm'),*[str(p) for p in objects.glob('*.o') if p.name!=main and len(p.stem)==40],'-lc++','-lz','-o',str(binary)]
    for framework in ['Cocoa','OpenGL','QuartzCore','CoreVideo','CoreData','AVFoundation','VideoToolbox','CoreMedia','AudioToolbox','CoreGraphics','StoreKit','SystemConfiguration','Security']:
        command+=['-framework',framework]
    subprocess.run(command,check=True)
    subprocess.run([str(binary),str(root/'build/mac/Project Peon.app/Contents/Resources')],check=True)
