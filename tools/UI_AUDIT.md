# Mac / iPhone UI parity audit

The canvas is 1024×768 game points with 170⅔ points added on either side:
1365⅓×768, or 16:9. Compare **rendered game points**, not screen pixels or
raw sprite sizes. iPhone textures use half-sized point rectangles on Retina;
Mac textures use pixel-sized rectangles. `CC_RECT_PIXELS_TO_POINTS` is required
when cropping source artwork. Touch/tilt instructions and Mac keyboard/recording
controls are expected differences; they are reported rather than hidden.

`rover/PeonUIAudit.h` records visible node origins and rendered axes after one
second of stable layout. The JSON goes to `tmp/PeonUIAudit.jsonl` in the iPhone
app container and `NSTemporaryDirectory()/PeonUIAudit.jsonl` on Mac. Each new
launch replaces the file. Console output lists captured screen names. Containers
with no rendered dimensions aren't compared as if they were images.

Use an isolated checkout of the published Mac branch for the reference. Do not
compare against a Mac binary built from the iPhone working tree: platform changes
can contaminate that reference. Inject only the audit hooks into the isolated
checkout, and record the reference commit with the report.

Build and run opt-in Debug audit builds:

```sh
PEON_UI_AUDIT=1 python3 mac/build.py
PEON_UI_AUDIT=1 PEON_UI_AUDIT_FIXTURES=1 'build/mac/Project Peon.app/Contents/MacOS/ProjectPeon'
python3 ios/build.py development --device-id YOUR_UDID
```

Launch the installed iPhone app with `devicectl device process launch`, using
`DEVICECTL_CHILD_PEON_UI_AUDIT=1` and `DEVICECTL_CHILD_PEON_UI_AUDIT_FIXTURES=1`
in the calling environment. Use the connected CoreDevice ID and `--console`.
The phone must be unlocked initially; the app disables auto-lock from startup
until that audit process ends. Without the fixtures flag it captures menus you
open manually. Audit instrumentation is disabled in Release builds.

The automatic walkthrough exercises eight tooltips, credits/settings/popups,
save row and expanded preview, and a results panel using identical sample content.
It never saves/deletes carts, purchases upgrades, or writes a level score.
Allow 65 seconds without interacting. Each screen has four seconds to animate
and settle. Gameplay backgrounds, full levels, and real touch/tilt interactions
still require manual inspection; this audit does not claim to verify them.

Retrieve iPhone output:

```sh
xcrun devicectl device copy from --device DEVICE_ID \
  --domain-type appDataContainer --domain-identifier com.digitalfury.rover \
  --source tmp/PeonUIAudit.jsonl --destination /tmp/iphone-ui.jsonl
python3 tools/audit_ui.py compare /tmp/mac-ui.jsonl /tmp/iphone-ui.jsonl --output /tmp/ui-report.json
python3 tools/audit_ui.py scan --output /tmp/ui-platform-gates.json
python3 -m unittest discover -s tools -p 'test_audit_ui.py'
```

The comparator fails when geometry differs by more than 0.75 game points,
when a close button isn't circular/48 points, or when screens are missing.
It reports changed/missing text and nodes as well. Differences in settings
control rows and recording buttons need human interpretation. The source scan
lists every application-level Mac guard and pixel-dependent layout expression
for review; a clean build alone does not establish visual parity.

To verify actual rendering, iPhone captures also save `<screen>.png` in the
app's temporary directory. These read the rendered framebuffer; geometry alone
can pass while OpenGL state prevents a sprite from drawing. Retrieve PNGs using
the same `devicectl device copy from` command with the corresponding filename.

Set `DEVICECTL_CHILD_PEON_UI_AUDIT_SETTINGS=1` alongside the other audit flags
to exercise the build-menu → settings → back → settings path and leave the final
settings screen open. This checks transitions as well as direct menu creation.

Set `DEVICECTL_CHILD_PEON_UI_AUDIT_WORKSHOP=1` alongside the audit/fixtures
flags to open the workshop using the real upgrade artwork and animations.
All workshop upgrades are included; no StoreKit observer, product request,
payment, or restoration is registered by this screen.
