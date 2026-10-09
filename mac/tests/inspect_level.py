#!/usr/bin/env python3
"""Verify saved cart preview sizes at standard and Retina resolutions."""
import hashlib, pathlib, subprocess, tempfile, plistlib, os, xml.etree.ElementTree as ET
root=pathlib.Path(__file__).resolve().parents[2]
objects=root/'build/mac/objects'
main=hashlib.sha1(b'mac/Main.m').hexdigest()+'.o'
with tempfile.TemporaryDirectory(prefix='peon-previews-') as directory:
    contents=pathlib.Path(directory)/'Inspection.app/Contents'
    (contents/'MacOS').mkdir(parents=True)
    (contents/'Resources').symlink_to(root/'build/mac/Project Peon.app/Contents/Resources')
    (contents/'Info.plist').write_bytes(plistlib.dumps({'CFBundleExecutable':'Inspection','CFBundleIdentifier':'local.peon.inspection','CFBundlePackageType':'APPL'}))
    binary=contents/'MacOS/Inspection'
    command=['xcrun','clang','-Wno-deprecated-declarations','-DPROJECTPEON_MAC=1','-DCC_DIRECTOR_MAC_THREAD=2','-fno-objc-arc','-fblocks']
    for path in ['mac','mac/compat','rover','rover/cocos2d','rover/cocos2d/Support','rover/PRKit','rover/Tutorial','rover/libs/kazmath/include']:
        command+=['-I',str(root/path)]
    command+=['-include',str(root/'mac/Prefix.pch'),str(root/'mac/tests/inspect_level.m'),*[str(p) for p in objects.glob('*.o') if p.name!=main and len(p.stem)==40],'-lc++','-lz','-o',str(binary)]
    for framework in ['Cocoa','OpenGL','QuartzCore','CoreVideo','CoreData','AVFoundation','VideoToolbox','CoreMedia','AudioToolbox','CoreGraphics','StoreKit','SystemConfiguration','Security']:
        command+=['-framework',framework]
    # Follow the actual playable-level mapping rather than the TMX filename numbering.
    mappings=plistlib.loads((root/'rover/tmxMappings.plist').read_bytes())
    requested_level=int(os.environ.get('PEON_INSPECT_LEVEL','1'))
    planet,level=map(int,mappings[f'planet1Level{requested_level}'].split())
    tree=ET.parse(root/f'rover/Planet{planet}/planet{planet}Level{level}.tmx').getroot()
    height=int(tree.get('height'))*int(tree.get('tileheight'))
    width=int(tree.get('width'))*int(tree.get('tilewidth'))
    segments=[]
    for obj in tree.findall('.//object'):
        polygon=obj.find('polygon')
        if polygon is None or obj.get('type')!='TexturedGround': continue
        ox=float(obj.get('x','0')); oy=height-float(obj.get('y','0'))
        points=[(ox+float(x),oy-float(y)) for x,y in (pair.split(',') for pair in polygon.get('points').split())]
        segments.extend(zip(points,points[1:]+points[:1]))
    poses=[]
    for x in [1000]+list(range(8000,width-1000,8000))+[width-2000]:
        ys=[a[1]+(x-a[0])/(b[0]-a[0])*(b[1]-a[1]) for a,b in segments if min(a[0],b[0])<=x<=max(a[0],b[0]) and a[0]!=b[0]]
        y=max(ys)+300 if ys else 3000
        for zoom in [.2,.35,.5,1]: poses.append(f'x{x:05d}-zoom{zoom},{x},{y},{zoom}')
        if x==1000: poses.append(f'start-above,{x},{y+3000},0.35')
    pose_file=pathlib.Path(directory)/'poses.csv'; pose_file.write_text('\n'.join(poses))
    output=root.parent/('outputs/level-one-inspection' if requested_level==1 else f'outputs/level-{requested_level}-inspection')
    output.mkdir(parents=True,exist_ok=True)
    subprocess.run(command,check=True)
    subprocess.run([str(binary),str(root/'build/mac/Project Peon.app/Contents/Resources'),str(output),str(pose_file),str(requested_level)],check=True)
