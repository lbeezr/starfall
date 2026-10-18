# Six follow-up debt fixes

**Result:** Partially verified · **Owner:** current implementer · **Date:** 2026-10-18

Ship exact contact clocks, tablet Welcome activation, semantic archive checks, RC failure evidence, rule-aware help and visible save recovery independently. [Acceptance and scope](../../TECH_DEBT_FOLLOWUP.md). This record separates code fixes from native, visual, actual VoiceOver and physical-device evidence.

**Next action:** ship RC failure handling; tablet diagnosis and Help/recovery UI remain open.

## Verification context

Initial main: `5ba0d36`. Xcode 27.1 (27A9275); Debug / iOS 27.0, Starfall Forecast Fallback QA `1E9DCEF5-BF64-4052-AF8D-A6A205F711EE` unless a task states otherwise. App tests use isolated defaults, injected clock/presenter/feedback and the shared Starfall scheme. Native commands use sequential tests and ad-hoc simulator signing (`CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES DEVELOPMENT_TEAM= CODE_SIGN_STYLE=Manual`). Raw logs/results: ignored `artifacts/debt-followup/` and the XcodeBuildMCP workspace. Actual VoiceOver: deferred to RC; no physical installation claimed.

## 1. Exact contact clock

Source: main `5ba0d36` plus `App/FallingSkyStore.swift` and `AppTests/TraceInputPolishTests.swift`. No schema/rule/RNG/artwork or geometry changes.

Root cause: contact holds reused interruption grace (`max(0.5, remainder)`), manufacturing time on release. The isolated reproduction held/released at the same clock instant every 100 ms: a 0.25 s opening deadline remained unfired at 1.05 s. Contact freezes now preserve the exact nonnegative remainder; pause/background keep their existing grace. An interruption arriving during an already-frozen contact applies its own grace before invalidation. The first new sibling test caught that nested case; it was corrected at the shared clock owner before the final run.

Examined touch-down/release, ticket replacement, invalidation, pause, suspension, balance/manual-shower resets, due delivery and stale callbacks. Existing near-deadline hold assertion intentionally changes from manufactured 0.5 s to the original 0.1 s; its 100-second held interval, stale callback and duplicate/stale ticket assertions remain. New cases cover zero-duration contacts through opening, regular fresh survival, retained Dusk and First Light, plus pause/background during contact. Actual held time still pauses rain; this is not a no-hold redesign.

| Check | Result |
| --- | --- |
| `swift test` | 162 passed. |
| Hosted TraceInputPolish, FallingSkyStore, ResponsiveInput | 73 passed, zero failures/skips. |
| Native stationary hold → trace/tap and Settings/background gesture recovery | 2 passed, zero failures/skips. |
| Debug simulator compilation, hygiene and diff | Passed. |

Native run used the standard context above, full normal input/motion assertions and no blanket retries. Gameplay quality, physical contact comfort and actual VoiceOver are separate; actual VoiceOver deferred to RC. No visual change requires replacement captures.

## 3. Semantic save validation

Source: main `cf6f846` plus `Sources/StarfallCore/FallingSky.swift`, `Tests/StarfallCoreTests/FallingSkyTests.swift` and `AppTests/SkySaveArchiveTests.swift`. Validation now requires distinct incoming identities and a blocked column whose highest occupied row reaches the landing limit. It uses the same height function as shower admission, including retained gravity boards. Schema, generation, RNG, score and outcome precedence are unchanged.

The reproductions decoded successfully but admitted forecast IDs `[0, 0, 2]` and a loss against an empty column. Regressions cover fresh survival, retained legacy and First Light, every blocked column, generated saves and terminal states, current-envelope rejection with no legacy fallback, read-only store construction and backup before replacement. Reviewed current/v7–v3 admission through their shared core validator. No claim that every possible malformed field is rejected follows from these two invariants.

`swift test`: 164 passed. Hosted archive + store: 51 passed, then all 11 archive tests passed after the added semantic admission regression; zero failures/skips. Debug simulator build passed as part of hosted tests on the phone context above. The retained replay driver with `precondition(game.isValidSave)` accepted all 1,337 archives and produced byte-identical output against the pre-refactor corpus (`swiftc -D DEBUG Sources/StarfallCore/*.swift <driver>`; raw comparison in `/tmp/starfall-semantic-replay`). Hygiene and diff checks passed. No UI/geometry/artwork change; native visual and actual VoiceOver checks are inapplicable to this batch.

## 4. RC failure handling

Source: main `8d3e81e` plus `scripts/rc-platforms.py` and its execution tests. The reproduced xcodebuild timeout was replaced by a shutdown timeout, while TemporaryDirectory removed the partial bundle and the plan still said planned. The runner now records a primary error separately from bounded secondary diagnostics, attempts a partial summary, preserves one failed bundle per role (64 MB maximum each), trims logs by reading only their tail, and marks the plan failed before temporary cleanup. Oversized bundles retain at most 100 path names plus size/count; they are explicitly marked over-limit rather than claiming full raw retention. A later role run replaces its own prior evidence; successful bundles remain disposable.

Examined boot, bootstatus, nonzero/timeout tests, summary parsing/counts, retention, shutdown and top-level temporary-directory ownership. Cleanup failure after otherwise successful checks is still a failure. Already-booted simulators are never shut down. Tests execute these paths with mocked subprocess boundaries and real temporary files; they do not claim native platform acceptance.

`python3 scripts/test_rc_platforms.py`: 11 passed. `test_native_test_plan.py`, hygiene and diff checks passed. Actual RC preflight still blocks because no iOS 17 runtime is installed; there is no fallback or download. No app source or deployment-service change; simulator app rebuild is inapplicable to this tooling-only batch.
