# Integrate sky flow with the current drawing game

**Status:** Partially verified · **Owner:** Current implementer · **Date:** 2026-10-17

The sky flow is rebased onto GitHub main `ba348d7`, preserving the adopted constellation drawing, existing bundle/save identity, build-ID display and main-to-iPhone updater. The Game Center checkpoint remains separate in draft PR #31; this integration includes none of its transport, account, ranking, entitlement or configuration changes.

**Next action:** Complete the exact integrated-source native checks, publish a focused PR, merge it and verify the updater's observed result. Do not describe the phone as updated until installed provenance identifies the new build.

## Boundaries and evidence

Only the sky-flow commit `f35eba8` is ported. Conflicts preserve main's trace-surface/input-generation cancellation, build ID and all current source/configuration owners. `SkyFlowCeremony` owns isolated Debug review defaults so no parked rankings fixture is required. Main's original rules, assets and CI/updater scripts remain unchanged. Its existing tests gain explicit Begin/Resume navigation; the restored constellation swipe still clears the chosen five and leaves the sixth.

The original [flow report](README.md), captures and hashes remain historical evidence of the pre-integration prototype. They do not establish current drawing-game acceptance. New integration results follow below.

- `swift test`: 63 passed, zero failures; `/tmp/sky-flow-integrated-core.log`.
- `python3 scripts/test_native_test_plan.py`: two passed. Hygiene passed; final diff check pending.
- Debug hosted/flow/swipe checks: pending, `/tmp/starfall-sky-flow-integrated-v2.xcresult`. Initial native compile identified the missing shared system-motion setter from the old local base; added it to the existing test utility before rerunning.
- Release simulator build: pending, `/tmp/starfall-sky-flow-integrated-release.log`.
- Actual VoiceOver: deferred to RC; not run on this development integration. Physical-device gameplay/motion acceptance remains separate from successful updater installation.

The local updater was observed enabled and up to date (`dev.bc187c831e`) before the merge. Its contract waits for successful CI on the exact main commit, then signs and installs over `com.starfall.prototype`; it never resets, uninstalls or launches the app. Pending/failed CI, a locked/unavailable phone, or signing/install errors defer delivery and preserve the existing installation.
