#!/usr/bin/env python3
"""Check repeated lifecycle pauses, failed resume retries, and explicit stops."""
import pathlib
import subprocess
import tempfile

root = pathlib.Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix="peon-audio-resume-") as directory:
    binary = pathlib.Path(directory) / "audio-resume"
    subprocess.run([
        "xcrun", "clang", "-fno-objc-arc", "-fblocks",
        "-Wno-atomic-property-with-user-defined-accessor",
        "-I", str(root / "mac"), str(root / "mac/Audio.m"),
        str(root / "mac/tests/audio_resume.m"),
        "-framework", "Foundation", "-framework", "AVFoundation",
        "-o", str(binary),
    ], check=True)
    subprocess.run([str(binary)], check=True)
