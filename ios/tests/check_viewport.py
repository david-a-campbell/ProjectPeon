#!/usr/bin/env python3
"""Exercise 16:9 viewport geometry, including both Duo displays."""
import pathlib
import subprocess
import tempfile
root = pathlib.Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix="peon-ios-viewport-") as temporary:
    binary = pathlib.Path(temporary) / "viewport"
    subprocess.run(["xcrun", "clang", str(root / "ios/tests/viewport.c"),
                    "-I", str(root / "mac"), "-framework", "CoreGraphics",
                    "-o", str(binary)], check=True)
    subprocess.run([str(binary)], check=True)
