# Repository scripts

Hygiene checks, native CI validation and app-icon export tooling.

## Start here

Run `python3 scripts/ci-hygiene.py` and `git diff --check` from the root. See [app icon export](README-app-icon.md) before regenerating branding; inspect `ci-simulator.sh` for its native environment requirements. The former icon SVG is historical.


## One-app iPhone updates

`device-update.py` is a local macOS service, not an iPhone network feature. It fetches public GitHub main, requires successful exact-source CI, signs with local Xcode, and updates regular Starfall in place. It never installs lab identities or launches/reset the game. See [build/testing policy](../docs/DEVELOPMENT_BUILDS.md). The Mac must be awake, logged in, with Xcode signing and a trusted connected iPhone.

```sh
python3 scripts/device-update.py configure --device <iPhone-UDID> --team <development-team>
python3 scripts/device-update.py run
python3 scripts/device-update.py status
python3 scripts/device-update.py enable
python3 scripts/device-update.py disable
python3 scripts/test_device_update.py
```

Enable copies the updater and fingerprint helper to `~/Library/Application Support/Starfall Device Updates/` and registers `~/Library/LaunchAgents/com.starfall.device-updates.plist` with a two-minute interval. Disable unloads/removes that agent and retains installed apps, config, backups and diagnostic state. Re-enable from updated repository scripts when updating the service itself. Configuration contains device/team identifiers, not account credentials. Build logs are replaced per build; recurring logs are trimmed at 2 MB. `installed.json` records the actual installed source/build, while `status.json` explains waiting/errors. Run the behavior checks without a phone or network.
