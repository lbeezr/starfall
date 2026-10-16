# Starfall: autonomous MVP delivery roadmap

Updated 2026-10-16 UTC. This is the bounded plan from the current prototype to a release candidate. The delivery coordinator owns execution, review, integration, evidence, and the next permitted assignment. Routine work proceeds without another request to continue. A blocked lane must not block independent work, and a running task label is not delivery evidence.

## Current delivery checkpoint — 2026-10-16 12:27 UTC

- Published runtime: `2f2bb2081de01a6d31dfe62a694f6005cf7dbe56`; latest run [38898933808](https://github.com/lbeezr/starfall/actions/runs/38898933808).
- Core tests, three prior native flows and bundled privacy-manifest validation pass. Large-text gameplay audits pass; Settings still reports `Text clipped` for the Calm effects label. The fourth UI flow is not accepted. Retained screenshots are partial evidence.
- Next executable diagnosis: inspect native accessibility text bounds and row layout for that label, preserve unsuppressed audit assertions, obtain independent review, then rerun exact-head acceptance.
- Prepared locally, not integrated: presentation-boundary interruption tests, hosted test target, approved icon registration and playtest/release checklists. Final integration review remains pending; no native test or icon compilation pass is claimed for this prepared work.
- Human playtest, actual VoiceOver and signed physical-device distribution remain separate gates. Independent source preparation does not establish those outcomes.

## Product contract

Make one small, relaxing, polished native iPhone puzzle that is understandable and pleasant to replay. Keep Swift, SpriteKit and SwiftUI; Candy Glass materials within a moonlit atmosphere. Keep the current 7×7 board, five distinct shapes/colors, orthogonal groups of three or more, free invalid taps, bounded dead-board recovery, 70-jewel target and 18 valid moves. Target/move counts remain provisional until playtested.

No timer, power-ups, new modes, character collection, progression system, backend, account system, analytics, third-party assets or speculative monetization framework. No new game genre. Ads/IAP and tracking remain physically absent from this clean MVP; any later monetized edition needs its own scoped decision. Apple Arcade quality is an aspiration, not acceptance or distribution approval.

## Verified starting point

- Last accepted runtime: `88738c204e8b33698da9de89334893480faa9a94`.
- Exact-head [native run 38862074669](https://github.com/lbeezr/starfall/actions/runs/38862074669): 15 core tests, native build and three UI flows passed; Xcode 26.3, iPhone SE (3rd generation), iOS 26.2 Simulator.
- Evidence inspected 2026-10-16 06:47 UTC: real tap/score/move transition, navigation/settings, normal save/relaunch, settled background/resume, Calm Effects persistence, final win/loss taps, terminal save restoration and replay. Eight PNGs and ZIP hash-verified. Artifact `12029922915` expires 2026-10-17 06:45:13 UTC; separately retained copies are necessary evidence after expiry.
- Existing procedural glass materials have rendered evidence. Concept artwork is a target, not proof of implementation equivalence.
- Not yet established: rapid/in-flight interruption safety, actual VoiceOver usability, wider layout coverage, animation quality/performance, physical-device behavior, human-play balance or signed distribution.
- The append-only historical sections of `VALIDATION.md` describe earlier states. Its later source-bound entries supersede earlier “not run” statements; no old pass transfers automatically to new source.

## Ownership and execution order

Active assignment as of 2026-10-16 11:19 UTC: the accessibility implementation owner holds `App` and `UITests`; the CI owner holds the fourth-flow evidence integration. The immediate slice is adaptive scroll-safe large Dynamic Type, 44-point controls, a larger settings detent and a scoped Apple accessibility audit (`textClipped`, `sufficientElementDescription`, `hitRegion`). This does not constitute an actual VoiceOver pass. A disjoint release-preparation owner is adding the current-source privacy manifest and project resource registration; CI will verify the bundled declaration. Other entries are responsibility slots; the coordinator records each actual assignee and exact source when starting a slice. One implementer owns each changed file at a time; an independent reviewer owns review, not overlapping edits. CI/evidence capture is serialized after integration to avoid testing stale heads or cancelling a useful run.

| Lane | Accountable owner | Permitted first slice | Dependency | Acceptance / next transition |
| --- | --- | --- | --- | --- |
| Delivery and integration | Coordinator | Complete active accessibility slice; reconcile current head and working tree before writes | Existing owners and approved budget | Reviewed diff, exact-head results, durable evidence, then next eligible slice |
| Reliability | Reliability implementer | Reproduce rapid-input/in-flight settlement gaps; introduce only the narrow test seam actually needed | Current committed-turn and presentation-settlement behavior | Tests distinguish committed rules state from interrupted animation; no double spend or permanent input lock |
| Independent quality review | Reviewer distinct from implementer | Review reliability change and tests against the product contract | Proposed diff | No unresolved correctness/architecture blocker; regression coverage addresses reproduced risk |
| Layout and accessibility | Platform acceptance owner | Implement the active adaptive-layout/audit slice; retain sole App/UITests ownership until integrated | Current source; Apple tooling for runtime claims | Source-bound captures/audit results, then one bounded repair if a real failure is found |
| Feel and playtest | Presentation/playtest owner | Prepare short evaluation script and compare implementation against approved visual target | Stable reliable build; no overlapping renderer edits | Real animation evidence and human observations; only measured, small polish/tuning changes |
| Release preparation | Release owner | Inventory missing icon, production configuration and distribution requirements | MVP contract; no signing access needed for inventory | Release checklist and unsigned preparation; signing/publication waits at explicit gates |

The active accessibility slice proceeds first; milestones are acceptance groups rather than a requirement to delay independent work. Reliability investigation and read-only release preparation can run in parallel, with reliability edits queued behind the current App/UITests owner. Renderer or SwiftUI edits serialize when their paths overlap. Do not create work just to occupy an idle lane.

## Milestone 1 — Close interaction and persistence gaps

**Next reliability slice after the current overlapping accessibility edits; investigation may start now. No new feature.**

1. Exercise repeated input while a valid clear is pending, including a second input that would otherwise be legal. Assert exactly one move and one rule transition until input reopens.
2. Exercise inactive/background settlement during a clear, and motion reduction enabled during a clear. Assert the committed board/counters are retained, presentation settles, and a subsequent legal tap works.
3. Exercise restart/late completion interaction if the reproducible path permits it. A stale animation callback must not unlock or redraw a different game incorrectly.
4. Check malformed/invalid saved-state fallback against existing validation; add focused cases only for uncovered behavior. Do not replace the save system without a demonstrated need.

**Evidence:** deterministic focused tests for the relevant state transitions plus existing core tests; native exact-head build and all existing UI flows. Apple-hosted integration tests may directly exercise a small production boundary when XCTest's idle waiting prevents sub-second interaction. Label these as component/integration evidence; they do not prove a real rapid physical tap. Any remaining genuine gesture/interruption case stays open for device acceptance rather than being marked green through a synthetic shortcut.

**Exit:** no demonstrated double spend, lost committed turn, stale completion corruption or frozen input; independent review complete; exact test scope and residual physical-input limitation recorded. Then continue to platform acceptance.

## Milestone 2 — Make the existing game accessible and layout-safe

1. Establish the initial supported shipping surface: iPhone first. Capture a small and large iPhone layout, default and large Dynamic Type, menu/settings/active board/terminal outcome. Use already installed runtimes sequentially and only within the existing compute/storage boundary; no paid matrix or runtime download.
2. Inspect color/shape differentiation, legibility, tappable areas, safe areas and settings dismissal. Repair only observed failures, preserving the square board and rules.
3. Run an available accessibility audit, then separately exercise VoiceOver: enter play, traverse row/column and group-size labels, clear multiple groups, reach feedback, use settings, resume and restart. Check enabling VoiceOver mid-session and how focus recovers after a clear. Automated element presence is not actual screen-reader usability.
4. Check system Reduce Motion separately from the in-app Calm Effects preference. Verify disabled animations do not change game outcomes or leave input locked.
5. Resolve the currently declared device/orientation configuration before release. If iPad remains supported by the target, capture iPad portrait/landscape too; otherwise explicitly scope the product to iPhone before release. Do not claim iPad support from a simulator build alone.

**Evidence:** source/device/runtime/size settings with inspected screenshots, automated results and an explicit manual accessibility record. If cloud tools cannot operate VoiceOver faithfully, record that exact gap and proceed with independent work; require a real device/operator pass before declaring accessibility accepted.

**Exit:** no clipping/blocked controls on the intended supported layouts; accessible interaction actually demonstrated or clearly gated; all regression tests pass. No aesthetic or accessibility “pass” based solely on source review.

## Milestone 3 — Validate feel and the simplest viable game

1. Inspect a brief real rendered clear/fall/replay sequence from the app, respecting the compact evidence/storage budget. If recording support would exceed authority, use available frame evidence and reserve timing/feel judgment for device play.
2. Evaluate the existing Candy Glass materials, contrast and restrained motion against the handoff target. Fix a bounded observed presentation issue at a time; do not add a mascot, world, currency or new gameplay system to imitate concept art.
3. Prepare a five-minute playtest for the user and willing testers: explain the rule in their own words, play a round without coaching, restart, and describe confusion, satisfaction, frustration and desire to replay. Do not contact third parties or transmit builds without the required approval.
4. Assess move/target tuning using deterministic simulations for diagnostics and observed human play for decisions. Seed simulation proves invariants, not commercial viability or retention. Keep current tuning until evidence supports a small change.
5. Verify optional sound off by default; audible quality and haptics require actual listening/device evidence. Do not infer them from a switch assertion.

**Exit:** the complete loop is understandable, usable and satisfying in observed play; major confusion/friction resolved; no rules regression. If testers do not want to replay, stop expanding scope and report the evidence with one bounded improvement proposal. No claim of product-market fit from a small playtest.

## Milestone 4 — Produce a clean release candidate

1. Review release configuration: DEBUG acceptance fixtures absent, no secret/test-only behavior exposed, no ad/IAP/tracking/network dependency introduced, intended device/orientation support explicit.
2. Add and validate the missing privacy manifest for the app’s actual UserDefaults access, with an applicable approved reason verified against current Apple documentation (release inventory identifies `CA92.1` as the candidate). Do not add tracking or invent disclosures. Prepare production icon/app assets aligned with approved art direction using existing permitted tooling; no asset-credit spend or new external service. Validate required sizes and appearance in an actual build. Keep unrelated private concept documents out of public source unless publication is separately authorized.
3. Prepare app name/bundle identifier/version, concise metadata, support/privacy information and age-rating answers from actual app behavior. The initial release inventory found missing icon resources and a privacy manifest. Privacy packaging is now verified; approved icon registration is prepared locally. Prototype bundle identity, signing team and iPad family scope still need resolution. Name availability, seller identity, production identifier and contact/publication details remain user decisions where not established. Do not assert legal/privacy compliance without review of actual requirements.
4. Run final exact-head core tests, native tests, Release build and supported-layout checks. Review warnings, save compatibility, app launch/relaunch and clean-build contents. Fix actual release blockers rather than doing a broad refactor.
5. On an authorized physical iPhone, run the existing complete acceptance script, inspect responsiveness/animation, background/resume, accessibility, audio and memory/energy behavior. Record device/OS and observed results, not invented frame-rate or thermal thresholds.
6. Prepare a release evidence index with source SHA, build identity, test runs, screenshots, known limitations and unresolved gates. Label an unsigned simulator candidate distinctly from a signed device/TestFlight candidate.

**Exit:** an independently reviewed candidate with exact-head evidence and no unresolved release-blocking defects. Physical-device/signing gaps prevent a claim of a distribution-ready release candidate even if source preparation is complete.

## Milestone 5 — Beta, submission and post-feedback fixes (gated)

Proceed when the required account/signing/distribution authority is established:

- Build a signed device/TestFlight candidate with the approved identity; no credentials or persistent grants created or uploaded implicitly.
- Invite only approved testers and share only the authorized build/information. Collect feedback and fix bounded release blockers with the same review/test/evidence loop.
- Submit to the App Store only after the relevant listing, legal disclosures, pricing/availability and submission authority are confirmed. Apple review outcome and timing cannot be promised.
- Apple Arcade is a separate curated opportunity and commercial decision, not an automatic promotion or MVP prerequisite. No Arcade submission or agreement is implied by this roadmap.

The roadmap ends at an accepted release candidate and, when authorized, beta/submission with known review issues addressed. New modes, growth systems, monetization experiments and live operations require a new prioritized scope.

## Non-negotiable quality gates

- Rules remain deterministic in `StarfallCore` without UI imports. Presentation, storage and feedback have small explicit boundaries; extract a boundary when a real change needs it, not to satisfy arbitrary file length.
- Tests cover changed behavior and the reproduced failure. Do not weaken assertions to get a green run, overfit production logic to fixture seeds, or equate syntax parsing with Apple SDK validation.
- Every integrated source increment receives independent review, proportionate tests and an exact-head native run. Documentation-only updates need consistency checks, not unnecessary CI.
- Keep the existing immutable action pins, repository/public-main guard, one standard runner, bounded execution and short artifact retention. No widened permissions, security changes, paid runner or CI subscription.
- Preserve useful evidence before expiry through already authorized storage. Record source, timestamps, runtime, pass/fail counts, artifact hashes and actual inspection. A successful upload is not an inspected screenshot.

## Authority and blocking decisions

Existing authority covers bounded MVP source implementation, tests, review and public-repository integration within the established workflow. Execution must remain within the existing approved cumulative allowance, including applicable storage/fees. Standard public-runner compute has been documented as free, but no unlimited paid usage or verified account billing balance is inferred. Check cumulative exposure and stop before spending beyond the cap. Never alter visibility or use another route to evade a denial.

These require a specific decision or supported approval before the affected action: exceeding the budget; new paid assets/services; Apple membership purchase; Apple identity or production bundle selection when unresolved; signing credentials or expanded persistent access; user-device operation; tester invitations/build sharing; public listing/legal commitments; App Store submission; monetization or tracking; and any change to the frozen MVP scope. Independent source and simulator work continues while such a gate waits.

## Delivery cadence and stop rules

For each slice, record actual owner, exact input head, smallest next step, dependencies, acceptance criterion, review result and timestamped output evidence. Once accepted, assign the next eligible bounded slice automatically. If blocked, diagnose the smallest authorized unblock step; if it needs new authority, ask only for that decision and proceed on an independent lane.

Send the user meaningful completed progress, a material change, a genuine blocker or a needed decision. Do not require hourly nudges or send unchanged running-status updates. Stop the affected action after an actual denial or uncertain write; reconcile read-only evidence before any further permitted write. Retain all existing project-specific holds. This roadmap applies only to this repository.
