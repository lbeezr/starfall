# Playful Tumble app icon adoption

October 17, 2026. User selected the rightmost falling Spark option and authorized adoption and integration. Installed asset is a standalone generated refinement of that selection, preserving the tilted aqua four-point star, happy face, lavender curved trail, ivory glint and cloud crescent. It is not a pixel-identical crop of the three-panel sheet. Original source is retained in `Artwork/AppIcon/playful-tumble-source.png`; deterministic normalization is owned by `scripts/export-app-icon.swift` through `scripts/generate-app-icon.sh`.

Acceptance: app catalog uses the selected falling-star direction; opaque 1024-square unmasked PNG; existing app identity/catalog entry unchanged; Debug/Release compile; masked Home Screen appearance inspected. No cover/menu implementation, rules, saves, settings or scene changes are part of this batch. No new app dependencies, SDKs or entitlements.

## Source and commands

Validation ran in `/tmp/starfall-icon-acceptance`, an export of commit `d1d46b9a32f57e2a420249d1e9416eecffc2badf` with only the new `App/Assets.xcassets/AppIcon.appiconset/Starfall-1024.png` overlaid. This excludes unrelated dirty/staged project, mechanics and documentation work. `source-manifest.json` records asset/export hashes and working-tree status. Source/export documentation has no app target membership; catalog membership and Contents.json already existed and are unchanged.

- `bash scripts/generate-app-icon.sh`: passed. Native system ImageIO/CoreGraphics export; `sips` confirms 1024 × 1024, no alpha.
- `swift test` in exported source: 61 tests, zero failures.
- Xcode 27.1 (27A9275), iPhone 17e simulator `4103C352-DFC2-493E-A224-DE4CE3D50889`, iOS 27.0, arm64.
- `xcodebuild -project Starfall.xcodeproj -scheme Starfall -configuration Debug -sdk iphonesimulator -destination 'platform=iOS Simulator,id=4103C352-DFC2-493E-A224-DE4CE3D50889' -derivedDataPath /tmp/starfall-icon-derived ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO build`: passed, including asset compilation.
- Same build with `-configuration Release`: passed.
- Initial Debug attempt without explicit architecture selected an x86_64 app against an arm64 package module and failed resolving StarfallCore. Explicit arm64 retry above passed; no project settings changed to conceal this environment issue.
- `xcrun simctl install` installed exported Debug app. Home button through XcodeBuildMCP, then `xcrun simctl io ... screenshot`: captured `home-screen.png`. Visually inspected the actual masked Starfall icon: complete star, face, trail and clouds visible without corner clipping. Nearby Supernova Lab retains the old icon and is a separate existing app, not part of this change.
- `python3 scripts/ci-hygiene.py` and `git diff --check`: passed.

Raw build/core logs are local ignored `artifacts/playful-tumble-icon/`. Small durable native evidence is here. Native interaction/hosted tests were not rerun for this image-only change. Gameplay, rapid taps, restart, win/loss, background/resume, settings, actual VoiceOver, Reduce Motion and animations are unaffected boundaries, not newly verified here. Physical device, alternate dark/tinted icon treatments and App Store acceptance are unverified. Follow up on those during release validation; avoid claiming that default simulator appearance covers every system treatment.
