#!/usr/bin/env python3
"""Build iOS from a temporary project to avoid Documents file-coordination stalls."""
import argparse
import pathlib
import shutil
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument("mode", choices=["simulator", "device", "development", "archive"], nargs="?", default="simulator")
parser.add_argument("--device-id", help="Connected iPhone identifier for a signed development build")
args = parser.parse_args()
repo = pathlib.Path(__file__).resolve().parents[1]
output = repo / "build" / "ios"
output.mkdir(parents=True, exist_ok=True)
# Sign development products outside iCloud/File Provider to avoid Finder metadata.
derived = pathlib.Path("/private/tmp/projectpeon-ios-" + args.mode) if args.mode in ("development", "archive") else output / args.mode
archive = pathlib.Path("/private/tmp/projectpeon-ios-release/ProjectPeon.xcarchive")
with tempfile.TemporaryDirectory(prefix="peon-ios-project-") as staging:
    staging = pathlib.Path(staging)
    project = staging / "rover.xcodeproj"
    project.mkdir()
    shutil.copy2(repo / "rover.xcodeproj/project.pbxproj", project)
    shutil.copytree(repo / "rover.xcodeproj/xcshareddata", project / "xcshareddata")
    for name in ["rover", "ios", "mac", "Default-Landscape@2x~ipad.png"]:
        (staging / name).symlink_to(repo / name)
    command = ["xcodebuild", "-project", str(project), "-scheme", "ProjectPeon",
               "-configuration", "Debug" if args.mode in ("simulator", "development") else "Release",
               "-derivedDataPath", str(derived)]
    if args.mode == "simulator":
        command += ["-sdk", "iphonesimulator", "CODE_SIGNING_ALLOWED=NO", "build"]
    elif args.mode == "device":
        command += ["-sdk", "iphoneos", "-destination", "generic/platform=iOS",
                    "CODE_SIGNING_ALLOWED=NO", "build"]
    elif args.mode == "development":
        destination = "id=" + args.device_id if args.device_id else "generic/platform=iOS"
        command += ["-sdk", "iphoneos", "-destination", destination,
                    "-allowProvisioningUpdates", "-allowProvisioningDeviceRegistration", "build"]
    else:
        command += ["-destination", "generic/platform=iOS", "-archivePath",
                    str(archive), "-allowProvisioningUpdates", "archive"]
    subprocess.run(command, cwd=repo, check=True)

print("Build products:", derived / "Build/Products")
if args.mode == "archive":
    print("Signed archive:", archive)
