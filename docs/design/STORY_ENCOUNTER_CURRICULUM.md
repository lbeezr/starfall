# Give each ready place a different decision

**Status:** Curriculum retained; Kite prepared through #278; final native acceptance pending · **Owner:** Current implementer · **Updated:** October 23, 2026 UTC · [Design leaf #252](https://github.com/lbeezr/starfall/issues/252)

**Selected follow-through:** [#278](https://github.com/lbeezr/starfall/issues/278) now selects 17,000 points as the complete compact Kite4 encounter and implements the versioned normal-app route. The original authoring witness and its carrier limits below remain source-bound; [current development acceptance](../evidence/kite-headroom-2026-10-23/README.md) verifies both native finishes, ordinary-clock recovery and phone/tablet reading. Seed #279 and Silver #280 are separate complete runtime leaves.

Kite should ask whether to open useful room high in the sky or take a larger award below. The 24-star candidate below proves that distinction under the current four-star-line resolver, including recovery after choosing points first. It does not establish difficulty, enjoyment, input time or a new whole-location target. The versioned native comparison has earlier passes; a later clock repeat remains unresolved before merge; #279/#280 extend the next distinct encounters. Human recognition and comfort still need observation.

This develops the [current roadmap](../ROADMAP.md) and the decision themes in the [Story plan](../STORY_MODE_GAMEPLAY_PLAN.md). It uses existing materials, exchanges, automatic patterns, growth, settling and local progression. No new power, obstacle, timing gate, artwork family or multiplayer is proposed here.

## Seven places, seven questions

“Ready” describes existing location content. Only Lantern/Ribbon currently have authored automatic-pattern definitions; later places still use historical 18-light rules. These are proposed gameplay identities, not seven implemented encounters.

| Place | Current behavior | Proposed decision and smallest useful proof |
| --- | --- | --- |
| **Lantern Landing — recognize** | Revision 4: four-star lines/squares, five-star crosses, mixed five-family opening, 150,000-point goal. | See a near-pattern and choose an exchange that completes it. Preserve the welcoming first chapter. Reuse the existing first-pair witnesses and [#248's identity work](https://github.com/lbeezr/starfall/issues/248); do not create another Lantern rewrite. |
| **Ribbon Crossing — anticipate survivors** | Revision 4 shares Lantern's patterns but has a different 25-star opening, an initial three-phase opportunity, four-second showers and a 220,000-point goal. | Predict how one pop makes survivors fall into another pattern. #248 owns the playable contrast, alternatives and recovery; this curriculum adds no competing implementation. |
| **Kite Harbor — make room** | Ready artwork; historical seed-42, 18-light round. | A smaller high-column clear opens room; a wider low clear pays more immediately. Prove both against the same supply and recover after declining the opening space clear, as specified below. |
| **Seed Moon — preserve ingredients** | Ready artwork; historical rules. | Position a grown ingredient for a later pattern or spend it in an immediate one. One authored fork must leave different useful survivors, with another legitimate opportunity after a missed opening. Completed automatic patterns cannot wait for a tap. |
| **Silver Pools — choose the sequence** | Ready artwork; historical rules. | Complete a support pattern whose falling survivors offer a deeper cascade, or take a larger immediate clear elsewhere. One fork needs actual distinct phase/ingredient receipts and a simpler recovery route. No timed combo or water simulation. |
| **Frostfruit Orchard — recover and compress** | Ready artwork; historical rules. | Rebuild useful space after an untidy arrangement: make a modest clear now or arrange matching top ingredients so an ordinary arrival stores two light units in one cell. Witness both a recovery and the conditions where growth is unavailable; no automatic rescue or rewritten forecast. |
| **Sunwheel Mill — combine earlier skills** | Ready seventh place; historical rules. | Combine headroom, retained ingredients and a causal follow-up in one encounter, with a straightforward alternate finish. Prove the earlier lessons interact; a larger score bar alone is insufficient synthesis. |

Seed, Silver, Frostfruit and Sunwheel need their own witnessed briefs after this one. A reusable content route can follow a successful native Kite slice; it is not a reason to build a new runtime framework now. Human first-pair observations in [#206](https://github.com/lbeezr/starfall/issues/206) inform tuning, while this bounded design can proceed independently. Optional mastery belongs to [#253](https://github.com/lbeezr/starfall/issues/253).

## One Kite encounter: high room or low points

**Experience hypothesis:** visible uneven heights make a smaller award useful, while the points-first route remains recoverable and can preserve a grown ingredient. These consequences are proved below; their appeal is unmeasured.

**Version proposal:** a future explicit new visit may select a Kite-specific authored definition using the current revision-4 pattern policy. Freeze its own opening, supply, objective and identity; do not make Kite accept every Lantern/Ribbon historical revision. Today's `StoryChallengeDefinition(.kiteHarbor, revision: 4)` returns `nil`. Missing Kite revision markers, existing saves, Continue and same-round Replay must keep the original 18-light definition. Lantern/Ribbon revisions 1–4 must remain unchanged.

The candidate opening uses 24 ordinary, nongrown stars. Rows increase upward from zero; columns increase left to right. `A` aqua, `R` rose, `V` violet, `M` mint, `Y` amber, `.` empty. Assign IDs 0–23 by increasing row, then column, skipping empty cells.

```text
       columns 0123456
row 6          .......
row 5          VR.....
row 4          MY.....
row 3          AM.....
row 2          RAVR...
row 1          ARMYAMY
row 0          AVAARAA
```

Initial heights are `[6,6,3,3,2,2,2]`. There is no completed pattern, free opening pop or manual-clear action. The two near-patterns are visible before any shower:

| Plan | First exchange | Actual automatic consequence | Heights after settling |
| --- | --- | --- | --- |
| **Space first** | `(2,1) → (2,0)` | One depth-1 vertical aqua line; consumes IDs `0,7,15,18`, four light, **5,000 points**. Mint/violet IDs `20,22` survive and fall to the bottom of column 0. | `[2,6,3,3,2,2,2]` |
| **Points first** | `(0,4) → (1,4)` | One depth-1 horizontal aqua line across columns 2–6; consumes IDs `2,3,5,6,11`, five light, **7,000 points**. Rose ID `4` falls to `(0,4)`. | `[6,6,2,2,1,1,1]` |

Every listed clear happens automatically inside its exchange. Separate actions reset causal depth; these are not a two-phase cascade. The first choice changes actual survivor identities, occupied cells and points, rather than only the name of a move.

### Fixed development and recovery

For this comparison, freeze the existing Lantern revision-4 seed-42 supply stream and gentle six-second cadence as candidate inputs. Do not retarget the supply to either board. The first two ordered showers are:

| Shower | Ordered materials and receiving columns, for authoring/reproduction only |
| --- | --- |
| 1, incoming IDs 0–4 | `A@5, Y@0, A@1, M@3, R@4` |
| 2, incoming IDs 5–9 | `Y@2, V@6, V@5, R@0, M@1` |

The current compact forecast communicates ordered materials, not reliable receiving-column placement. The player is asked to respond to visible heights, not predict these exact columns. Both plans admit all five first-shower arrivals without overflow or another automatic clear:

| After shower 1 | Score | Heights | Relevant consequence |
| --- | ---: | --- | --- |
| Space first | 5,000 | `[3,7,3,4,3,3,2]` | Column 0 retains four vacant cells; column 1 is visibly full. All five arrivals occupy new cells. |
| Points first | 7,000 | `[7,7,2,3,1,2,1]` | Both high columns are full. The arriving rose grows surviving ID `4` in column 4 instead of occupying another cell. |

Now take the missed opening exchange: space-first uses `(0,4) → (1,4)` for 7,000; points-first uses `(2,1) → (2,0)` for 5,000. Each is a single depth-1 line phase. Both reach 12,000 points and open column 0. Column 1 is still full: these two clears alone do **not** establish sustained safety.

Both branches then have the same legal five-exchange recovery:

1. `(5,1) → (4,1)` brings the high rose down one cell.
2. `(4,1) → (3,1)` makes three consecutive roses above the bottom violet.
3. `(0,4) → (0,3)` moves the bottom rose toward that column.
4. `(0,3) → (0,2)` continues it left.
5. `(0,2) → (0,1)` completes the four-star vertical rose line.

The first four exchanges earn zero and produce no phase. The last consumes IDs `4,8,14,23` in phase index 0, depth 1, and reduces column 1 from seven occupied cells to three. Space-first collects four light for 5,000, reaching **17,000** with heights `[3,3,2,3,2,2,1]`. Points-first collects five light because ID `4` is grown, earning 6,000 and reaching **18,000**, with heights `[3,3,2,3,1,2,1]`.

**Encounter finish beat:** a player has completed the two opening patterns and resolved the remaining crowded column, with different light/space outcomes. The 17,000-point boundary is a useful bounded native comparison marker, **not a selected whole-Kite objective**. A future runtime leaf must explicitly choose and version the full-round target and any later authored content; this design does not adopt the older speculative 300,000 target. Do not require the shower or these exact actions: a skilled player may clear earlier, and other valid solutions remain legal.

As a recovery stress check only, the 150,000-target Lantern carrier also admits all five second-shower arrivals after those moves: heights become `[4,4,3,3,2,3,2]` and `[4,4,3,3,1,3,2]`, respectively, with no pop or overflow. This does not authorize an extra shower after a live round has earned its finish.

The five setup exchanges are a visible cost, particularly given the user's setup-effort feedback. Source proof does not establish that they fit a comfortable unpaused input window. Pause/explicit Next shower remain ordinary player choices. If native or player observation finds the recovery laborious, revise the opening/recovery, rather than adding a hidden rescue, forecast requirement or mandatory delay.

## Witness and limits

Executed on unchanged Core at `93ae893a034ab30e48d3cf55d306d7d1567150f4`, October 23 UTC, macOS 27.0.1 arm64, Apple Swift 6.4. All Core Swift sources were compiled directly with one disposable host witness, default compiler configuration, no `-O` or `-DDEBUG`. No App/native/simulator execution occurred.

The witness JSON-encodes a fresh Lantern revision-4 game, replaces **only** its board with the 24-star candidate, and decodes it. It then calls production `FallingSky.nudge` and `letStarsFall`; it does not implement its own matching, scoring, growth or settling. The opening and every recorded candidate state pass `isValidSave`; the two post-opening-recovery states round-trip through Codable unchanged. This is a schema-valid Lantern **carrier for hypothetical content**, not a reachable shipped Lantern history or an implemented Kite definition. `replay()` still selects the carrier's shipped Lantern opening.

Production boundary checks separately establish that a nonmatching arrival into a six-star column fills its seventh cell and stays `.playing`; a nonmatching arrival into an already full column commits `.lost`. Matching-top growth is handled before that full-column rejection. The candidate's actual first shower, rather than assumed height semantics, proves both alternatives survive.

Those two one-arrival boundary fixtures are not valid saved Story carriers; they isolate the overflow condition through the existing fixture constructor. All **19 recorded candidate states** separately pass save validation. The coordinator independently recompiled and reran the witness: output matched the worker's JSON byte-for-byte and all 27 witness/Core input hashes matched. An initial broader inspection included the intentionally non-save boundary fixtures; the scoped candidate validation is the accepted save claim.

```sh
swiftc -module-cache-path /private/tmp/starfall-kite-encounter-20261023/module-cache Sources/StarfallCore/*.swift /private/tmp/starfall-kite-encounter-20261023/main.swift -o /private/tmp/starfall-kite-encounter-20261023/kite-witness
/private/tmp/starfall-kite-encounter-20261023/kite-witness > /private/tmp/starfall-kite-encounter-20261023/results.json
```

Both compile/run exits were zero. Disposable `main.swift` SHA-256: `10c1ef5fc7d38bcd4032162de715c665d11faa19d713604d94f679e96aee80e8`; `results.json`: `36dd200a85b745064b52bd42b7724f8c49536522e57530669b6403ddd26e712e`. The adjacent `source-manifest.json` records every compiled Core input. The opening, IDs, supply and action transcript above are the durable reproduction specification; temporary artifacts are not packaged game content.

Relevant owners are [authored definitions](../../Sources/StarfallCore/StoryChallenge.swift), [exchange/shower commitment and restore validation](../../Sources/StarfallCore/FallingSky.swift), [automatic phase resolution](../../Sources/StarfallCore/SkyResolutionPhase.swift), [pattern discovery](../../Sources/StarfallCore/StarRecipe.swift), [scoring](../../Sources/StarfallCore/StoryScore.swift), and [existing authored-position test setup](../../Tests/StarfallCoreTests/StoryPatternTests.swift). Core remains authoritative; scene callbacks cannot award points, advance showers or select a definition.

## Smallest future native comparison and decision

Before runtime adoption, select the bounded Kite objective/content tail explicitly, add its versioned definition and preserve historical constructors. Use existing artwork and normal entry/results. Do not multiply this sketch into five more new rounds.

- **Core/save:** encode/decode the new definition at opening, after each branch, after growth and during recovery. Assert the exact consumed IDs/phase depths and unchanged announced forecasts. Reconstruct the same new opening on Replay; retain legacy Kite's 18-light save/replay and Lantern/Ribbon revisions 1–4. Check missed exchanges, overflow, last-action finish and no post-win actions.
- **Phone and iPad:** compare both plans on one normal-motion iPhone viewport and one iPad viewport. First use existing pause/Next shower to hold the same opportunities; perform actual native exchanges and inspect falling survivors, full-column readability and score feedback. Then run the recovery with ordinary automatic showers to measure usable input opportunity, cancellation/rapid-follow-up behavior and setup effort. Check a committed restore through that path. Quiet presentation preserves outcomes. No actual VoiceOver session is requested.
- **Retain:** native actions produce these distinct consequences; the points-first choice has an understandable recovery; full-round finish occurs promptly and preserves progression/replay; subsequent player observation supports the intended space-versus-reward decision.
- **Revise:** the five-step setup dominates play, the opening's height overwhelms recognition, or the choice is meaningful only with exact hidden receiving columns. Adjust the authored arrangement/supply in a newly explicit candidate; do not rewrite an announced preview.
- **Remove:** native comparison cannot expose a useful distinction or a recoverable alternative. Keep historical Kite and the other accepted goals; discard the candidate instead of adding compensating mechanics.

Human learning, preference, physical touch comfort, final target balance and complete native round acceptance remain open. This leaf delivers the curriculum and source-witnessed encounter brief; it does not complete #206, #248, #253 or a future playable Kite implementation.
