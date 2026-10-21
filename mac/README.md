# Project Peon for macOS

Native AppKit port of the original cocos2d/Box2D iPad game, targeting Apple silicon Macs running macOS 12 or later.

## Build

Open `rover.xcodeproj`, select the **Project Peon macOS** scheme and **My Mac**, then press Run (Command-R). The shared scheme uses the existing Mac build script, enables development features in Debug, and builds the standard release app in Release. It targets Apple silicon and requires no signing team for local development.

Install Xcode and its command-line tools, then run from the repository root:

```sh
python3 mac/build.py
```

The standalone app is generated at `build/mac/Project Peon.app`. The build signs it locally; distribution to other Macs may require a one-time approval in Privacy & Security. Developer ID signing and notarization are needed for normal verified distribution.

## Controls

- Move the mouse or use WASD/arrow keys for level-select parallax.
- Click and drag to build a cart.
- With the Move tool, hold Shift at any point during a drag to rotate left/right; release Shift to resume moving without a jump.
- A/D or left/right arrows drive; Space boosts.
- R relaunches the rover during gameplay.
- C returns to cart creation during gameplay.
- M cycles the current scene's music playlist.
- Command-Q quits.

The blueprint panel saves carts using the cart-plus button. Select a saved thumbnail and its green check mark to load it.

All motor/booster purchases are included by default. The eight original music tracks play in the title and level-select menus; the nine new tracks play only in levels. Sound effects retain their original assets.

Saves and progress are stored in `~/Library/Application Support/Project Peon/CartSave.sqlite`. The window stays 16:9. The home screen fills the window with an expanded background. Popup menus fill the window with a continuous hexagon backdrop while their panels retain the original centered layout. Planet selection also fills the 16:9 window with extended parallax backgrounds and corner navigation. Cart building and driving both use the full 16:9 view, with the original construction camera position preserved. Results retain the wide view. Fullscreen preserves proportions, and input matches the viewport.

## Checks

Build first, then run:

```sh
python3 mac/tests/check_restart.py
python3 mac/tests/check_saves.py
python3 mac/tests/check_music.py
python3 mac/tests/check_pivot_compression.py
python3 mac/tests/check_round_friction.py
python3 mac/tests/check_viewport.py
python3 mac/tests/check_previews.py
python3 mac/tests/check_ship.py
python3 mac/tests/check_teleport.py
python3 mac/tests/check_rotation.py
python3 mac/tests/check_boundaries.py
python3 mac/tests/check_right_boundaries.py
python3 mac/tests/check_starting_ground.py
python3 mac/tests/check_terrain.py
python3 mac/tests/check_shaders.py
```

Checks cover save persistence across processes, music cycling and playlist separation, fullscreen/Retina coordinates, previews and popups, parallax and keyboard action guards, ground pixels, and bundled shaders.

Enable Gameplay recording below effect volume in Settings to record automatically at 1024×768, up to 60 fps, with background video encoding. At the results screen, the camera button exports the MP4 to your Desktop. Restart, next level, level select, building, or quitting discards the unexported recording. Videos have no sound.

Capture uses two GPU transfer buffers, polls completion without waiting, and enables hardware H.264 encoding where available. Both GPU transfer and encoder queues remain bounded.

Use Debug → Show FPS in the Mac menu bar to show or hide the FPS monitor. The preference is remembered between launches.

Escape dismisses the topmost open menu, including tooltips and the load/save cart menu. An active cart save finishes before the menu can close.

Gameplay recording is off by default and the export button is hidden while disabled. The recording preference is remembered.

In a development build, Debug → Start Screen Recording (Command-Option-R) records the game window from any screen. The item changes to Stop Screen Recording while active; stopping saves a silent MP4 to the Desktop. This recording continues across menus, restarts and level changes independently of the gameplay-recording setting. Hiding the Debug menu also stops and saves it.

Use Debug → Show Box2D Objects to overlay physics bodies and joints in cart creation and gameplay. It is off by default and remembered between launches.

Debug → Disable Ship Finish Trigger keeps driving active when the cart reaches the ship. Uncheck it to restore normal completion; it is off by default and remembered between launches.

Debug → Enable Cart Teleport (T) enables pressing T during driving to move the connected cart assembly to the center of the current view. Use Mouse Pan Map to choose a destination. Teleporting stops its movement and preserves its joints; detached parts remain where they are. The toggle is off by default and remembered between launches.

The left map boundary is offset for the wider cart workspace. Before every launch, it moves farther left if needed to leave 64 world pixels of clearance from all solid starting-cart fixtures. This prevents oversized wheels from overlapping the wall and receiving a forward impulse. It returns to the normal wide position for smaller carts; other map boundaries are unchanged.

The Mac app icon is generated from the original `rover/Icon512.png` and `rover/Icon1024.png` artwork by `mac/build_icon.py` during each build.

P toggles Mouse Pan Map when no popup, tooltip, load/save cart panel or level-entry screen is open. While those overlays are open, the pan-map state stays unchanged. Mouse Pan Map in cart creation opens a paused map preview at the driving zoom, with the cart and building controls hidden. Drag to pan; turn the toggle off, press C, or press Escape to restore the editor camera and cart. During driving, the toggle continues to pan the live driving camera.

The standard build is a release build: Debug is omitted, its credits tap target is omitted, and saved debug options are cleared at startup. Use `PEON_DEBUG=1 python3 mac/build.py` for a development build with Debug support. `PEON_RELEASE=1` and App Store builds always disable Debug, even if development or audit flags are also set. In development builds, click David Campbell ten times to show Debug; ten more clicks clear its options and hide it.

C and R also work from level results. Both clear the results card and cancel pending results animations. C restores the original editor camera at full scale; R restores the launch camera at driving scale and resets the ship completion state.
