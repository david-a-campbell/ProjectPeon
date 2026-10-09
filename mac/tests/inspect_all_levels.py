#!/usr/bin/env python3
"""Run the offscreen background audit across all 36 playable levels."""
import json
import os
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parents[2]
logs = root.parent / 'work/all-level-audit'
logs.mkdir(parents=True, exist_ok=True)
results = []
for planet in range(1, 4):
    for level in range(1, 13):
        env = dict(os.environ, PEON_INSPECT_PLANET=str(planet), PEON_INSPECT_LEVEL=str(level))
        path = logs / f'planet-{planet}-level-{level:02d}.log'
        with path.open('w') as output:
            result = subprocess.run([sys.executable, str(root / 'mac/tests/inspect_level.py')], cwd=root, env=env, stdout=output, stderr=subprocess.STDOUT)
        passed = result.returncode == 0
        results.append(dict(planet=planet, level=level, passed=passed))
        (logs / 'results.json').write_text(json.dumps(results, indent=2))
        print(f'Planet {planet}, level {level:02d}: {"PASS" if passed else "FAIL"}', flush=True)
sys.exit(0 if all(item['passed'] for item in results) else 1)
