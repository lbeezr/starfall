# Deliver and evaluate the next pacing iteration

**Status:** Local technical trial ready; user play and publication pending · **Owner:** pacing coordination chat · **Updated:** October 17, 2026

Implement the [bounded pacing comparison](design/PACING_NEXT.md) in separate batches. Begin with the verified production baseline; keep timing rules, scheduling, presentation and measurement under distinct owners. User authorized starting the sequence and parallel work where scopes do not overlap.

**Next action:** Use the [user-only four-round protocol](design/PACING_PLAYTEST.md) against validated runtime/export `b42eba357515793c834fec7d9125907ca106a22f`. Tasks 1–6 are locally integrated and technically checked within the [acceptance limits](evidence/pacing-acceptance-2026-10-17/README.md); task 7 awaits actual user observations. B is not adopted. Remote publication remains pending; this work performed no phone or updater operation.

## Scope and success

Includes the existing opening/tracing integration, a test-only timing comparison, local measurement, native acceptance and an observed adoption decision. Excludes a second installed phone app, changes to wave sizes or RNG, adaptive difficulty, new mechanics and production analytics.

- [ ] Approved opening and tracing verified together on current remote main.
- [ ] Versioned cadence and the single clock preserve saves and interruption contracts.
- [ ] A/B presentation and local tools share one exact verified source.
- [ ] Human comparison resolves adoption/removal or one bounded remaining question.

## Separate ownership

These task chats are user-owned. Dependencies require concrete source/API handoff, not merely a task starting.

| Task | Owned scope | Dependency and completion |
| --- | --- | --- |
| 1 — Reconcile the production baseline | Integration gaps and focused baseline regressions | Recheck remote main; exact verified source, Core/hosted/native evidence and Debug/Release builds. Respect existing integration/phone owner. |
| 2 — Define deterministic cadence rules | Core cadence value/API, persistence contract, Core tests | After 1. Publish interval indexing, phase/warning semantics and compatibility tests. |
| 3 — Integrate cadence with the single clock | Store scheduling and hosted lifecycle tests | After 2. Publish narrow cue values and test seams; verify no catch-up/stale actions. |
| 4 — Present readable phase cues | View/theme cues and focused UI tests | After 3 contracts. Can run alongside 5 once edit scopes are confirmed separate. |
| 5 — Build local pacing comparison tools | Offline tools, tool fixtures/checks, measurement report | Read-only reconnaissance now; implementation after 2/3 contracts. No App/Core runtime edits. |
| 6 — Validate the combined native candidate | Cross-boundary acceptance and source-bound evidence | After 4/5. Return implementation failures to their owners. Coordinate simulator use to avoid conflicting global settings. |
| 7 — Compare play and resolve adoption | Human protocol, observations and decision | After 6. Do not substitute bots for unavailable participants. Retain pending human checks honestly. |

Task IDs, in order: `01a14bab-4b80-7840-8b4c-4ef302c2132f`, `01a14bab-4d08-71a1-a487-a6708e632b44`, `01a14bab-4fb9-7651-a939-00081f963b61`, `01a14bab-51a8-78a2-a1a2-15d2ac52b14d`, `01a14bab-5496-7322-9c9b-77e18003aea2`, `01a14bab-5695-7821-8333-fc1f25038a72`, `01a14bab-5af2-7c71-bca6-5e196dd422b6`.

## Integration and verification

Preserve unrelated agents' work. Do not run independent Git mutations against the same checkout concurrently. Each handoff names commit, dirty paths, checks, and material gaps. Stage explicit paths and integrate verified batches incrementally; a shared simulator build directory or global accessibility setting is also a shared resource.

Comparison B remains test-only until the adoption decision. The independent phase-cue and tooling owners must not each add a runtime selection path. Core and Store owners establish that single test entry contract first. A final adoption needs removal of temporary routes or a named bounded follow-up, not a permanent pilot flag.

Rule/save, interruption, animation and accessibility acceptance is defined in the design. Human preference remains unverified until actual comparison. Source changes require the repository's automated and Apple-tooling checks; this coordination document adds no new approval gate. Physical installs and updater changes are outside these task scopes.

## Local completion and next decision

| Task | Local status | Exact evidence / remaining boundary |
| --- | --- | --- |
| 1 — Baseline integration | Done | Opening/tracing, corrected regressions and [integration record](evidence/pacing-baseline-2026-10-17/README.md); reconciled pinned main `b88fcfc` locally. |
| 2 — Core cadence | Done | Versioning/replay and 72 Core checks; [contract](design/PACING_CORE_CONTRACT.md). |
| 3 — Store clock | Done | Single deadline, shared fixture and lifecycle/trace checks; [contract](design/PACING_STORE_CONTRACT.md). |
| 4 — Cue/export | Done for local trial | B normal/reduced-motion, largest text, Settings and geometry checks pass on final presentation source; no B adoption. |
| 5 — Measurement tools | Done | 192 modeled runs, 8,765 parity commits; independent output reproduction; [limits/counterexamples](evidence/pacing-tools-2026-10-17/README.md). |
| 6 — Combined simulator acceptance | Done within recorded scope | 102 hosted and selected native checks on `5e56d5a`; seven hosted/six native presentation follow-ups on `b42eba3`; [source-bound matrix](evidence/pacing-acceptance-2026-10-17/README.md). |
| 7 — Human comparison | Pending | Protocol ready: seed 0 A→B, seed 11 B→A. No human results; unfamiliar-player comprehension remains open. |

Normal Debug/Release and exported Debug builds, hygiene and whitespace checks pass at their recorded sources. Initial runner stalls, aggregate bundle failures, test setup corrections and bounded reruns remain documented. Continuous smoothness, accelerated-opening trace comfort, actual VoiceOver and physical-device fit are not established. Local technical completion is not remote publication, RC acceptance or enjoyment evidence.
