# Mac App Store release

The store build uses `com.digitalfury.rover`, matching the existing Project Peon listing. Version 2.0, build 200 supports arm64 and x86_64, with macOS 12 as the minimum version. Original icon artwork is reused.

Local sandbox validation build:

```sh
python3 mac/AppStore/package.py
```

Signed upload package:

```sh
python3 mac/AppStore/package.py \
  --profile /absolute/path/Project_Peon_Mac_App_Store.provisionprofile \
  --app-identity 'Apple Distribution: Kiwi Pineapple LLC (K8BH4PM89R)' \
  --installer-identity '3rd Party Mac Developer Installer: Kiwi Pineapple LLC (K8BH4PM89R)'
```

The resulting `build/app-store/Project Peon.pkg` must pass Apple's validation before upload. The universal app and dSYM are also retained in `build/app-store`. Certificate private keys and provisioning profiles are kept outside the repository and must never be committed.

The sandbox stores game progress and carts in its container's Application Support directory. Video exports and debug screenshots use the system Save dialog, with user-selected file access only. The privacy manifest declares local preferences and elapsed-time APIs. The ordinary local build remains available through `mac/build.py`.

Support and privacy documents in this folder describe the native Mac release only.
