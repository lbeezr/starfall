# Current storms expose choices; preservation stays situational

**Result: Partially verified · Owner: current implementer · October 17, 2026.** Keep current rules. In both fresh 64-seed cohorts, storm states offered multiple sampled clear selections more often than calm states. Saving Opal sometimes repaid a smaller or equal first clear, but was not a universal rule. These are untimed production-Core trajectories, not human interest, motor feasibility or a causal comparison with storms removed.

**Next action:** Use ordinary current-app play to observe whether players notice the simultaneous choices and choose deliberately. Seed 180 / shower 12 is a replayable prepared example for a later native comparison; it is not participant evidence. Do not tune Opal/gravity frequency from this sample.

[Preregistered method and decisions](../../design/OPAL_CHOICE_STUDY.md) · [summary](summary.json) · [replayable examples](examples.json) · [source/tool hashes](source.json)

## What the current rules offer

One visible-board clear follows each settled shower, for at most 24 showers. Two policies maximize current reward; one breaks score ties by spending fewer Opals. Each plays a separate trajectory. Candidates include tap groups, full traced components and bounded connected five-star subsets at Opal states. “Multiple” means distinct selected sets, which may overlap; it does not prove that alternatives have meaningfully different outcomes. Larger partial traces are omitted. No oracle result enters policy choice.

The phase is the **just-committed shower**, classified by Core: nine calm waves, then three storm waves. Death states are excluded from decision denominators. States within a seed are correlated, and phase, occupancy, supply and survival differ together. Percentages describe these trajectories only.

| Cohort / policy | Calm: multiple selections / decisions | Storm: multiple selections / decisions | Eligible Opal decisions | Smaller-first immediate gain | Equal-first immediate gain |
| --- | ---: | ---: | ---: | ---: | ---: |
| 160–223 / largest immediate | 203/1121 (18%) | 272/360 (76%) | 401 | 3 | 2 |
| 160–223 / preserve on ties | 211/1130 (19%) | 282/363 (78%) | 427 | 3 | 2 |
| 224–287 / largest immediate | 222/1121 (20%) | 286/366 (78%) | 355 | 8 | 1 |
| 224–287 / preserve on ties | 225/1121 (20%) | 285/368 (77%) | 375 | 8 | 1 |

Immediate gains compare the first clear plus the best following tap/full-component clear on the resulting board, with no intervening shower. Smaller/equal categories may overlap and cannot be summed as unique states. No sampled Opal state hit an enumeration cap. Raw phase counts include after-shower oracle gain/safety metrics, explicitly separated from visible-board planning.

The first current equal-reward example is seed 180 / shower 12. Both first clears earn three light. Spending Opal leaves a best next clear of three; preserving it leaves six, giving **six versus nine total** without requiring future arrivals. Discovery seed 188 / shower 21 offers six then three instead of eight then zero. Retained losing-preservation examples remain in examples.json; do not teach “always save Opal.”

Preserve-on-ties scores totaled 4406 versus 4345 in discovery and 4455 versus 4440 in confirmation, but most rounds were censored at 24 showers and policies visited different states. This is not evidence of full-round superiority. Immediate preservation gains remain sparse even when several legal selections exist.

## Gravity exposure limits

Active orbit decision states numbered 9/8 in discovery and 0/4 in confirmation, by policy order. Orbit-plus-Opal states numbered 2/2 and 0/1. Core legal actions/settling include gravity, but these reward-seeking policies do not deliberately form or preserve magnetic pairs. This sample therefore gives little evidence about combined orbit/Opal strategy and cannot justify changing gravity supply. The native prepared gravity fixtures establish opportunities separately; they do not establish natural encounter frequency or enjoyment.

## Verification and boundaries

Production App/Core/resources/project are unchanged from main **1b466c3**. Only the offline sampler adds counters and phase reconciliation; policies and candidate enumeration are unchanged. Source provenance records base HEAD and working-tree differences for each run. Swift 6.4 / Xcode 27.1 compiled unchanged production Core and the checker with `-O -DDEBUG`.

| Acceptance | Result |
| --- | --- |
| Existing report compatibility | Seeds 128–143 reproduce every old JSON value after removing added counters/phaseCounts; no policy or outcome change |
| Repeatability | Discovery repeated byte-for-byte, report SHA256 bc2cb628de8f0c649928f4161d1e93857e11269e45338c902360ab7c34ed079b |
| Phase/legality/source checks | Phase boundaries 9/10/12/13; every phase metric sums to its overall total; Core action legality/save validity; immutable source probes; fixture JSON round-trip and topology/cap checks passed before/through sampling |
| Core regression | swift test: 109 passed, zero failures; /tmp/starfall-phase-study-core.log |
| Simulator compilation | Debug build passed, no warnings/errors; iPhone 17e / iOS 27.0 (24A434), arm64 unsigned, Starfall; build_sim_2026-10-18T01-33-31-341Z_pid85535_ded14a3d.log |
| Hygiene | python3 scripts/ci-hygiene.py and git diff --check passed |
| Runtime/save changes | Not applicable: no product code, membership, resource, rules or save changes |
| New interaction/animation/VoiceOver/device preference | Not run for this tooling-only study; no such acceptance claimed. Current presentation evidence remains source-bound in the gravity overlap record |

Raw reports/compiler/progress logs remain under ignored artifacts/opal-choices. No app was installed or retained phone round reset. An attempted fast-forward to the API-published equivalent failed because local and published history differ; full trees were identical, and the clean research branch was then created directly from origin/main before accepted sampling. This did not alter source or results.

**Decision:** Retain the diagnostic counters for reproducible future comparisons; adopt no new mechanic, route or tuning. The remaining question is whether the offered choices are legible and rewarding during normal falling play. Current results support testing that question, not declaring the game more enjoyable.
