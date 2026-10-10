#!/usr/bin/env python3
"""Build a universal Mac App Store app and sign its installer when requested."""
import argparse
import os
import pathlib
import plistlib
import shutil
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--profile', type=pathlib.Path, help='Mac App Store provisioning profile')
parser.add_argument('--app-identity', help='Apple Distribution signing identity')
parser.add_argument('--installer-identity', help='3rd Party Mac Developer Installer identity')
args = parser.parse_args()
signing = (args.profile, args.app_identity, args.installer_identity)
if any(signing) and not all(signing):
    parser.error('Provide all three signing arguments, or none for local validation.')

out = ROOT / 'build/app-store'
for arch in ('arm64', 'x86_64'):
    env = dict(os.environ, PEON_APP_STORE='1', PEON_ARCH=arch,
               PEON_BUILD_DIR=str(out / arch))
    subprocess.run([sys.executable, str(ROOT / 'mac/build.py')], env=env, check=True)

app = out / 'universal/Project Peon.app'
if app.exists():
    shutil.rmtree(app)
shutil.copytree(out / 'arm64/Project Peon.app', app, copy_function=shutil.copyfile)
for executable in (app / 'Contents/MacOS').iterdir():
    executable.chmod(0o755)
binary = app / 'Contents/MacOS/ProjectPeon'
subprocess.run(['xcrun', 'lipo', '-create',
                *[str(out / arch / 'Project Peon.app/Contents/MacOS/ProjectPeon')
                  for arch in ('arm64', 'x86_64')], '-output', str(binary)], check=True)
subprocess.run(['xcrun', 'dsymutil', str(binary), '-o', str(out / 'Project Peon.app.dSYM')], check=True)
entitlements = plistlib.loads((ROOT / 'mac/AppStore/ProjectPeon.entitlements').read_bytes())
identity = '-'
if all(signing):
    profile_path = args.profile.expanduser().resolve()
    profile = plistlib.loads(subprocess.check_output(['security', 'cms', '-D', '-i', str(profile_path)]))
    authorized = profile['Entitlements']
    app_id = authorized.get('com.apple.application-identifier', '')
    if not app_id.endswith('.com.digitalfury.rover') or authorized.get('get-task-allow'):
        raise SystemExit('Expected a distribution profile for com.digitalfury.rover.')
    for key in ('com.apple.application-identifier', 'com.apple.developer.team-identifier', 'keychain-access-groups'):
        if key in authorized:
            entitlements[key] = authorized[key]
    shutil.copyfile(profile_path, app / 'Contents/embedded.provisionprofile')
    identity = args.app_identity
entitlements_path = out / 'release.entitlements'
entitlements_path.write_bytes(plistlib.dumps(entitlements))
subprocess.run(['xattr', '-cr', str(app)], check=True)
subprocess.run(['codesign', '--force', '--sign', identity, '--entitlements',
                str(entitlements_path), str(app)], check=True)
# Finder/iCloud can attach metadata while a keychain permission dialog is open.
subprocess.run(['xattr', '-cr', str(app)], check=True)
subprocess.run(['codesign', '--verify', '--strict', '--deep', str(app)], check=True)
subprocess.run(['xcrun', 'lipo', str(binary), '-verify_arch', 'arm64', 'x86_64'], check=True)
if all(signing):
    package = out / 'Project Peon.pkg'
    subprocess.run(['productbuild', '--component', str(app), '/Applications',
                    '--sign', args.installer_identity, str(package)], check=True)
    subprocess.run(['pkgutil', '--check-signature', str(package)], check=True)
    print(f'Ready for App Store validation and upload: {package}')
else:
    print(f'Universal sandbox validation build (not uploadable): {app}')
