# Project Peon for iPhone and iPad

Branch: `iphone-release`. Open `rover.xcodeproj` and select the shared
`ProjectPeon` scheme. Requires Xcode 26 or newer. The app targets iOS 15+,
supports both landscape orientations, and retains `com.digitalfury.rover`
for the existing App Store listing. Version 2.0.2, build 213.

The centered 16:9 game canvas is fitted inside the screen's safe area.
The original cart and level dimensions are preserved, with the wider viewport
showing more of the map and spreading the toolbar and HUD to its edges. New installs use
touch driving controls. Retina assets are always enabled. The app icon reuses
the existing `rover/Icon1024.png` artwork.

## Build

From the repository root:

```sh
python3 ios/build.py simulator
python3 ios/build.py device
python3 ios/build.py development --device-id YOUR_CONNECTED_DEVICE_ID
python3 ios/build.py archive
```

The first two commands create unsigned simulator/device builds. The development
command signs a Debug build for a connected iPhone with automatic provisioning.
Development products are staged at `/private/tmp/projectpeon-ios-development`
to keep iCloud metadata out of the signing process.
The archive command also stages signing outside Documents, at
`/private/tmp/projectpeon-ios-release/ProjectPeon.xcarchive`. It uses automatic signing for team `K8BH4PM89R` and needs a signed-in
Xcode account, active developer membership, and valid provisioning. Products
are in ignored `build/ios/`. The helper stages the project outside Documents
to avoid an Xcode file-coordination stall; source and resources stay in this repo.

Install the simulator build on a booted simulator:

```sh
xcrun simctl install booted build/ios/simulator/Build/Products/Debug-iphonesimulator/rover.app
xcrun simctl launch booted com.digitalfury.rover
```

## Compatibility fixes

- Shader extension directives are emitted before injected GLSL declarations.
- iOS uses the shared AVFoundation audio adapter instead of legacy OpenAL,
  which aborted during simulator startup. Music/effects, volume controls,
  interruptions, and background pause/resume retain their existing behavior.
- Maps now load on both iPhone and iPad; the old device check skipped iPhone.
- The modern icon catalog, launch configuration, privacy manifest, and shared
  scheme replace obsolete release settings and expired provisioning entries.

## Before submission

Simulator checks and an unsigned Release build do not replace physical-device
testing. Test cart creation, saving/loading, driving, audio interruptions,
rotation, and audio on an actual iPhone and iPad. All upgrades are included;
there are no purchases in version 2.0. Validate a signed archive
in Xcode Organizer, complete current App Store metadata/screenshots and privacy
answers, and test through TestFlight before submitting for review.

The privacy manifest declares no tracking or collected data. It declares
UserDefaults reason `CA92.1` for local settings within the app. Re-audit it if services or SDKs are added. Signing/upload remain dependent
on the renewed Apple Developer membership and local signing credentials.

The shared 16:9 UI includes mirrored menu close buttons, inset bitmap fonts,
updated credits and volume captions, and centered cart thumbnails. Touch driving,
tilt driving, and two-finger part rotation remain iOS controls.
