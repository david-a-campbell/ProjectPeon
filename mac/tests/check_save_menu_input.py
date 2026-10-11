#!/usr/bin/env python3
"""Verify save/cart input through the actual shared touch dispatcher."""
import hashlib, pathlib, subprocess, tempfile, sys
root=pathlib.Path(__file__).resolve().parents[2]
# Use the builder's current source list and configuration-dependent cache keys.
# Old build configurations can coexist in the object cache.
sys.path.insert(0, str(root/'mac'))
build={'__file__':str(root/'mac/build.py')}
exec((root/'mac/build.py').read_text().split('outputs=[]; failed=0')[0], build)
def object_for_source(source):
    key=str(source.relative_to(root))
    # MacOS keys all configurations; the older iPhone builder keys special builds.
    if 'DEBUG_BUILD' in build or build['STORE'] or build['ARCH'] or build['os'].environ.get('PEON_UI_AUDIT')=='1':
        key+=repr(build['common'])
    return build['OBJ']/(hashlib.sha1(key.encode()).hexdigest()+'.o')
objects=[object_for_source(source) for source in build['sources'] if source != root/'mac/Main.m']
if not all(path.exists() for path in objects):
    raise SystemExit('Run python3 mac/build.py with the same environment first')
with tempfile.TemporaryDirectory(prefix='peon-save-input-') as directory:
    binary=pathlib.Path(directory)/'check-save-input'
    command=['xcrun','clang','-Wno-deprecated-declarations','-DPROJECTPEON_MAC=1','-DCC_DIRECTOR_MAC_THREAD=2','-fno-objc-arc','-fblocks']
    for path in ['mac','mac/compat','rover','rover/cocos2d','rover/cocos2d/Support','rover/PRKit','rover/Tutorial','rover/libs/kazmath/include']:
        command+=['-I',str(root/path)]
    command+=['-include',str(root/'mac/Prefix.pch'),str(root/'mac/tests/save_menu_input.m'),*[str(p) for p in objects],'-lc++','-lz','-o',str(binary)]
    for framework in ['Cocoa','OpenGL','QuartzCore','CoreVideo','CoreData','AVFoundation','VideoToolbox','CoreMedia','AudioToolbox','CoreGraphics','StoreKit','SystemConfiguration','Security']:
        command+=['-framework',framework]
    subprocess.run(command,check=True)
    subprocess.run([str(binary),str(root/'build/mac/Project Peon.app/Contents/Resources')],check=True)
