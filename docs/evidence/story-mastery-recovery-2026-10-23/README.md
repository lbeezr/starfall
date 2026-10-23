# A later-chain Lantern win after declining the opening

**Result:** Verified Core witness · **Owner:** Factory coordinator / level design and Core testing · **Date:** October 23, 2026 · [Leaf #271](https://github.com/lbeezr/starfall/issues/271)

A real revision-4 Lantern route consumes the opening's rose follow-up directly, then earns grown collection and **five later survivor chains** before restoring the place. It wins at exactly **150,000 points after 73 exchanges and 15 showers**. The unchanged rules and supply therefore support recovery from this particular declined opening. This resolves the gap left by [the initial route audit](../story-mastery-feasibility-2026-10-22/README.md).

**Next action:** Reuse this route when developing the proposed [mastery qualification/save contract](../../design/STORY_MASTERY_CONTRACT.md). Missed-first-grown recovery, completion-only alternatives, full qualification/ledger equivalence, enrollment/persistence and native presentation remain separate acceptance. This witness does not implement ratings or establish human timing, comprehension or motivation.

## What was independently verified

[All 88 literal actions](actions.json) start from fresh current Lantern. Flat indices mean `row × 7 + column`; `[]` is one unchanged shower. The [independent replay](witness.json) derives goals from actual committed phases rather than planner flags and retains selected complete phase boards, cleared identities and scores.

| Boundary | Committed result |
| --- | --- |
| Action 0: `1 → 2` | One phase, 5,000 points, consumes the original follow-up IDs 2, 8, 15, 22. They never return during the run; subsequent moves cannot undo the declined opportunity. |
| First A, action 7: `14 → 15` | After one shower, collects ordinary grown ID 21. Growth is read in the recipe's own before board. |
| First later B, action 8: `0 → 7` | After one already committed shower, one transaction produces consecutive survivor phases, 11,000 → 27,000. Boards link; ingredient identities survive the earlier clear and actually move; the later recipe was absent before settling. |
| Later earning | A at actions 7, 8, 50, 69, 76, 77, 87. B at 8, 25, 61, 76, 77. These are zero-based action indices including showers. |
| Winning action 87: `2 → 9` | 140,000 → 150,000 and consumes grown ID 29 in the complete winning transaction. Further exchange/shower is rejected without state change; replay restores the original opening. |
| Every commitment | Legal production action; unchanged ordered forecast for exchanges and exact announced shower consumption; decoded pre-state replay yields equal final game, phase receipts and arrivals. Valid saved state, Codable equality, physical conservation and exact score increments hold. |

The compact [regression](../../../Tests/StarfallCoreTests/StoryMasteryRecoveryWitnessTests.swift) binds this route explicitly to content revision 4. Its maximum six exchanges between showers is an authoring constraint, not a new game rule. Automated planning and pausing do not supply a physical-player timing result.

## One bounded search, with exact coverage

The [frozen probe](Probe.swift) uses one deterministic layered beam: width 8, horizon 40 showers, at most six exchanges per shower including the forced prefix. Every depth considers non-scoring setup exchanges and the unchanged shower. Full sorted Codable game state plus A/B flags and exchanges since the last shower determine identity; all four cardinal directions are enumerated.

Ranking is points + 2,000·A + 8,000·laterB − 300·occupancy − 1,200·sum(max(0,columnHeight−4)²) + 180·partial-pattern potential. Potential gives 10 for three matching cells and 2 for two across square and four-cell line windows. Ties use score, fewer actions and lexicographic encoded actions. The full configuration and counters are in [search.json](search.json).

The declared bound was **100,000 successor evaluations or 180 monotonic seconds**. One run found the qualified win after **49,043 evaluations**, comprising 48,201 exchange and 842 shower calls. There were 22,949 unique successors, 26,094 duplicates, zero rejected calls and one winning successor. The fixed prefix commit is separate: 49,044 search/preparation Core calls in total. Search time was **3.590 seconds**; it stopped on success. There was no parameter retry or budget extension. Compilation, output tracing and independent validation are separate work.

Beam pruning limits completeness. It does not weaken an independently replayed positive route. The [earlier 74-path coordinate perturbation](../story-mastery-feasibility-2026-10-22/README.md) remains a historical narrow negative result; do not repeat it or treat it as impossibility.

## Source and reproducible checks

Research source **`8298d6cdd2698c62e3bc4197f9fc534b6eb9f81f`**; integrated main **`fc0867e51873d9efeb4003c4d0cfa4997f957365`** includes the other coordinator's Ribbon wording and sensory acceptance. Final integration also includes `f65a9ecfce13d20441b113d8090e07c48741ad9c` (#274's independent safe-return acceptance). All 26 Core Swift files, the tested recovery file and compiled App/configuration/project inputs remain byte-identical across that integration; checks are not repeated without an input change. This slice adds only the version-bound test and documentation/evidence. [Verification metadata](verification.json) binds source, hashes and bounded receipts.

Environment: macOS 27.0.1 arm64, Xcode 27.1 (27A9275), Swift 6.4, Python 3.9.6. The direct optimized probe and independent validator compiled successfully; the validator then replayed the winner in 0.191 seconds. All source inspection and execution is local; no phone, save reset or simulator boot occurs.

The probe is disposable evidence, outside app/package membership. To reproduce at matching Core hashes, create `/private/tmp/starfall-mastery-recovery-20261023`, compile the retained probe with the actual unchanged Core files, and run it through the existing bounded owner:

```sh
swiftc -O -parse-as-library Sources/StarfallCore/*.swift docs/evidence/story-mastery-recovery-2026-10-23/Probe.swift -o /private/tmp/starfall-mastery-recovery-20261023/Probe
python3 scripts/simulator-command.py recovery-search 210 /private/tmp/starfall-mastery-recovery-20261023/Probe
```

The 210-second process bound includes output serialization; the probe itself stops discovery at 180 seconds. Replay the retained route independently:

```sh
swiftc -O -parse-as-library Sources/StarfallCore/*.swift docs/evidence/story-mastery-recovery-2026-10-23/validate.swift -o /private/tmp/starfall-mastery-recovery-20261023/Validate
python3 scripts/simulator-command.py recovery-independent 60 /private/tmp/starfall-mastery-recovery-20261023/Validate docs/evidence/story-mastery-recovery-2026-10-23/actions.json /private/tmp/starfall-mastery-recovery-20261023/validation.json --require-win
```

Full `swift test` passes **242 tests, zero failures/skips**, in 34.937 seconds including build (21.002 seconds execution). The integrated arm64 Debug simulator build passes in **22.28 seconds**, with signing disabled and no simulator boot. Exact commands and bounded receipts are retained in verification metadata. Hygiene/diff and local links are checked after staging; Markdown source is reviewed and rendered-document inspection is not run. Hosted/UI, visual, animation, physical-player and actual VoiceOver checks are not run for this test/evidence-only slice. Upstream native changes retain their own acceptance; VoiceOver remains deferred. Raw search frontiers, traces, compiler output and build products remain disposable under the named temporary directory.
