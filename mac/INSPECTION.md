# Camera inspection

While a level is open, choose **Camera → Inspect Level** (Command-Option-I).

- WASD or arrow keys: pan the camera.
- + / −: zoom in or out.
- P, or Camera → Save Screenshot to Desktop: save the next rendered frame as a PNG.
- Escape: leave inspection and restore the original camera and window format.

Inspection pauses gameplay and timers. It does not start gameplay recording. Camera bounds follow the map's gameplay boundaries. The main game shortcuts return when inspection ends.

For automated camera screenshots after building, run `python3 mac/tests/inspect_level.py`. Set `PEON_INSPECT_PLANET` (1 Earth, 2 Moon, 3 Mars) and `PEON_INSPECT_LEVEL` (1–12) to choose a playable level. The utility follows the actual TMX mapping and uses a temporary app bundle, an in-memory save store, and an offscreen renderer.

Each level produces 45 screenshots: nine map positions at four zooms, the actual cart and escape-pod positions at four zooms, and a view above the start. Images are written to `../outputs/all-level-inspection/planet-N-level-LL`. Coverage assertions check parallax edges and existing regressions. These are camera/rendering checks, not a complete physics playthrough.

Run `python3 mac/tests/inspect_all_levels.py` to inspect all 36 levels and save individual logs and a result summary in `../work/all-level-audit`.
