#!/usr/bin/env python3
"""Verify music cycling through every scene playlist."""
import json, pathlib, subprocess, tempfile
root=pathlib.Path(__file__).resolve().parents[2]
objects=root/'build/mac/objects'
build_objects=json.loads((root/'build/mac/objects.json').read_text())
with tempfile.TemporaryDirectory(prefix='peon-music-') as directory:
    binary=pathlib.Path(directory)/'check-music'
    command=['xcrun','clang','-Wno-deprecated-declarations','-DPROJECTPEON_MAC=1','-DCC_DIRECTOR_MAC_THREAD=2','-fno-objc-arc','-fblocks']
    for path in ['mac','mac/compat','rover','rover/cocos2d','rover/PRKit','rover/libs/kazmath/include']:
        command+=['-I',str(root/path)]
    command+=['-include',str(root/'mac/Prefix.pch'),str(root/'mac/tests/music.m'),*[path for source,path in build_objects.items() if source!='mac/Main.m'],'-lc++','-lz','-o',str(binary)]
    for framework in ['Cocoa','OpenGL','QuartzCore','CoreVideo','CoreData','AVFoundation','VideoToolbox','CoreMedia','AudioToolbox','CoreGraphics','StoreKit','SystemConfiguration','Security']:
        command+=['-framework',framework]
    subprocess.run(command,check=True)
    subprocess.run([str(binary),str(root/'rover/Audio/Music/MusicTracks.plist')],check=True)
