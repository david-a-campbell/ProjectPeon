#!/usr/bin/env python3
"""Check the starting floor's outline against its support block in every map."""
import pathlib, subprocess, tempfile
root=pathlib.Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix='peon-starting-ground-') as directory:
    binary=pathlib.Path(directory)/'check-starting-ground'
    subprocess.run(['xcrun','clang++','-std=c++11','-fno-objc-arc','-I',str(root/'mac'),str(root/'mac/tests/starting_ground.mm'),'-framework','Foundation','-framework','CoreGraphics','-o',str(binary)],check=True)
    subprocess.run([str(binary),str(root/'rover')],check=True)
