#!/usr/bin/env python3
"""Build the original game and bundled engines as a standalone macOS app."""
import concurrent.futures, hashlib, json, os, pathlib, plistlib, shutil, subprocess, sys, tempfile
ROOT = pathlib.Path(__file__).resolve().parents[1]
OUT = pathlib.Path(os.environ.get('PEON_BUILD_DIR', ROOT / 'build/mac'))
OBJ = OUT / 'objects'
OBJ.mkdir(parents=True, exist_ok=True)
p = json.loads(subprocess.check_output(['plutil','-convert','json','-o','-',str(ROOT/'rover.xcodeproj/project.pbxproj')]))
objects = p['objects']; paths = {}
def walk(key, parent):
    obj = objects[key]; path = obj.get('path','')
    base = ROOT if obj.get('sourceTree') == 'SOURCE_ROOT' else parent
    current = base / path
    paths[key] = current
    for child in obj.get('children',[]): walk(child,current)
walk(objects[p['rootObject']]['mainGroup'], ROOT)
excluded = {'main.m','AppDelegate.mm','GameNavControllerViewController.m','UIDevice-Hardware.m'}
sources=[]; resources=[]
for obj in objects.values():
    if obj['isa'] not in ('PBXSourcesBuildPhase','PBXResourcesBuildPhase'): continue
    for entry in obj['files']:
        source = paths[objects[entry]['fileRef']]
        if source.suffix == '.xcdatamodeld': resources.append(source); continue
        if obj['isa'] == 'PBXResourcesBuildPhase': resources.append(source); continue
        relative = str(source.relative_to(ROOT))
        if source.name in excluded or '/FontLabel/' in relative or '/CocosDenshion/' in relative: continue
        if '/Platforms/iOS/' in relative and source.name not in ('CCTouchDispatcher.m','CCTouchHandler.m'): continue
        if '/glu/' in relative: continue # macOS supplies GLU.
        if source.suffix in ('.m','.mm','.c','.cpp'): sources.append(source)
sources += list((ROOT/'mac').glob('*.m'))
sdk = subprocess.check_output(['xcrun','--sdk','macosx','--show-sdk-path'],text=True).strip()
include_dirs=[ROOT/'mac',ROOT/'mac/compat',ROOT/'rover',ROOT/'rover/libs',ROOT/'rover/libs/kazmath/include',ROOT/'rover/cocos2d/Platforms/iOS']
include_dirs += sorted({f.parent for f in (ROOT/'rover').rglob('*.h') if 'boost.framework' not in str(f) and '/FontLabel/' not in str(f) and '/CocosDenshion/' not in str(f) and '/Platforms/iOS' not in str(f)})
common=['-isysroot',sdk,'-mmacosx-version-min=12.0','-DPROJECTPEON_MAC=1','-DCC_DIRECTOR_MAC_THREAD=2','-DCOCOS2D_DEBUG=1','-Wno-deprecated-declarations','-Wno-incompatible-pointer-types','-Wno-int-conversion','-Wno-shorten-64-to-32','-Wno-pointer-to-int-cast','-Wno-nullability-completeness','-Wno-objc-method-access','-Wno-format','-O1','-g']
for d in include_dirs: common += ['-I',str(d)]
headers = list((ROOT/'rover').rglob('*.h')) + list((ROOT/'mac').rglob('*.h')) + [ROOT/'mac/Prefix.pch']
header_time = max(f.stat().st_mtime for f in headers)
def compile(source):
    output = OBJ/(hashlib.sha1(str(source.relative_to(ROOT)).encode()).hexdigest()+'.o')
    if output.exists() and output.stat().st_mtime > max(header_time,source.stat().st_mtime): return output, ''
    command = ['xcrun','clang++' if source.suffix in ('.mm','.cpp') else 'clang', *common]
    if source.suffix in ('.m','.mm'): command += ['-fno-objc-arc','-fblocks','-include',str(ROOT/'mac/Prefix.pch')]
    if source.suffix in ('.mm','.cpp'): command += ['-std=c++11','-Wno-c++11-narrowing']
    result = subprocess.run([*command,'-c',str(source),'-o',str(output)],stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True)
    return (output if result.returncode == 0 else None), result.stdout
outputs=[]; failed=0
with concurrent.futures.ThreadPoolExecutor(max_workers=min(8,os.cpu_count() or 4)) as pool:
    for source, (output,log) in zip(sources,pool.map(compile,sources)):
        if output: outputs.append(output)
        else:
            failed+=1; print(f'FAILED: {source.relative_to(ROOT)}\n{log}',flush=True)
if failed: sys.exit(f'{failed} compilation units failed. See errors above.')
staging = tempfile.TemporaryDirectory(prefix='projectpeon-build-')
app = pathlib.Path(staging.name)/'Project Peon.app'; contents=app/'Contents'; binary=contents/'MacOS'; assets=contents/'Resources'
binary.mkdir(parents=True,exist_ok=True); assets.mkdir(parents=True,exist_ok=True)
frameworks=['Cocoa','OpenGL','QuartzCore','CoreVideo','CoreData','AVFoundation','VideoToolbox','CoreMedia','AudioToolbox','CoreGraphics','StoreKit','SystemConfiguration','Security']
command=['xcrun','clang++','-mmacosx-version-min=12.0',*[str(o) for o in outputs],'-o',str(binary/'ProjectPeon'),'-lz']
for framework in frameworks: command+=['-framework',framework]
subprocess.run(command,check=True)
for resource in resources:
    if not resource.exists(): raise SystemExit(f'Missing resource: {resource}')
    if resource.suffix=='.xcdatamodeld':
        subprocess.run(['xcrun','momc',str(resource),str(assets/(resource.stem+'.momd'))],check=True)
    elif resource.is_dir(): shutil.copytree(resource,assets/resource.name,dirs_exist_ok=True,copy_function=shutil.copyfile)
    else: shutil.copyfile(resource,assets/resource.name)
shutil.copyfile(ROOT/'mac/Assets/ProjectPeon.icns',assets/'ProjectPeon.icns')
for caption in ['CartLoad.png','CartLoadDown.png','CartDelete.png','CartDeleteDown.png','RecordGameplayLabel.png','MusicVolumeLabel.png','EffectVolumeLabel.png','titleBackdropWide.png','MenuGridWide.png','planet1MenuWide.tmx','planet2MenuWide.tmx','planet3MenuWide.tmx','loadingScreen1Wide.png','loadingScreen2Wide.png','loadingScreen3Wide.png']:
    shutil.copyfile(ROOT/'mac/Assets'/caption,assets/caption)
shutil.copyfile(ROOT/'mac/Assets/MenuClose.png',assets/'MenuClose.png')
shutil.copyfile(ROOT/'mac/Assets/MenuCloseDown.png',assets/'MenuCloseDown.png')
info={'CFBundleExecutable':'ProjectPeon','CFBundleIdentifier':'com.digitalfury.projectpeon.mac','CFBundleName':'Project Peon','CFBundleDisplayName':'Project Peon','CFBundleIconFile':'ProjectPeon.icns','CFBundlePackageType':'APPL','CFBundleVersion':'2','CFBundleShortVersionString':'2.0','LSMinimumSystemVersion':'12.0','NSHighResolutionCapable':True,'NSPrincipalClass':'NSApplication'}
with (contents/'Info.plist').open('wb') as f: plistlib.dump(info,f)
subprocess.run(['xattr','-cr',str(app)],check=True)
subprocess.run(['codesign','--force','--deep','--sign','-',str(app)],check=True)
subprocess.run(['codesign','--verify','--deep','--strict',str(app)],check=True)
final_app = OUT/'Project Peon.app'
# Rebuild the bundle cleanly so removed resources cannot survive an update.
if final_app.exists(): shutil.rmtree(final_app)
shutil.copytree(app,final_app,dirs_exist_ok=True,copy_function=shutil.copyfile)
(final_app/'Contents/MacOS/ProjectPeon').chmod(0o755)
staging.cleanup()
print(f'Built: {final_app}')
