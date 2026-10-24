# Queue the next deliberate moves

**Status:** Implemented and development verified locally · **Owner:** Current coordinator · **Updated:** October 24, 2026

The user wants to keep planning moves while Starfall calls out combos and presents earned light. Announcements never own input. A bounded FIFO retains up to four accepted tap/swap commands through physical presentation, with immediate static direction/count feedback and no wall-clock expiry. The [player-momentum plan](PLAYER_MOMENTUM_PLAN.md) owns the current priorities.

[Development evidence](../evidence/player-momentum-2026-10-24/README.md) covers exact FIFO/save/clock/lifecycle behavior and a native normal-motion five-phase sequence. Physical thumb comfort and actual VoiceOver remain unperformed.

## Input and lifecycle contract

- Capture the actual input snapshot at contact start and submit against it before releasing the contact. A release cannot dispatch an older command and reinterpret the star/group just touched.
- Preview each command through Core against the prior queued command's projected outcome. Only stationary visible endpoints whose identities remain in those cells are accepted. Do not silently follow a moved ID or select a final-state replacement. An exchange that settles back still has a moving waypoint; exclude both exchange endpoints throughout that presentation. Manual tap admission validates the whole selected group.
- Keep accepted commands in FIFO order. New contacts append rather than replacing earlier intentions. Admit at most four commands across one continuous presentation burst, preventing indefinite replenishment from starving showers. Reject capacity/conflicting-identity requests with factual feedback and preserve existing commands.
- Serialize queued physical transactions and commit/save each head exactly once when physical ownership is available. Full pop, fall, refill and causal-phase motion remain. Celebration text, sound and collection flights have no input reservation and cannot delay the next command.
- Preserve the existing single clock remainder while contact/queue owns it. Resume that remainder after the final physical transaction or cancellation; already-due rain wins and no catch-up shower queue is created. Animation callbacks coordinate presentation readiness, never legality, score, supply or save outcomes.
- Round replacement, Replay, settings/background/suspension, layout/motion changes, scene detachment and incompatible direct commits cancel the complete uncommitted plan. Retire the head before execution; stale completions cannot duplicate it. Persist only committed state, with no new schema or restore queue.
- Native and accessible tap/swap entry points use the same request boundary. Held constellation walks retain their exact-selection contract and do not enter the queue. Existing direct, disjoint-column commits retain their strict admission policy.

## Verification and limits

Use deterministic presenter/clock regressions for FIFO order, distinct contacts, long/five-phase presentation, capacity, exact projected state, moving/replaced/settle-back identities, whole tap groups, contact-release ordering, terminal winners, committed-only saves, due rain and interruption. Exercise native rapid swipes during the production Ribbon five-phase transaction without waiting for settling between queued contacts; compare normal/quiet outcomes and inspect the passive cues. First-play guidance uses the same input boundary.

Independent stationary moves are supported; planning through future moving/refilled positions is rejected until those stars are actually available. Four admissions per burst is a conservative initial limit, not an observed optimal capacity. Revisit these constraints with the next [uncoached player session](CURRENT_STORY_PLAYTEST.md), preserving safe identities and usable shower opportunities. Simulator interaction does not establish physical comfort, sustained performance or enjoyment.

## Historical single-slot behavior

The October 18 implementation kept one latest intention for 650 ms and canceled it on a new touch. That covered ordinary 340 ms swaps and 560 ms clears. [Ribbon's later native evidence](../evidence/depth-goal-06-ribbon-full-board-2026-10-23/README.md) records a valid follow-up arriving about 2.7 seconds before a five-phase transaction ended, so that intention expired. The FIFO supersedes expiry/replacement while preserving historical rules, full motion and save compatibility. The old evidence remains source-bound; no phone delivery is performed by this change.
