# Optional Story mastery and replay records

**Status:** Implemented bounded Lantern slice; integrated verification is recorded separately · **Owner:** Core qualification and App persistence/presentation owners below · **Updated:** October 23, 2026 · **Implementation:** [#312](https://github.com/lbeezr/starfall/issues/312) · **Original design:** [#253](https://github.com/lbeezr/starfall/issues/253)

Every earned repair remains a complete success. New Lantern visits disclose two optional accomplishments, then award one to three stars from one completed run. Falling Sky and Full Board have different goals and independent best records. Mastery never gates repairs, access or the next destination.

The implemented slice preserves gameplay definitions, RNG, supply, scoring and targets. It adds explicit enrollment, qualification from the validated ledger, v19 round saves and a separate whole-run best store. [Goal 9 evidence](../evidence/depth-goal-09-optional-mastery-2026-10-23/README.md) owns integration status and executed checks. The 235-action mechanical comparison establishes qualification and replay equivalence; it does not establish human understanding, enjoyment or every rank's natural reachability.

**Next decision:** At the next bounded Lantern player observation, assess whether the goals are understood and optional replay feels worthwhile. Keep, revise with an explicit new identity, or remove the slice before extending mastery across the map. Missing recovery witnesses remain development limits.

## What the player earns

Entry names the restoration objective and selected mode's optional goals before Begin. The pause menu shows current progress; the result shows this completed run and the best whole run for the same contract. Lantern's Map/Places card keeps the two mode records separate. Restoration remains the main gameplay measure.

| Completed run | Result | Consequence |
| --- | --- | --- |
| Neither goal | ★ | Full repair, normal ending and ordinary access. |
| Either goal | ★★ | The same repair, with one optional accomplishment. |
| Both goals | ★★★ | Both were earned in this one successful run. |
| Still playing or lost | No completed-run rating | Prior best and repairs remain intact. |

One star is success. Stars add no currency, XP, speed requirement, gesture limit, no-pause rule or score-overshoot requirement. No surplus action is available after a win to finish a goal. Historical repairs receive no invented rating for a newer contract.

The direction originated in the [Story gameplay plan](../STORY_MODE_GAMEPLAY_PLAN.md#three-stars-reward-accomplishments). Its historical manual tap/trace examples do not define current goals. Player wording belongs in the existing dialogue/interface catalogue.

## Two exact contracts

`StoryMasteryIdentity` consists of challenge, content revision and goal-set revision. Only these two identities are supported:

| Location and mode | Content / goal-set revision | Optional goals |
| --- | --- | --- |
| Lantern Landing / Falling Sky | `firstLight` / 4 / 1 | Collect a grown star; make one clear lead into another. |
| Lantern Landing / Full Board | `firstLight` / 6 / 1 | Make one clear lead into another; clear at least eight actual stars in one phase. |

Both retain a 150,000-point restoration target. Retained Lantern Full Board5 and Lantern0–3 are completion-only. An existing unenrolled Lantern4 or Lantern6 round also remains completion-only, including on same-round Replay. Availability alone cannot enroll a saved attempt.

Other locations have no mastery contract in this slice. Current new-visit objectives remain distinct: Ribbon Sky4/Full Board7 uses 220,000; Kite4 17,000; Seed4 11,000; Silver4 12,000; Frostfruit8 15,000; Sunwheel9 24,000. Historical revision-0 rounds retain their manual 18-light rules. Open Sky, disposable Tutorial practice and Debug review fixtures submit no mastery records.

A changed threshold, qualifying event meaning or goal list requires a new goal-set identity; incompatible gameplay needs its own content revision. Cosmetic wording does not change a predicate. Records under different identities are never combined. Any future variable scenario needs an explicit comparison identity before sharing records.

## Qualification comes from committed rules

[StoryMastery](../../Sources/StarfallCore/StoryMastery.swift) defines the contracts and winning proof. [StoryScoreLedger](../../Sources/StarfallCore/StoryScore.swift) validates its bounded receipts before deriving goals. No UI flag, scene node, animation callback or displayed bonus awards mastery.

| Goal | Committed predicate | Does not qualify |
| --- | --- | --- |
| `grownCollection`, Sky4 only | A collected ordinary ingredient was grown before its automatic clear. Under this exact definition, collected physical light exceeds the ledger's distinct actual-star count. | Growing, moving or inspecting without collection; size or chain bonus alone. |
| `cascade`, both contracts | One action resolves a nonempty automatic phase after depth one, recorded in an earned causal tier. | Separate single-phase actions; simultaneous recipes in one phase; App relay feedback. |
| `largeClear`, Full Board6 only | One automatic phase clears a union of at least eight distinct actual stars. | Physical light from fewer grown stars; totals across phases; a large point award alone. |

Falling Sky's later phase follows surviving stars settling after the preceding clear. Full Board can also create later phases through ordinary committed refill. Its goal acknowledges that actual clear/refill consequence; it does not promise that all ingredients were visible before the exchange or that the player predicted the supply. Full Board has no grown ingredients, so grown collection is not offered there.

Legal exchanges and fully landed showers use Core's resolution authority. Scheduled and manually advanced showers qualify identically where showers exist. Pausing and presentation policy do not change them. Overlapping recipes spend their union once. An overflowing shower that skips automatic resolution earns no new recipe goal.

The complete winning transaction counts, including later phases after an earlier phase crossed the target. Core resolves it normally, then produces the completed record. Terminal input stays locked; there is no post-win move or extra shower.

## Enrollment and same-round replay

`FallingSky.enrollMastery(runID:)` accepts an explicit UUID only on a valid, pristine supported opening with no existing enrollment. Normal App Begin enrolls an explicit new Lantern visit. Preview, map browsing and cancellation change neither the round nor records. App practice and Debug persistence boundaries exclude disposable runs.

Continue preserves the exact identity, attempt UUID and ledger. Pure `replay()` reconstructs the opening and retains the enrollment marker for preview without creating an attempt. Committed Replay/Retry uses `replay(masteryRunID:)`: it retains an enrolled contract, supplies a new UUID and resets the ledger. If enrollment was absent, it stays absent through either API. Only an explicit supported New visit can enroll that old round's replacement.

Sky4 and Full Board6 retain their openings, previews, supply, target and rules. This feature changes neither `StoryChallengeDefinition.currentRevision` nor any gameplay/RNG revision.

## One whole winning proof owns the best

`StoryMasteryRecord` stores a bounded, valid enrolled winning `FallingSky` as its proof under the encoded `game` field. Identity, attempt UUID, goals and rank derive from that immutable proof. Rank is `1 + earned.count`, bounded to one through three; separately encoded rank or goal flags have no authority. Playing, lost, unenrolled and invalid rounds cannot construct a record.

[StoryMasteryStore](../../App/StoryMasteryStore.swift) retains one record per supported identity, two records total. A higher rank replaces the whole record. Equal and lower ranks keep the first valid best. A later two-star run can display its own different accomplishment without changing that best: A-only followed by B-only remains two stars. Duplicate projection is harmless. Repairs and access stay in the independent WorldJourney v1 envelope.

This is local semantic validation under the existing bounded ledger/save invariants, not a replay-log or anti-cheat guarantee. Invariant-valid aggregate fixtures prove rank and persistence semantics; they do not establish a natural production route for every goal combination.

## Save format, recovery and rejection

| Owner | Implemented responsibility |
| --- | --- |
| [FallingSky](../../Sources/StarfallCore/FallingSky.swift), [StoryScoreLedger](../../Sources/StarfallCore/StoryScore.swift), [StoryMastery](../../Sources/StarfallCore/StoryMastery.swift) | Validate exact enrollment, derive qualification, reconstruct replay and authorize completed proof. No event log or saved goal flags. |
| [SkySaveArchive](../../App/SkySaveArchive.swift) | Write `starfall.accumulation.v19`; retain validated v3–v18 readers and original bytes. Every pre-v19 reader requires absent enrollment, including eligible Sky4/Full6 content. Present invalid newer archives never fall back. |
| [FallingSkyStore](../../App/FallingSkyStore.swift) | Save the committed round first; independently project repair and best afterward. Exclude practice/Debug records and retain a winner until best persistence succeeds. |
| [StoryMasteryStore](../../App/StoryMasteryStore.swift) | Write `starfall.mastery.v1`, validating at most two unique whole records. Preserve rejected prior values in `starfall.mastery.rejected` when replacing them. |
| [WorldJourneyStore](../../App/WorldJourneyStore.swift) / [WorldJourney](../../Sources/StarfallCore/WorldJourney.swift) | Preserve valid-win repair/unlock semantics independently and recover from a durable winning round. |
| [SkyMasterySnapshot / SkyMasteryView](../../App/SkyMasteryView.swift) | Present exact-contract Entry, progress, result and map-best values through existing owners. No qualification or persistence capability. |

Missing enrollment decodes as absent. Mismatched content/location/goal-set enrollment or a malformed UUID invalidates the round claim; the archive rejects and preserves the envelope under its existing policy. It does not strip malformed metadata and resume guessed completion-only play. A bad separate best envelope cannot invalidate an otherwise valid round or remove an earned repair.

If the round write fails, neither best nor repair projects from that unsaved win. If optional-best persistence fails after the round saves, repair projection still runs. The durable winning round remains the bounded retry receipt; Replay/New visit cannot discard it until the optional write succeeds. Initialization is read-only: it can reconstruct an outstanding best in memory from a valid saved winner, while activation/commit owns durable retry. The existing persistence notice explains failure without claiming that the best was saved.

Backgrounding during animation restores committed Core state. Duplicate callbacks add no goals or records. Entry cancellation, lower/equal/better replay, practice exclusions and interrupted independent writes are covered by the [Goal 9 integration record](../evidence/depth-goal-09-optional-mastery-2026-10-23/README.md), which separates Core, hosted, native and visual results.

## What is proved and what remains open

[StoryMasteryTests](../../Tests/StarfallCoreTests/StoryMasteryTests.swift) compares ledger qualification with actual committed phase predicates after **235 production actions across five fixed routes**, including per-action Codable/RNG/control-round equality. It covers rejected contracts, absent legacy replay, whole-record rank combinations, final-action qualification and independent Full Board goals.

| Witness | Established consequence | Limit |
| --- | --- | --- |
| [Historical Sky4 joint route](../evidence/story-mastery-feasibility-2026-10-22/README.md) | A real 151,000-point win earns grown collection and cascade. | Determinism does not prove understandable or enjoyable play. |
| [Sky4 later-chain recovery](../evidence/story-mastery-recovery-2026-10-23/README.md) | A real 150,000-point win earns both after irreversibly declining the opening chain; its winning action collects a grown star. | Recovery after missing the first grown opportunity remains unproved. |
| Full6 HIGH10 route | A real 156,000-point win earns both goals. Final-action phases clear 10, 8 and 4 actual stars; the eight-star threshold first qualifies in that winning transaction. | Refill consequences do not prove deliberate supply prediction. |
| Full6 LINE21 route | A real 150,000-point win earns cascade only, with no phase reaching eight stars. | A natural Full Board large-clear-only win is not established. |
| Labeled invariant-valid aggregate proof fixtures | Neither/A-only/B-only/both ranks, strict proof decoding, no union and whole-best replacement. | Accounting proofs are not authored histories. Natural one-star and Sky grown-only/cascade-only wins are not established. |

The earlier [four-star-line trial](../evidence/four-star-lines-2026-10-22/README.md) and [resolver tests](../../Tests/StarfallCoreTests/StoryFourStarLineTests.swift) retain their original scope. The original design was inspected at `93ae893a` with runtime baseline `c9763dc5`; those records remain historical. Goal 9 implements the selected mode-appropriate slice on unchanged later content, with current integration evidence above.

The original proposal treated every missed-opening and completion-only contrast as a runtime prerequisite. This bounded slice records missing natural-route cases explicitly while proving qualification, complete joint wins, a real Full Board two-star contrast and historical Sky later-chain recovery. A Full Board route that merely delays an opening is not proof of irreversible missed-opportunity recovery. No supply rewrite, target increase, withheld reward or minimum turn count fills those gaps. Do not claim all ranks are naturally available or extend goals to other places without their own witnesses.

Human comprehension, recovery comfort, optional replay motivation, actual VoiceOver and physical-device acceptance remain separate from deterministic/native automation. At the next Lantern comparison, observe those questions and revisit goal meanings before expansion. A missed optional goal must never turn a repaired place into failure or reduce access.
