#!/usr/bin/env python3
"""Verify results-to-driving/building reset transitions."""
import json, pathlib, subprocess, tempfile
root=pathlib.Path(__file__).resolve().parents[2]
objects=root/'build/mac/objects'
active=json.loads((root/'build/mac/objects.json').read_text())
with tempfile.TemporaryDirectory(prefix='peon-restart-') as directory:
    binary=pathlib.Path(directory)/'check-restart'
    command=['xcrun','clang++','-std=c++11','-Wno-deprecated-declarations','-DPROJECTPEON_MAC=1','-DCC_DIRECTOR_MAC_THREAD=2','-fno-objc-arc','-fblocks']
    for path in ['mac','mac/compat','rover','rover/libs','rover/cocos2d','rover/cocos2d/Support','rover/PRKit','rover/Tutorial','rover/libs/kazmath/include']:
        command+=['-I',str(root/path)]
    
    for path in sorted({f.parent for f in (root/'rover').rglob('*.h')}):
        command+=['-I',str(path)]
    command+=['-include',str(root/'mac/Prefix.pch'),str(root/'mac/tests/restart.mm'),*[p for source,p in active.items() if source!='mac/Main.m'],'-lc++','-lz','-o',str(binary)]
    for framework in ['Cocoa','OpenGL','QuartzCore','CoreVideo','CoreData','AVFoundation','VideoToolbox','CoreMedia','AudioToolbox','CoreGraphics','StoreKit','SystemConfiguration','Security']:
        command+=['-framework',framework]
    subprocess.run(command,check=True)
    subprocess.run([str(binary),str(root/'build/mac/Project Peon.app/Contents/Resources'),str(root/'rover')],check=True)
