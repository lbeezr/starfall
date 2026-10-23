# Lantern mastery: one joint win, recovery still unproved

**Result:** Partially verified · **Owner:** Factory coordinator / Core and game design · **Date:** October 22–23, 2026 · [Research leaf #268](https://github.com/lbeezr/starfall/issues/268)

The proposed grown-star and survivor-chain goals both occur in the existing revision-4 Lantern winning route. Its **only chain is the opening action**. A genuine alternative consumes that opening opportunity, but the narrow continuation search found no later chain or alternate win. This does not establish impossibility or justify changing the supply.

**Next action:** Before promising recoverable mastery, construct a later-chain winning route after the named declined opening using state-aware legal planning rather than replaying coordinates from a different board. Then test missed-first-growth recovery, ordinary completion alternatives, winning-action qualification and the minimal ledger/enrollment contract. No tracker, rating, save, App or gameplay change ships here; [the proposed contract](../../design/STORY_MASTERY_CONTRACT.md) remains separate.

## What the production actions establish

Flat cell indices are `row × 7 + column`; action indices are zero-based and include showers (`[]`). [The witness](witness.json) retains all 97 actions and selected exact before/settled boards, identities, score and save results. The existing policy test already restores every action and compares committed receipts on both copies.

| Situation | Actual result | Limit |
| --- | --- | --- |
| Full unchanged Lantern route | 75 exchanges, 22 showers, 151,000 points, valid completed win. A occurs at actions 22, 36, 40, 51, 55, 57, 76, 85 and 91; B only at action 0. | Both goals occur in one win, in different transactions. This is one chosen route. |
| Opening `8 → 9` | Aqua IDs 0, 1, 7, 9 clear; rose survivors 2, 8, 15, 22 form the next phase. IDs 15 and 22 move; phase boards link, cleared identities differ and depths advance. Total 15,000. | A true same-transaction survivor chain, not simultaneous groups or a timed streak. |
| Independent next `0 → 1` | One all-small phase adds 5,000. | Neither new A nor B; earlier run accomplishments are distinct from this action. |
| Shower at action 6 | Grows ID 30; no recipe phase or points. | Growth alone does not collect it. |
| First grown collection, action 22 (`5 → 12`) | After six showers, 50,000 → 56,000; cleared IDs 30, 31, 42, 49 include grown ordinary ID 30. | Exact phase-before authority, not bonus size or appearance. |
| Genuine declined opening `1 → 2` | One 5,000-point phase consumes the original rose follow-up IDs 2, 8, 15, 22. They are absent afterward; save round trip is valid. | Irreversibly declines B. The all-small opening has no A opportunity to decline. |
| Winning action 96 (`11 → 12`) | 146,000 → 151,000. Further exchange/shower is rejected without mutation. | No extra post-win action. This winning action itself earns neither goal; goal-bearing winning-transaction cases remain future acceptance. |

Two fixture-bound regressions reuse the existing plan in [StoryFourStarLinePolicyTests](../../../Tests/StarfallCoreTests/StoryFourStarLinePolicyTests.swift). They also establish physical-light surplus equivalence **on this valid all-colored automatic route**, not a general ledger, historical-save or enrollment proof.

## The alternative search was deliberately narrow

[Search receipts and literal paths](search.json) contain **256 attempts but only 74 distinct committed action paths**; one path repeats 173 times because later perturbations are never reached before loss. All attempts begin with `1 → 2`, then reuse the old route while omitting one action, inserting a shower or inserting one deterministic legal exchange. Illegal coordinate actions are skipped. Surviving the old endpoint would permit at most 16 further showers and four highest-award exchanges per shower.

The cap was 256 attempts or 180 seconds. It exhausted attempts in **0.149 seconds**; a path-identity instrumentation rerun took **0.169 seconds** and reproduced the outcomes. All lost by shower 10; best 22,000, 251 attempts collected growth and none produced B. This is weak negative evidence from one plan-reuse family, not 256 independent policies, a general solver or a ten-minute search. Repeating it unchanged is not a useful next task.

## Verification and reproduction

Research baseline **`27252f6677f323d80206fe7837b59772dfcf4d2e`**; final integration uses **`fba8d11bb60caf0db8b5b8d0f2dfc0ebe5d26ad5`**, after the other coordinator merged #269. All 26 Core files and the final tested policy file remain byte-identical. Shared indexes preserve both independent entries; this research changes only that test and documentation/evidence. [Verification metadata](verification.json) binds all 26 unchanged Core Swift files, exact probe/input/test hashes, environment and bounded receipts. Xcode 27.1 (27A9275), Swift 6.4, macOS 27.0.1 arm64, Python 3.9.6.

| Check | Actual result |
| --- | --- |
| Worker focused `--filter StoryFourStarLine` | 13 passed, zero failures/skips, before three coordinator assertions were added. |
| Final full `swift test` | 241 passed, zero failures/skips; 43.308 seconds including build, 19.358 seconds test execution. |
| Generic arm64 Debug simulator build | Baseline passed in 21.728 seconds with 546 unchanged recorded inputs. After upstream #269, integrated build passed in 7.3 seconds. No simulator was booted. |
| Hygiene / whitespace / local links | Passed after explicit staging; 634 local targets across eight Markdown files. Markdown source reviewed; rendered-document inspection not run. |
| Hosted/UI, visuals, animation, actual VoiceOver, physical device/player study | Not run for this research: no production/native inputs changed by this slice; upstream #269 retains its own native acceptance. These Core witnesses establish feasibility only. VoiceOver remains deferred. |

The full Core command was:

```sh
python3 scripts/simulator-command.py --receipt /private/tmp/starfall-mastery-20261023/root-stages.jsonl mastery-core-full 240 swift test --scratch-path /private/tmp/starfall-mastery-20261023/root-tests
```

The simulator build used the same bounded runner (600-second cap):

```sh
xcodebuild -project Starfall.xcodeproj -scheme Starfall -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/starfall-mastery-20261023/DerivedData ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO build
```

The disposable [probe](probe.swift) is retained for this research, not as an app feature or reusable solver. It expects `/private/tmp/starfall-mastery-20261023/golden-actions.json` (copy the [retained input](golden-actions.json)). Compile unchanged `Sources/StarfallCore/*.swift` as a `StarfallCore` module and the probe as a dependent executable, using a scratch Swift package; execute through `simulator-command.py` with a 200-second outer bound. Its fixed output directory is disposable. The retained tests independently reproduce the positive and declined-opening assertions without the probe. Raw all-action output, logs and build products remain in that temporary directory.

Initial scratch builds failed on a module-cache denial, then a temporary closure-shadowing compilation error, followed by sandbox-denied DSYM generation after successful linking. Those nonzero builds remain failures in the receipts; the linked probe executions and passing Debug tests are separate results. The coordinator subsequently built the exact final harness in Release with normal compiler access: passed in 9.715 seconds, then its bounded execution reproduced the same 256 attempts / 74 paths, 22,000 best and no joint alternative. Its successful result is recorded separately. No assertion or game rule was weakened.

No conclusion about human timing, understandability, enjoyment, mastery motivation, Ribbon, retained-history ratings or crash-safe persistence follows from these routes. The ordinary repairs, historical saves and current game remain unchanged.
