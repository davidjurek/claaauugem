# Building Static Falls for iPhone

The game runs on a real iPhone via Godot's iOS export + Xcode signing.

## One-command rebuild + install

With the iPhone **plugged in / paired, Developer Mode ON, and unlocked**:

```bash
bash tools/ios_deploy.sh
```

This exports the Xcode project, builds + signs it, installs it, and launches it.

## What's set up

- **Godot iOS export preset** (`export_presets.cfg`, preset "iOS"):
  - Bundle ID: `com.davidyko.psychosuburbia`
  - Team: `8WW85L69P3` (the Apple ID team that's signed into Xcode)
  - Targeted device family: iPhone & iPad (universal)
  - `export_project_only=true` — Godot emits an Xcode project; `xcodebuild` signs it.
- **App icon**: `art/ui/appicon/icon_1024.png` (flat placeholder logo — swap anytime).
- Signing is **automatic** (`-allowProvisioningUpdates`); Xcode generates the
  development provisioning profile for the bundle ID on first build.

## Gotchas we already hit (so you don't have to)

1. **iOS requires ETC2/ASTC texture compression.** Project Setting
   `rendering/textures/vram_compression/import_etc2_astc=true` must be ON, or
   Godot's iOS export fails (with an unhelpful blank error on the command line).
   Already enabled in `project.godot`.
2. **`targeted_device_family`** in Godot: `0`=iPhone, `1`=iPad, `2`=both. Use `2`.
3. **Team**: the signing cert in the keychain was team `QJ9DF2NT26`, but the
   account actually signed into Xcode is `8WW85L69P3`. Builds must use the team
   that's signed into Xcode (Xcode → Settings → Accounts).
4. Free/personal signing certs expire after 7 days — just re-run the script to
   re-sign.

## Device

- Default device: **Seaweed** (iPhone 15 Pro), id `00008130-000634362491401C`.
- Override with env vars: `IOS_DEVICE_ID=... IOS_TEAM=... bash tools/ios_deploy.sh`
- List devices: `xcrun xctrace list devices`
