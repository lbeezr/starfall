# Stars share a world

**Status:** Accepted presentation · **Owner:** Current implementer · **Updated:** October 17, 2026

Make one arrival-and-clear sequence feel connected: a glancing arrival transfers a little motion to one existing star, a nearby character acknowledges it, light reaches the landing surface, and the board returns to stillness. Deterministic cells, score, forecasts, saves and clocks stay authoritative.

**Decision:** Use bounded authored contact response, not free rigid-body motion. A contact must have a real receiver within reach in the shared scene coordinates; do not invent collisions across the tall board's empty gaps. Keep at most one receiver and one social reaction per arrival. Small/grown/dark stars have distinct response weights. Stop perpetual per-star idle turns so the completed event has a quiet resting state.

**Decision point resolved:** Adopt the bounded presentation after the seed-five native comparison, full-motion hosted checks and native gameplay flows. [Results and limits](../evidence/star-contact-2026-10-17/README.md). Observatory geometry and art remain a separate workstream; preserving its uncommitted integration does not promote it or establish its floor/stack acceptance.

## Observable acceptance

| Area | Criterion |
| --- | --- |
| Rules/save | Same committed model, score, RNG, forecast and restored continuation for baseline/candidate. No rule or schema edits. |
| Contact | A supported glance visibly deflects the traveler and transfers a smaller impulse to an existing receiver. Growth/stack/empty/dark/edge cases have honest, bounded paths. |
| Character | At most one nearby character turns toward the event and returns front; use the existing bounded StarCast materials. No perpetual idle action remains after settlement. |
| Light/clear | Low surface light stays beneath characters and native controls. Clear has a brief gather, traveling response, gravity and rest. No camera shake or board-wide flash. |
| Timing/input | All transient effects finish by the owned completion deadline; exact final cells, unit transforms and expressions are restored. Rapid taps and restart/settings/background/resize replacement reject stale completions. |
| Accessibility | Calm/system Reduce Motion/VoiceOver retain the same outcomes and usable native input; no new screen-reader announcements. Actual VoiceOver speech/focus remains a separately reported check. |
| Boundedness | Fixed per-star grounding marks, two light shapes per impacted/cleared star (at most 98 for a full 49-cell clear) and one receiver/reaction; no particles, physics bodies, external assets, IO or rendering work added per frame. |
| Evidence | Core, focused hosted/native tests, Debug/Release membership/build checks; inspect native motion and screenshots. Human satisfaction, device performance and Observatory floor/stack comprehension stay explicitly unverified unless observed. |

## Comparison and ownership

`FallingSkyScene` presents committed turns. A focused motion helper owns trajectories, impulse weights and event timing; character nodes own their local response so a reaction cannot fight the parent's falling/settling position. Scene replacement cancels owned actions and removes lights. The store's existing generation/deadline contract owns input and scheduling.

The current baseline is local source `627411f`; the shared checkout also has unrelated in-progress UI/environment/project/mechanics edits, excluded from this isolated checkout. Keep the baseline available for same-seed recording until the adoption decision, then remove any temporary comparison route.

Research: [Glenn Fiedler, Spring Physics](https://gafferongames.com/post/spring_physics/) explains weight, elastic response and damping toward equilibrium. This trial uses finite authored actions inspired by those principles; it does not introduce a numerical physics simulation. Perceived satisfaction remains a playtest question.
