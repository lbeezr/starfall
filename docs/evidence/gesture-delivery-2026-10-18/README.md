# Gesture improvements delivered individually

**Result:** Partially verified · **Owner:** current implementer · **Date:** October 18, 2026

All five gesture improvements were merged and delivered one batch at a time through the canonical updater. Each published tree exactly matches its independently verified local tree. Delivery receipts verify the same single app and actual installed identity; they do not establish physical thumb comfort.

**Next action:** observe repeated phone play on final installed runtime `dev.8a753c144b`. Actual VoiceOver remains RC acceptance. The prior source-publication block was resolved by the user’s explicit authorization naming the public repository and canonical delivery.

## Individual deliveries

| Batch | PR | Current-main source | Installed runtime |
| --- | --- | --- | --- |
| Immediate cardinal swipes; hold then draw | [#134](https://github.com/lbeezr/starfall/pull/134) | `e4e672a7a51855f38d21e5c2c94cdb9c33edff57` | `dev.5294727fd1` |
| One bounded follow-up | [#135](https://github.com/lbeezr/starfall/pull/135) | `764c53cc07146003f8f6babc770c238b04e416a9` | `dev.677341325c` |
| Coarse-flick edge forgiveness | [#136](https://github.com/lbeezr/starfall/pull/136) | `4c145d6b79ecac16ff4f7a11b27f505bc2c663cf` | `dev.5e10acea62` |
| Hold progress and armed feedback | [#137](https://github.com/lbeezr/starfall/pull/137) | `64223e65ef9b6d353c6ff1d2c8bbf99300a94cc6` | `dev.0f08b779a9` |
| Immediate quiet-mode readiness | [#138](https://github.com/lbeezr/starfall/pull/138) | `ec6d638eecc84152651eabd1d00107c9fe69e249` | `dev.8a753c144b` |

The updater archives current main, runs Core tests, builds/signs, rechecks main and known CI failure status, installs over `com.starfall.prototype`, then verifies actual app identity. Each receipt is checked before merging the next code batch. No feature checkout is installed, no second app is created, and the updater does not reset or launch the player’s saved round. See the [canonical delivery contract](../../DEVELOPMENT_BUILDS.md).

[Sanitized canonical receipts](receipts.json) retain source, build, bundle and validation fields, excluding device identifiers and installation paths. Each was read from the updater after its individual installation. Final main tree `267b8a19f58cf8043fd4a51de55dc786be5bcebe` exactly matches verified local `ff4a8e0`; there are no source differences. This follow-up changes documentation only.

## Verification and limits

- The final combined source passed **169 Core, 286 hosted and 13 native UI tests**, zero failures/skips, plus Debug/Release Simulator builds and hygiene checks. [Final source hashes, commands and tests](../quiet-input-2026-10-18/README.md).
- Earlier batches retain their independently tested source and limits: [foundation](../immediate-swipes-2026-10-18/README.md), [follow-up](../follow-up-input-2026-10-18/README.md), [edges](../gesture-edges-2026-10-18/README.md), [hold feedback](../hold-feedback-2026-10-18/README.md).
- Native interaction evidence covers rapid inputs, all directions, same-family swaps, coarse strokes, exact held drawings, Settings/background, maximum text and system Reduce Motion. Normal animation checks observe node motion. The [armed-state capture](../hold-feedback-2026-10-18/README.md#inspected-native-presentation) remains source-bound to batch 4.
- Remote CI runs on pushes to main, not these PR heads. PR-head checks therefore return empty. Canonical receipts record `mainCIAtInstall: pending`; local development validation is allowed by the repository policy. This is not a cloud CI pass or RC approval.
- Physical installation is verified separately from gameplay. Physical missed-touch rate, accidental-draw rate, touch-to-photon timing and haptic comfort have not been observed. Actual VoiceOver and minimum-OS RC acceptance remain open. Keep the [engineering follow-up](../../ENGINEERING.md#gesture-response-acceptance--october-18-2026) until those checks are made.

Documentation checks: local links, `python3 scripts/ci-hygiene.py`, and `git diff --check` pass. Runtime tests are not repeated for this documentation-only update.
