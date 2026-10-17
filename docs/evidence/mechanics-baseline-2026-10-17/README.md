# Mechanics exploration baseline

October 17, 2026, Eastern time. Source: `a999e6bf7e7c74026d6b8d457e138af29d68d537` plus the sampler metric additions in this batch. Production rules, saves and UI are unchanged. Pre-existing dirty paths: `Starfall.xcodeproj/project.pbxproj` and untracked `Starfall.xcodeproj/project.xcworkspace/`; preserved. The native build uses that working tree and is not clean-commit acceptance.

Hypothesis: meaningful alternatives remain scarce even when a policy clears every available group. Scope: expand the existing offline sampler rather than introduce another gameplay flag. Acceptance: deterministic output, all existing policy results unchanged, explicit dry-wait and high-column metrics, and no runtime dependency. Adopt the diagnostic additions; choose a single playable mechanic separately before changing rules. Revisit these measures with that candidate and human observations; they do not establish enjoyment.

`baseline.json` records 200 seeds, a 60-shower cap and six policies. The clear-all policy offers multiple groups at 215/3224 decision states (6.7%). It has 2190/5090 dry surviving shower states (43.0%), with a longest dry run of one. Idle states can retain an existing group indefinitely; zero dry states there does not imply continued useful input. Overflow showers are excluded from opportunity denominators. Maximum dry run is measured in showers, not seconds.

`highColumnChoices` counts decision states where some legal groups touch a tallest column and others do not. It measures the availability of a column-pressure choice, not whether it improves eventual survival. Tied tallest columns count equally. The existing next-preview outcome metric separately counts choices with different immediate overflow outcomes. Neither establishes long-term strategic depth.

Validation: compiled both original and expanded samplers with `swiftc -O Sources/StarfallCore/*.swift <sampler>`, ran both and asserted equality of every pre-existing result field for all six policies. Passed. `python3 scripts/ci-hygiene.py`, `git diff --check` and `swift test` passed (60 tests). Xcode 27.1 (27A9275), Debug generic iOS Simulator build passed with signing disabled and `/tmp/starfall-mechanics-derived` DerivedData. Raw sample/build output remains in `/tmp/starfall-mechanics-*`. No app-target file additions; sampler is outside app/package targets.

Rule/save and interruption changes: inapplicable. Hosted/UI tests, native interaction, visual/full-animation, actual VoiceOver and physical-device checks: not run for this offline-only change. Build success is compilation evidence only.

Research method: [Microsoft's games user research overview](https://www.microsoft.com/en-us/research/publication/data-driven-games-user-research/) describes using behavioral data to investigate game usage. Our application is to use repeatable local simulation as a diagnostic alongside the repository's observed-play protocol, without adding telemetry to the app. The research does not select a Starfall mechanic or validate these bots as player models.

Reproduce with `swiftc -O Sources/StarfallCore/*.swift tools/sample-falling-sky-balance.swift -o /tmp/starfall-sample` followed by `/tmp/starfall-sample`. Output is deterministic JSON; no network or normal-save access occurs.
