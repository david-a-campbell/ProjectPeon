#!/usr/bin/env python3
"""Verify immediate native window expansion and exact restoration without showing a window."""
import pathlib, subprocess, tempfile
root=pathlib.Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory() as directory:
    binary=pathlib.Path(directory)/'wide-window-test'
    subprocess.run(['xcrun','clang','-fno-objc-arc','-fblocks','-Wno-objc-method-access','-I',str(root/'mac'),str(root/'mac/tests/wide_window.m'),str(root/'mac/PeonWideScreen.m'),'-framework','Cocoa','-framework','QuartzCore','-o',str(binary)],check=True)
    subprocess.run([str(binary)],check=True)
