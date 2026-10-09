#!/usr/bin/env python3
import pathlib, subprocess, tempfile
root=pathlib.Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory() as directory:
    binary=pathlib.Path(directory)/'recorder-test'
    cmd=['xcrun','clang','-fno-objc-arc','-fblocks','-Wno-deprecated-declarations','-I',str(root/'mac'),str(root/'mac/tests/recorder.m'),str(root/'mac/PeonRecorder.m')]
    for framework in ['Cocoa','AVFoundation','VideoToolbox','CoreMedia','CoreVideo','OpenGL','QuartzCore']: cmd+=['-framework',framework]
    subprocess.run(cmd+['-o',str(binary)],check=True)
    subprocess.run([str(binary)],check=True)
