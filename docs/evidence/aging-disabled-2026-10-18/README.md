# Automatic star aging disabled

**Result:** Partially verified · **Owner:** Current implementer · **Date:** October 18, 2026

The user finds automatic growth, purple warnings and implosions too chaotic. Disable critical mass in ordinary fresh and restored survival skies. Keep matching growth, scoring, showers, timing and First Light. Historical Dusk rounds and explicit Debug fixtures retain their rules; do not introduce Dusk into migrated critical-mass skies.

## Acceptance

- Fresh survival never ages or collapses stars and generates no Dusk.
- Restored critical-mass rounds clear visual ages while preserving identities, matching growth, score, lost light, preview, RNG and cadence; migration is idempotent and valid after save/reload and replay.
- Help and controls describe the selected rules, without pressure or Dusk instructions for these skies.
- Core regressions, affected hosted checks, Debug/Release simulator builds and hygiene pass. Record native interaction, motion and accessibility limits separately.

## Verification

Core, hosted tests and simulator builds pass. Native fresh-play, rapid double-tap, win/replay/full-sky/restore, settings/background and Reduce Motion checks passed. Physical device delivery and actual VoiceOver are not claimed.

## Implementation and compatibility

Core rule marker 2 retires version 1 aging. It retains the no-Dusk RNG path and lost-starlight ledger; removing the marker outright would reintroduce Dusk and invalidate consumed-light accounting. Migration clears only stellar ages, preserving ordinary grown value, IDs and positions. The store applies it before presentation on restore and replay; fresh survival uses it directly. Version 1 remains readable and explicit Debug fixtures still reproduce historical collapses. Older envelope versions reject both no-Dusk rule versions. No new player toggle, SDK, target or resource is added.

Examined boundaries: fresh/replay/restore entry points, age-driven SpriteKit shader/size/warnings and accessibility text, help/menu rule selection, future shower generation, lost-light conservation and archive validation. First Light and historical Dusk are unchanged. Future reintroduction requires a new user decision; do not silently re-enable old ages.

## Source and checks

Source: `99803b3` plus this change's tracked diff. Source changes: `FallingSky.swift`, `CriticalMassRule.swift`, store, menu, view call site, preferences and archive; tests in existing Core and app test files. No target membership changes. Xcode 27.1, arm64 iPhone 17e simulator (`Starfall Landing Acceptance`, iOS 27.0). Working-tree acceptance, not a clean published-commit or physical-device claim.

- `swift test`: 166 tests passed, including 20-seed migration/reload/replay and subsequent shower checks. Historical rules remain tested independently.
- Debug simulator build/run and Release simulator build passed. Initial builds selected x86_64 app compilation against arm64 Core; supplying `ARCHS=arm64 ONLY_ACTIVE_ARCH=YES` resolved the build mismatch without a repository build-setting change.
- Selected `StarfallAppTests`: 80 passed (CriticalMassProductionTests, FallingSkyStoreTests, SkyFlowStateTests, SkySaveArchiveTests, and two NativeInputWindowTests). Full-motion fresh/restored shower windows passed; migrated nodes have no purple shader or critical marker; warnings are absent. An initial test retained the obsolete all-column collapse lock expectation; corrected to the fixture's arriving column 6, then rerun successfully.
- Native system Reduce Motion manual play and settings/background gesture recovery passed. Full actual VoiceOver remains RC work.
- `python3 scripts/ci-hygiene.py` and `git diff --check`: passed.

Commands use `xcodebuild -project Starfall.xcodeproj -scheme Starfall -configuration Debug -destination 'platform=iOS Simulator,id=21025903-D90D-4E30-BA74-45D3EFB2F5E4' -derivedDataPath /tmp/starfall-aging-build ARCHS=arm64 ONLY_ACTIVE_ARCH=YES test` with the selected classes/methods above. Release uses `-configuration Release -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/starfall-aging-release ... build`. Disposable logs: `/tmp/starfall-aging-{core,hosted-final,native-final,release}.log`; xcresults under the respective DerivedData Logs/Test folder.

A launch screenshot was inspected (empty board, readable dialogue and controls); it does not establish dense-board appearance or motion. Selected active-play/settings references are marked Needs refresh. No physical device delivery, human enjoyment, or actual VoiceOver acceptance is claimed.

Without automatic consumption, a neglected sky can fill sooner. This is an intended consequence of removing the mechanic; assess pacing in the next human play session before making any balance change.

Final native checks: `FallingSkyInteractionTests/testFirstShowerIsPlayableAndManualInputStaysPaused` and `SkyFlowInteractionTests/testFirstLightWinReplayAndFullSky` both passed on the final source. They cover an invalid empty tap, one scoring clear from a double tap, paused play, First Light win, replay, overflow, ending restore and fresh-survival entry. Together with the earlier two native checks, four selected UI tests passed. First Light completion does not establish survival balance or human enjoyment.

**Next action:** Assess the quieter survival game in the next human play session. Refresh dense active-play and help captures before claiming visual acceptance; physical delivery uses the canonical main-based updater when requested.

## Current-main integration — October 18

Integrated onto GitHub main `0d28c50` as local `726a21d`, preserving the newer feedback-ordering correction and unchanged v8 archive contract. Clean integration checks: 166 core tests, Debug simulator build and Release build passed. The expanded 96-test hosted selection found four assertions in one seed-28 input test still assuming aging locks all columns. Its scenario now explicitly verifies the unchanged opening group remains playable across an unrelated shower, scores once and cannot be replayed by completion; the moving-column stale-contact regression is unchanged. The corrected 16-test ResponsiveInputTests suite passed, alongside the other 80 passing selected hosted tests. Only tests and this evidence changed after the clean runtime verification. Logs: `/tmp/starfall-aging-integration-{core,hosted,responsive,release}.log`.

Git CLI lacks authentication on this Mac. Publication uses the connected GitHub app, with its tree SHA compared to the tested local tree before merge. Phone delivery must then use the canonical updater and verify its actual installation receipt.
