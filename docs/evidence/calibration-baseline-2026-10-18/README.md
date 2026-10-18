# Free exchanges are the first calibration question

**Result:** Partially verified · **Owner:** current implementer · **Date:** October 18, 2026

Hold the mechanics steady. A visible-reward setup policy survives substantially longer than clearing alone in both sampled seed cohorts. At the 240-shower cap, clear-only ends **119/128** rounds; allowing one improving horizontal exchange per shower ends **9/128**. The other setup rounds remain censored: this does not establish endless play, optimal play, human execution or enjoyment. Do not add a cost, counter or new mechanic from these scores alone.

**Next action:** Play the integrated gesture/Dusk refinement once available, comparing natural clear-first and setup-first rounds under automatic showers. Observe whether setups are discoverable and rewarding or repetitive. Native interaction is presently blocked by Simulator automation/capture stalls; no successful touch or motion acceptance is claimed for this pass. [Calibration plan](../../design/CALIBRATION.md).

## What the sample says

Production Core is unchanged. Four policies maximize immediate visible collectible reward with stable cell-mask ties. All can tap and trace full valid components. Recipe policies also consider exact squares/crosses; setup policies can first make **one** horizontal exchange, only if it strictly improves the best immediate reward. The all-clear variant then spends all available greedy clears. No forecast, optimal subset search, repeated exchange chain, reaction-time model or clock/presentation gates enter these policies.

| Policy | Seeds 0–63: ended / observed median showers | Fresh seeds 64–127: ended / observed median showers |
| --- | --- | --- |
| Clear one | 58/64 · 108 | 61/64 · 95 |
| Recipe-aware, one clear | 58/64 · 108 | 62/64 · 93.5 |
| One useful exchange, one clear | 1/64 · **at least 240** | 8/64 · **at least 240** |
| One useful exchange, all clears | 5/64 · **at least 240** | 8/64 · **at least 240** |

Each row is a separate replay, not an identical arrival stream after actions diverge. Clearing can change relief generation. More greedy clears do not guarantee better survival. Censored samples cannot supply a completed-round median; 240 is the observation bound. Shower counts are not measured minutes.

The setup-one policies use 6,113 and 5,692 exchanges, respectively. Recipe-aware one-clear policies spend only two and one recipe-specific selections; ordinary tap-equivalent outcomes are deduplicated. That low count reflects a largest-immediate-reward policy, not proof that trimming/relays are useless. Partial selections, survival-oriented exchanges, zero-point rescues and longer planning are not optimized. No sampled nonterminal no-clear stretch exceeds one shower; that metric is measured after optional setup, not time spent waiting for usable input.

**Interpretation:** Free setup can strongly reduce pressure for a capable policy. Native play must establish whether a person can find/execute those moves during the current rhythm. Recipe discovery and useful preservation deserve observation before changing their reward. Preserve the current supply and save contract until those questions are answered.

## The measurement correction

The existing Opal study ranked actions using `value(of:)`. Feeding Dusk can make a legal three-light match collect zero, so the first current-rule run failed its commit/reward invariant. The study now uses Core's authoritative `reward(of:)`. A focused self-check commits every candidate in `DuskFixture.zeroClear`, verifies zero-reward legal matches exist, and preserves the source. The calibration path shares the existing action enumeration/commit boundary; historical Opal mode remains available with its original legacy-Dusk initialization.

This is a tool correction. App scoring, rules, RNG, save schema, cadence and gesture code are unchanged. The concurrent input/Dusk task owns shorter swap timing and five-feed Dusk; those unfinished changes are excluded from this baseline, which uses main's three-feed rule.

## Verification and source

**Source:** clean runtime at `11a16fc` (`origin/main` at branch creation); dirty paths are the two mechanics tools and new calibration documentation only. Source/tool hashes and exact commands are retained in [discovery provenance](final-discovery-source.json) and [confirmation provenance](final-held-out-source.json). Aggregate data: [discovery](final-discovery-summary.json), [confirmation](final-held-out-summary.json). Raw per-seed rows and logs: ignored `artifacts/calibration-current/`.

**Environment:** Apple Swift 6.4 / Xcode 27.1, arm64 macOS. Native target: iPhone 17 model, named Starfall Pacing Forecast Acceptance, iOS 27.0, `F4BA0D73-6491-4171-A29B-93ABC79EB4FF`.

| Check | Result and limit |
| --- | --- |
| Core | `swift test`: **147 passed**, zero failures. No app/Core changes in this batch. |
| Calibration | Two 64-seed cohorts × four policies × up to 240 showers; all sampled committed states validate and round-trip. Exact commands are in the linked manifests. |
| Reproduction | Both full 64-seed data files reproduce byte-for-byte after provenance-only tool changes. Two independent 2-seed/6-shower runs produce identical rows and summaries. |
| Historical study mode | Focused 2-seed/6-shower regression retained; topology, Opal, consumption and reward self-checks execute before sampling. |
| Debug simulator build | Current runtime `xcodebuild` build succeeds with scheme Starfall, `ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO`, DerivedData `/tmp/starfall-calibration-derived`. Build/run tool later times out installing on the initial simulator; build success is distinct. |
| Native launch | Built app installs and launches on the named QA simulator; runtime tree exposes Arrange and current dialogue. Native tap then times out; screenshot and mirrored frame never complete. No round, geometry, layout or animation acceptance follows. |
| Recovery | Scoped QA-simulator shutdown also stalls; no global simulator-service reset because other tasks are running. Pending installs/capture owned by this task were terminated and its mirror disconnected. QA simulator may require recovery before reuse. Phone installation/saves were untouched. |
| Rapid taps, win/loss/restart, background/resume, settings, Reduce Motion, largest text | **Not verified** in this pass. Earlier source-bound acceptance is not reattributed here. QA simulator reported Reduce Motion on; full-motion checks were not run. |
| Actual VoiceOver | Deferred to RC; not run on this development build. |
| Device/human | Not run. No preference or physical-feel conclusion. |
| Release | Not run; no app routing/build/resource changes. |
| Hygiene | `python3 scripts/ci-hygiene.py` and `git diff --check` pass. |

The checkout initially opened at an obsolete `f35eba8`. Its old tracing measurements/export repair were discarded from the change set after locating current main. They are excluded from every current result above; historical lab tooling remains retired.
