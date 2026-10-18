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

## 5. Rule-aware Help

Source: main `20af64d` plus the six source/test paths in snapshot `361f431fc46a` (`sha256(git diff -- <paths>)`, in App menu/view/ceremony/preferences and hosted/native flow tests). `SkyHelpContext` snapshots current Core rules or the pending entry choice. Welcome/retained replay retains its actual Dusk/challenge rules; New sky uses the Core fresh-survival factory. Help has no implicit Dusk/critical-mass defaults. First Light omits opening cascades, Opal/storm and arrangement sections; its objective still names the unavailable mechanics. Entry exposes the same Settings & help action without committing a round.

Examined Welcome, initial/fresh/replay/challenge Entry and in-game Help call sites. Hosted selection tests cover current fresh, retained Dusk and First Light against each pending choice and prove reading leaves flow unchanged. `swift test`: 164 passed. Hosted SkyFlowState: 17 passed; native largest-text pressure and complete Help read-through: 2 passed; native pending First Light Help/cancel and shared Welcome preferences/paused retained summary: 2 passed in the final run. The latter exposed a stale case-sensitive `Paused` assertion from earlier copy; it now checks the complete shipped phrase `Automatic showers paused`, retaining the pause-state requirement. Debug and Release simulator compilation passed; hygiene/diff passed. Existing files keep target membership.

| Entry after Help | First Light Help |
| --- | --- |
| <img src="dev-20af64d-wip-361f431fc46a-first-light-entry-17e-default.jpg" width="220" alt="First Light Entry with Begin, Back to Observatory and Settings and help inside the dialogue panel"> | <img src="dev-20af64d-wip-361f431fc46a-first-light-help-17e-default.jpg" width="220" alt="First Light Help showing shower, pause and fixed 18-starlight objective text with Done reachable"> |

Inspected native captures, iPhone 17e / iOS 27.0, default text, normal app route with isolated reset defaults. Text and all Entry actions fit; Done remains available in Help. Full largest-text read-through is independently tested above. Tablet Welcome hit-result diagnosis remains open; these phone samples do not close it. Actual VoiceOver and physical-device acceptance remain RC work. Raw captures/result bundles stay in `/tmp/starfall-help-attachments` and XcodeBuildMCP.
