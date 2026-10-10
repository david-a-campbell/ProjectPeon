#!/usr/bin/env python3
"""Build iOS from a temporary project to avoid Documents file-coordination stalls."""
import argparse
import pathlib
import shutil
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument("mode", choices=["simulator", "device", "archive"], nargs="?", default="simulator")
args = parser.parse_args()
repo = pathlib.Path(__file__).resolve().parents[1]
output = repo / "build" / "ios"
output.mkdir(parents=True, exist_ok=True)
with tempfile.TemporaryDirectory(prefix="peon-ios-project-") as staging:
    staging = pathlib.Path(staging)
    project = staging / "rover.xcodeproj"
    project.mkdir()
    shutil.copy2(repo / "rover.xcodeproj/project.pbxproj", project)
    shutil.copytree(repo / "rover.xcodeproj/xcshareddata", project / "xcshareddata")
    for name in ["rover", "ios", "mac", "Default-Landscape@2x~ipad.png"]:
        (staging / name).symlink_to(repo / name)
    command = ["xcodebuild", "-project", str(project), "-scheme", "ProjectPeon",
               "-configuration", "Debug" if args.mode == "simulator" else "Release",
               "-derivedDataPath", str(output / args.mode)]
    if args.mode == "simulator":
        command += ["-sdk", "iphonesimulator", "CODE_SIGNING_ALLOWED=NO", "build"]
    elif args.mode == "device":
        command += ["-sdk", "iphoneos", "-destination", "generic/platform=iOS",
                    "CODE_SIGNING_ALLOWED=NO", "build"]
    else:
        command += ["-destination", "generic/platform=iOS", "-archivePath",
                    str(output / "ProjectPeon.xcarchive"), "-allowProvisioningUpdates", "archive"]
    subprocess.run(command, cwd=repo, check=True)
