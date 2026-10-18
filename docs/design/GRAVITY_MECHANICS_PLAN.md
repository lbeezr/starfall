# Prove a controllable magnetic collision and orbit

**Status:** Isolated implementation; adoption review pending · **Owner:** current implementer · **Updated:** 2026-10-17

Build one isolated, deterministic comparison of magnetic precursors forming a temporary hole. Keep production Dusk intact, white independent, and ordinary tap play as the initial baseline. The [design](GRAVITY_MECHANICS.md) selects occupied capture positions and explicit support gravity; comprehension of that gravity is the principal adoption risk.

**Next action:** compare the playable fixtures with the user: predict the next movement, choose trigger/keep/close and explain the result. Keep natural spawning and production adoption deferred. [Implementation evidence](../evidence/gravity-orbit-2026-10-17/README.md) records source-bound checks; human preference remains unverified.

## Scope and success

**Includes:** a horizontal clear-triggered collision, one hole, up to four occupied captive positions, three settled matching windows, captive-clear/expiry release, support-based settling, explicit lab identity/save contracts, committed animation phases and a bounded native comparison.

**Excludes:** natural magnetic/hole spawning, blast damage, chains, polarity, white integration, changed Dusk severity/cadence, First Light changes, progression, SDKs, network/ranking delivery, a second gameplay clock and production save migration. Compare Dusk suppression versus occupancy only in its own later batch if still useful.

- [ ] A floor example demonstrates a visible beneficial setup; a counterexample demonstrates a reason to avoid/delay collision.
- [ ] Captives provide usable changed connections without requiring taps on moving targets; all edge/support/expiry outcomes are explicit.
- [ ] Ordinary behavior, RNG and retained saves remain reproducible; candidate saves remain isolated and validated.
- [ ] Human comparison establishes comprehension and a reason to replay, or the candidate is revised/removed with its limits recorded.

## Work in small batches

Batches 1–5 are implemented in the isolated export; current-main tracing is inherited rather than reconstructed from the parked trace tool. Batch 6 remains observed-player work. The table retains each batch’s acceptance boundary; executed results live in the evidence record.

All batches belong to the current implementer. Each is a separate reviewable integration unit; do not combine an unrelated white or tracing change to make a batch pass.

| Batch | Deliverable / affected boundaries | Done when |
| --- | --- | --- |
| 1. Prove the rule geometry | A pinned, Core-only export; strict canonical gravity patch; focused `OrbitField` / `GravityFieldRules` helpers and authored tests. Implement explicit special identity, collision precedence, formation settle/capture and support release. Production sources stay unchanged. | Floor two-captive example and trigger/defer branches are reproducible. Corner topology, elevated settling, zero/one captures, lower clears, ordinary growth, two/three/four-slot cycles, lifetime and overflow pass. Stop/revise if no useful choice survives the ordinary alternatives. |
| 2. Prove state ownership | Separate versioned lab envelope, independent entity allocation/material accounting, ordinary replay comparison and malformed-save tests. Record input hashes and commands. | Save after collision, each rotation, supported gap, expiry and terminal arrival restores exact continuation. Old ordinary-only states and previews reproduce the baseline; unknown versions/invalid topology reject. No production/default save or ranking sidecar changes. |
| 3. Coordinate atomic events | Ordered turn phases in the lab; store integration with the existing injected clock/presenter and generation guards. Fake-clock/presenter regressions. | State saves before animation. Rain due during a phase produces at most one subsequent shower; pause/background/restart/motion/fixture replacement reject old callbacks. Manual Next shower yields the same sequence. Lab ranking creation/delivery is disabled explicitly. |
| 4. Make one native fixture comparison | Export from the same selected runtime source using existing export infrastructure, separate bundle/defaults/test IDs and manifest. Add focused hole/magnet material and motion helpers, shared geometry cells, resting markers and cell semantics. | Debug and Release simulator builds include new sources. Normal-motion collision/orbit/closure is inspected, native floor taps and rapid input work, screenshots at normal/largest text remain readable, Reduce Motion preserves outcomes. Production and white apps/saves are untouched. No extra phone install unless the current single-lab convention permits replacement without losing its retained round. |
| 5. Check selected tracing deliberately | Compose the canonical trace candidate on the selected source only after batch 4; resolve strict patch conflicts explicitly. | A selected captive closes the field once; omitted captives retain IDs/value until release; new shower/orbit/layout/menu changes cancel the stale walk. Whole-group taps and selected traces have correctly previewed collision consequences. No white composition. |
| 6. Observe and decide | Matched fixture sessions and source-bound evidence. Compare two versus four windows only after the three-window reference is understood. | Players predict the next step and explain trigger/keep/close choices. Record successful window use, missed windows, forced waits, column headroom, confusion and replay preference. Adopt the bounded result, revise one named uncertainty or remove/defer it; update the experiment register. Natural spawning requires its own supply/orphan-lifetime plan. |

### Expected file ownership

Existing production rule/store/scene/view files remain the semantic owners; candidate changes are applied only inside a clean export. Store canonical trial inputs under `tools/mechanics/` using its existing export/hash conventions, with a single gravity patch and focused helper/test fragments. Proposed helpers are responsibilities, not a demand to introduce every filename immediately. SwiftPM automatically includes exported Core files; explicitly add exported app helpers and tests to the Xcode project, then inspect target membership. Do not append a large new subsystem to existing files merely to bypass membership work.

Reuse `FallingSky`'s generator, `FallingSkyRainScheduling`, `FallingSkyPresenting`, `ObservatoryGeometry`, shared theme and bounded materials. No copied RNG, generalized scheduler, separate game engine or parallel private coordinate map. The typed special identity is lab-local; agree a shared production contract with white only when combination/adoption is selected.

## Risk and verification

| Risk | Evidence required / response |
| --- | --- |
| Pinned support is difficult to understand | Ask players where a new star lands and what falls when the hole closes. If the prediction fails repeatedly, simplify to a one-time vortex or defer the orbit before natural spawning. |
| Floor collision has too few captives | Use survivors dropping into endpoint cells, then capture after formation settling. Verify legal arrival/clear history, not hand-edited save JSON. Fewer than two captives closes immediately; report how often this happens before supply tuning. |
| Pressure hides the matching window | Measure actual usable time after animation under the existing three-second default; a saved rules window is not automatically a comfortable interaction window. Compare slower orbit cadence/lifetime independently. Do not shorten full animation or force Reduce Motion to get green tests. |
| New identities leak into Dusk/white paths | Audit nil-kind classification, previews, labels, materials, growth, score/IDs and ranking. Fail closed on unknown candidate save versions; never write the normal save key. |
| Candidate layers drift | Pin baseline and transforms, fail mismatched anchors, retain hashes, replay exact candidate after composition. Exporting current HEAD does not prove compatibility with old white/trace pins. |

For source-changing batches run `swift test`, focused hosted/UI tests, a simulator build, `python3 scripts/ci-hygiene.py` and `git diff --check`; include Release when routing, resources, fixtures or project membership changes. Use bounded condition-based native waits. Record source/dirty paths, command, configuration, simulator/OS and results. Human/device acceptance and actual VoiceOver are separate from automation; follow the [development/RC cadence](../DEVELOPMENT_BUILDS.md#accessibility-checks-by-build-stage).

Before implementation, define focused acceptance fixtures for every item in the [design checklist](GRAVITY_MECHANICS.md#acceptance-and-decision). Round-trip/replay and interruption checks are mandatory for the new rule boundary, not substitutes for understanding or fun. Keep raw artifacts ignored and retain a concise report under `docs/evidence/` only after results exist.

## Status of this planning batch

Completed: code analysis, selected draft gravity/identity/event contract, phased plan and updated navigation/register. Existing package baseline: **63 tests passed** with Apple Swift 6.4, `swift test`, source `f35eba87311f5e9e56740b9677bceb699154e8ae`; dirty inputs are research/design/plan/register/navigation documents only. Runtime bytes were unchanged. Documentation hygiene, whitespace and relative file-link checks passed. Markdown source was reviewed; rendered Markdown was not inspected.

Not implemented or validated: new Core rules, candidate save schema, fixture simulation, app target membership/build, native input, animation, lifecycle behavior, accessibility, actual VoiceOver, device performance and player enjoyment. No simulator build was run for documentation-only work. Approval of a draft is distinct from these future verification gates.

Implementation follow-through: the export now uses published source `06ce514`, with the executed rule/native results and remaining human/device gates in the [evidence record](../evidence/gravity-orbit-2026-10-17/README.md). The planning-batch status above remains historical.
