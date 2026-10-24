# Make the next move inviting

**Status:** First two slices implemented and development verified locally · **Owner:** Current coordinator · **Updated:** October 24, 2026

The player promise is an immediately understandable star puzzle: make a useful move, see its consequence and keep playing while the game celebrates. The user explicitly prioritizes responsiveness and a faster first satisfying clear after the adversarial product review. This is a bounded request, separate from the standing factory queues. More locations, monetization and additional systems are not part of this implementation batch.

## Ordered outcomes

| Priority / order | Outcome | Observable acceptance / next decision |
| --- | --- | --- |
| P1 · 1 | Keep deliberate moves queued through cascades. | Up to four distinct accepted swipes survive long full-motion presentations and execute once in order. Announcements and collection effects never reserve input. Validate selected star identities; cancel incompatible or interrupted intent without retargeting. Preserve committed-only saves and the single shower clock. |
| P1 · 2 | Give new players a direct route to the first real clear. | Genuinely fresh Home offers one-tap Lantern play, using the ordinary current round/save/mastery owners. A concise cue names the existing opening square; the actual exchange earns 15,000 points through two phases. Existing/rejected saves, other Home choices and practice remain intact. |
| P1 · 3 | Observe whether the improved loop earns another round. | Run the existing [uncoached pilot](CURRENT_STORY_PLAYTEST.md), associated with [#206](https://github.com/lbeezr/starfall/issues/206), with the next five new players. Record time from Play to first intentional clear, rejected/accidental moves, control/satisfaction, stop reason and actual voluntary continuation. Initial design target: an understood first clear within 30 seconds of Play, without an observer explaining the move. Later-day return is separate from stated intent; this small sample guides corrections rather than estimates population retention. |
| P2 · 4 | Make live feedback readable at a glance. | Compare one concise live callout such as “2-clear chain · +15,000” while keeping exact accounting in optional Last clear. Observe next-move hesitation and whether players can still explain the clear. Adopt shorter copy only if it improves reading without losing useful cause/effect; keep celebration passive. |
| P2 · 5 | Make campaign effort and endings feel earned. | Observe ordinary whole rounds before changing targets. Compare the opening pair with short later encounters, including unfinished/overdue/premature endings and understood consequential decisions. Choose one evidenced round-arc correction; do not inflate objectives merely to add time. |
| P2 · 6 | Prove repeat value within one existing place. | After a repair, observe self-chosen improvement and repeated plans. If renewal is weak, compare one bounded offline variation or mastery refinement before expanding art/content. Preserve exact Replay as deliberate practice. |
| P2 · 7 | Establish a commercial proposition after return value. | Investigate a future opt-in commercial edition only after observed return and willingness to recommend/pay. Evaluate acquisition cost against net lifetime contribution and ongoing content/support. Current app stays offline with no ads, purchases, tracking or analytics; no monetization implementation is authorized here. |

The first two outcomes pass [source-bound development checks](../evidence/player-momentum-2026-10-24/README.md): 352 Core, 135 selected hosted and three native journeys, plus Debug/Release. These establish execution and sampled layout, not human satisfaction or retention. Independent visual review subsequently rejected the queue panel and detached AX3XL composition; PR #395 remains held for shared-component correction and integration of active HUD repair #382 before adoption. Nearby versus and cooperative restoration remain future directions under the [Pokémon Puzzle League adaptation guide](POKEMON_PUZZLE_LEAGUE_REFERENCE.md); this batch remains offline.

## First slice: responsive input

The recorded failure is [Ribbon's five-phase swipe expiry](../evidence/depth-goal-06-ribbon-full-board-2026-10-23/README.md): a valid next swipe arrived about 2.7 seconds before physical presentation finished, exceeding the old 0.65-second buffer. Merely waiting longer in tests does not improve the player's interaction.

Use a bounded FIFO with sequential Core previews and exact endpoint identities. Queued intentions remain transient; only an executed action is committed/saved. Full physical presentations remain ordered. Stable visible stars can admit plans; departing/moving/replaced stars must never silently name a different final occupant. The first implementation supports independent plans and explicitly rejects a conflicting projected endpoint. New contacts append rather than evict accepted moves. Round replacement, suspension, layout/motion changes and stale generations cancel uncommitted plans. Already-due rain keeps priority; draining/canceling resumes one retained remainder without catch-up.

Counterexamples: a long cascade must not expire an accepted swipe; a capacity overflow must not evict one; a disappearing source must not move its replacement; no old callback may execute after Replay/background; saves must contain no speculative future move. Normal and quiet presentation must commit the same action sequence. Native evidence must include rapid contacts during full motion, without waiting for settling between admitted requests.

## Second slice: first clear

Home offers **Play Lantern Landing** only for strict missing-archive/no-history state, excluding rejected recovery, world/mastery history and practice/review/reset routes. Explicit user action invokes the normal Begin handoff; construction stays read-only. Keep Story, Free Play and Tutorial available. Starting the actual round supplies existing persistent return detection; add no first-play save schema.

Use the current production Lantern4 opening and its real Aqua-left square. A passive cue withdraws when the committed board changes; it cannot force a move, delay showers, award a repair or change rules. The contrasting scenarios are a fresh launch and a returning/rejected-save launch. Prove the route, real first clear, next input, Home/restore, interruption and phone/tablet large-text reading. Human learning, speed and enjoyment remain unperformed until observed.

## Ownership and verification

One worker owns Store/input/presentation and focused regressions. A second owns Home/flow/copy and flow tests. The coordinator owns View integration, native interaction checks, project membership, this plan and shared indexes. No worker stages, commits or uses another worker's simulator. Existing [verification](../ENGINEERING.md#verification-by-change), [UI production](UI_PRODUCTION.md) and [factory](../AGENT_FACTORY.md) contracts apply. Keep raw output disposable and source-bound summaries in evidence.

The prioritized plan is published as [GitHub issue #393](https://github.com/lbeezr/starfall/issues/393) after the user's explicit publication approval. Earlier attempts were rejected by automatic approval review for missing external-posting authorization. Implementation is in draft [PR #395](https://github.com/lbeezr/starfall/pull/395), held for corrected visual acceptance; no phone installation was performed. This file records development implementation and planned follow-ups, not human-retention or commercial acceptance.

## Parallel delivery wave — October 24

The user requested disjoint agents targeting main. One coordinator integrates the existing first-loop slice while three workers cover independent work. Current-main reconciliation preserves the HUD stack owned by its separate coordinator; this wave does not claim that queue.

| Workstream | Exclusive delivery | State at integration handoff |
| --- | --- | --- |
| First playable loop · coordinator | Existing Store/input/flow/View slice, focused checks and shared evidence | Nonvisual input merged in [#398](https://github.com/lbeezr/starfall/pull/398), verified352Core/88hosted/one native cascade plus Debug/Release. First-play/visual additions remain draft #395. Main5a baseline:352Core/135hosted/6native plus Debug/Release pass. Shared passive status/markers corrected; whole-screen adoption held for active HUD382 composition repair and fresh independent review. |
| Live feedback · worker | Automatic live scripts/guide and receipt label, exact detail retained in Last clear; isolated codex/momentum-feedback checkout | Source and native navigation repair frozen. Debug/Release,113hosted and3 AX3XL actual-Calm journeys pass; normal-phone pause-navigation failures remain under bounded diagnosis. Whole-screen visual acceptance also depends on active HUD382 correction. |
| First-session study · worker | CURRENT_STORY_PLAYTEST.md only | Merged to main in [#396](https://github.com/lbeezr/starfall/pull/396). Seven local links, hygiene and whitespace pass; identified candidate/ordinary starts stay separate. Actual #206 observations remain outstanding. |
| Round/repeat analysis · worker | ROUND_PACING_AND_REPEAT_VALUE.md only | Merged to main in [#397](https://github.com/lbeezr/starfall/pull/397), including two stale maintained summaries.17local links, hygiene and whitespace pass. No tuning or human verdict. |

The coordinator owns shared Git, PRs, indexes and the two dedicated simulators. Workers did not run Git/native builds, fan out, add telemetry or fabricate observations. Additional supporting issue creation was rejected by automatic approval review; use this local packet and the already published parent #393 rather than duplicating external issues. Each slice has a separate main-targeted branch and review boundary; actual player evidence and the commercial proposition keep their stated dependencies. This wave creates no recurring/background task or device delivery.
