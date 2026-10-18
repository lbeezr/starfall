# Third debt pass: restore and native acceptance reliability

**Result:** In progress · **Owner:** current implementer · **Date:** 2026-10-18

[Ranked scope and acceptance](../../TECH_DEBT_THIRD_PASS.md). Main `b5ec445` is the starting source; the checkout was clean and origin was already up to date. This report records separate core, build, native, visual and physical-device results as batches finish.

**Next action:** primary CI simulator lifecycle, then tablet clearance and default-game evidence.

## Baseline reproduction

A local standalone Swift driver compiled with `swiftc -D DEBUG Sources/StarfallCore/*.swift <main.swift>` generated gravity generation 2 / seed 0 using ordinary showers until overflow. The archive validates, has lost outcome and blocked column 5. That column contains a magnet. Calling `removingGravity()` removes the magnet, compacts its survivors and fails the `result.isValidSave` precondition at FallingSky.swift:218 because the blocked column is no longer full. Raw driver/archive/crash output is in `/tmp/starfall-next-audit` and `/tmp/starfall-gravity-terminal.json`; no player data was changed.

The previous replay corpus samples intermediate rounds and replay starts, so its passing 1,337 archives did not establish terminal migration coverage. A passing ordinary invalid-overflow regression also did not establish that migration preserves terminal outcomes. The correction must cover both contracts.

## 1. Terminal gravity retirement

Verified on main `b5ec445` plus `Sources/StarfallCore/FallingSky.swift`, `Tests/StarfallCoreTests/GravityRetirementTests.swift` and `AppTests/SkySaveArchiveTests.swift`. Overflow is a committed result: explicit gravity retirement can remove supports and compact the losing column after that result. Requiring the post-retirement column to remain full confused committed history with the current presentation board. The validator now recognizes the existing bounded retired-mass accounting only in non-critical-mass standard-generation retired skies. Ordinary fresh, retained unretired and First Light archives still require a full blocked column. All existing conservation and gravity invariants still apply.

No new field, schema, RNG, score, seed, cadence or survivor identity was introduced. Existing retired archives have no pre-retirement column snapshot, so exact historical occupancy cannot be reconstructed from them; the compatible retirement accounting is the available provenance. This validator is not proof that an arbitrary archive's history actually occurred.

The original generated seed-0 archive now reports `before valid=true, outcome=lost` and `after valid=true, outcome=lost`, without a trap. Added 128 terminal histories across both gravity generations verify retirement, compaction, outcomes, stable survivors, round-trip, inert terminal actions and replay. Hosted cases cover current/v5 envelope read-only restore, activation, canonical re-encode, relaunch and replay. Reviewed raw admission, retirement postcondition, feeding-Dusk adoption and app archive precedence.

| Check | Result |
| --- | --- |
| `swift test` on final source | 165 passed, zero failures. Includes existing ordinary impossible-overflow/duplicate-forecast negatives. |
| Hosted store/archive + native First Light win/replay/full/restore | 55 hosted + 1 native passed, zero failures/skips. |
| Final hosted archive, gravity-retirement and Dusk-production suites | 24 passed, zero failures/skips. |
| Existing retained/replay corpus, each save validated | 1,337 accepted and byte-identical to the original baseline. |
| Debug simulator build, hygiene, diff | Passed. |

Xcode 27.1 / iOS 27.0, shared Starfall scheme, Debug, iPhone 17e `Starfall Forecast Fallback QA` (`1E9DCEF5-BF64-4052-AF8D-A6A205F711EE`), sequential native tests with ad-hoc simulator signing (`CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES DEVELOPMENT_TEAM= CODE_SIGN_STYLE=Manual`). Raw results: XcodeBuildMCP; Core/restore/replay logs in `/tmp/starfall-third-core-final.log` and `/tmp/starfall-next-audit`. The native ending flow preceded only the final exclusion of critical-mass skies from the retirement exception; final Core/hosted tests include that guard. UI/geometry/artwork unchanged; no screenshot refresh or actual VoiceOver session is implied. Actual VoiceOver/minimum-iOS/device acceptance remain separate RC gates.
