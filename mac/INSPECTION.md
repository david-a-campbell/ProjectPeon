# Camera inspection

While a level is open, choose **Camera → Inspect Level** (Command-Option-I).

- WASD or arrow keys: pan the camera.
- + / −: zoom in or out.
- P, or Camera → Save Screenshot to Desktop: save the next rendered frame as a PNG.
- Escape: leave inspection and restore the original camera and window format.

Inspection pauses gameplay and timers. It does not start gameplay recording. Camera bounds follow the map's gameplay boundaries. The main game shortcuts return when inspection ends.

For automated first-level camera screenshots after building, run `python3 mac/tests/inspect_level.py`. The utility uses a temporary app bundle, an in-memory save store and an offscreen renderer; it follows the actual first-level TMX mapping and captures nine positions at four zooms. Images are written to `../outputs/level-one-inspection`. It checks that inspection exits and restores the original window format.
