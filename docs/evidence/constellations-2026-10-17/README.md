# Diagonal clears merit a native comprehension comparison

**Result:** Partially verified · **Owner:** current implementer · **Date:** 2026-10-17

Extend the offline candidate to a bounded native comparison; do not adopt it. The reported five-pink-star relationship is rejected by ordinary matching and cleared by the candidate. On identical sampled boards, diagonal eligibility restores useful opportunities but sometimes merges independent ordinary choices. Longer simulated survival does not establish player preference or comprehension.

**Next action:** agree five actual stars versus five starlight and whole-component precedence with the player, then prepare separately saved native baseline/candidate exports. Ask the learner to predict clears, darkness and settling before tapping. Adopt/remove after that comparison, or document one bounded remaining question. No native route was added in this batch.

## Outcomes against acceptance

See the [criteria written before implementation](../../design/CONSTELLATION_TRIAL.md). The runner and fixtures remain offline under `tools/mechanics`; they compile temporary copies and delete them afterward. Production rules, RNG/schema, app files and normal saves are untouched. The phone was neither accessed nor reset; no phone screenshot was retained.

| Criterion | Result | Limit |
| --- | --- | --- |
| Branching five-star example, all five tap origins | Pass | Contrasting support makes a settled fixture; surrounding phone board is unknown |
| Four grown diagonal stars, ordinary grown pair, grown five-star score | Pass | Eligibility counts actual stars; score retains growth |
| Orthogonal dark removal and diagonal dark exclusion | Pass | Existing growth shading implementation unchanged |
| Edge bounds, overlap, invalid and terminal input | Pass | Whole-component precedence prevents tap-origin ambiguity but removes subset clears |
| Single settling, survivor identity/order, preview/RNG preservation | Pass | Fixture verifies every column and unchanged encoded generator fields |
| Generated committed-save validation and restore | Pass | All sampled commits validated; clears round-trip; fixture continuation replay matches |
| Existing package tests / simulator build | Pass | 61 tests; Debug app build only, unchanged production source |
| Comprehension, native input/interruption, full/reduced motion, actual VoiceOver, human/device play | Not run | Offline candidate has no UI; no gameplay-quality claim |
| Separate native saves | Not applicable yet | No app route or persistent writes; mandatory distinct bundle/suite for next native trial |

## Matched boards show both opportunity and lost choices

The candidate core also exposes the unchanged ordinary clear solely for comparison. Traverse seeds 0–199 for at most sixty showers, clearing the first ordinary group once after each shower. At each nonterminal board, evaluate both rules before any candidate action. This isolates move availability from different trajectories.

Of **5,043 identical boards**, **268** gain a clear where the baseline has none; **294** gain a second choice; **30** lose a second choice. **38** states contain a constellation merging multiple ordinary groups. There are **1,105** new or expanded candidate groups; expanded groups are not automatically independent additional choices. Choices mean distinct resulting tap groups, not measured strategic quality.

## Matched seeds describe different trajectories

Both modes use the existing six-policy sampler, 200 seeds and sixty-shower cap. Each starts from the same seeds; after different clears, board-dependent relief may produce different future skies. The candidate deliberately retains **orthogonal availability** as the generator's relief predicate. Replacing that predicate with constellation availability would confound the experiment with a generation change. Clear actions preserve the already announced preview and RNG.

The table reports baseline → candidate. Dry share excludes terminal overflow showers; survival includes them. Surviving capped rounds are censored, not completed rounds.

| Policy | Dry share | States with 2+ choices / decision states | Mean showers observed | Capped survivors / 200 | Consequential choice states |
| --- | --- | --- | --- | --- | --- |
| Clear all | 43.0% → 41.8% | 215/3224 → 327/4641 | 26.45 → 35.67 | 0 → 15 | 7 → 7 |
| First group | 39.8% → 37.5% | 292/3038 → 419/4123 | 26.22 → 33.93 | 0 → 10 | 11 → 14 |
| Largest value | 39.8% → 37.6% | 287/3029 → 413/4097 | 26.15 → 33.80 | 0 → 8 | 11 → 13 |
| Lowest column pressure | 39.5% → 37.6% | 300/3099 → 410/4122 | 26.63 → 33.97 | 0 → 10 | 10 → 9 |
| Preview-aware | 39.5% → 37.6% | 300/3099 → 410/4122 | 26.63 → 33.97 | 0 → 10 | 10 → 9 |
| Idle | 0% → 0% | No decisions | 19.68 → 19.68 | 0 → 0 | No decisions |

Longest dry streak remains **one shower** in every active policy. Absolute dry counts rise because rounds last longer; the smaller dry fractions are the appropriate comparison. Idle retains its opening match until overflow, explaining zero dry boards without useful play. Pressure and preview-aware policies happen to choose identically in this sample; preview-aware sees hidden landing columns and is an upper-bound diagnostic. Consequential choices distinguish immediate overflow through the announced shower; they do not establish long-term strategy. Bots clear immediately and may underexpose deliberate waiting opportunities.

## Context and recommendation

The existing generation research already addresses sparse choices through cohesive showers, relief and isolated paired/pressure/Surge candidates. Historical `gameplay-study/results-2026-10-16` concerns the original 18-move jewel puzzle and is not falling-sky evidence. The shower samplers use a frozen older source; this trial instead uses current `1583e76`, so their numerical results are not a controlled cross-mechanic comparison. No combined shower/constellation rule was tested.

Ordinary orthogonal clearing is functioning as designed: the report exposes a mismatch between visual grouping and eligibility, rather than a proven input bug. Eight-neighbor same-family components address that mismatch at the core grouping boundary. Inspecting `FallingSky.group`, `legalGroups`, `clear`, darkness, settling and `nextShower` found the generator dependency that must remain separate. UI/store/scene integration has not been implemented or audited as a constellation feature.

Prefer a tap-only native comparison. Thin eligible-component links and spoken count/value could explain the grouping without tracing, but remain a proposed presentation. Four grown diagonal stars worth eight starlight still fail the five-star threshold: this is the strongest likely learning cost. Whole-component precedence also removes smaller orthogonal alternatives. Test those counterexamples explicitly before accepting the rule.

## Verification context

Source: `1583e7601ba3e6f1d5ac5d9659310ab6a826d77c`; initial checkout clean. Only new offline tooling and documentation differ. [Machine summary](summary.json) records input hashes and aggregate counts. This is working-tree evidence, not acceptance of a published integration commit.

Environment: Xcode 27.1 (27A9275), Apple Swift 6.4, arm64 macOS; Debug build destination iPhone 17e Simulator / iOS 27.0, `4103C352-DFC2-493E-A224-DE4CE3D50889`.

Commands:

```sh
python3 tools/mechanics/compare-constellations.py > artifacts/constellations/comparison.json
swift test > artifacts/constellations/swift-test.log 2>&1
xcodebuild -project Starfall.xcodeproj -scheme Starfall -configuration Debug -destination 'platform=iOS Simulator,id=4103C352-DFC2-493E-A224-DE4CE3D50889' -derivedDataPath /tmp/starfall-constellation-build ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO build
python3 scripts/ci-hygiene.py
git diff --check
```

Raw logs are ignored under `artifacts/constellations`. An intermediate check incorrectly compared dictionary descriptions for RNG preservation; dictionary ordering triggered a failure. Structural equality replaced that assertion; final rerun passes. No rule assertion was weakened. No new app target membership exists: candidate source is intentionally compiled only by the runner. Release, hosted/UI execution, screenshots, animations and VoiceOver were not run because shipping app sources/routing/resources are unchanged. Markdown rendering was not checked; local links were checked.
