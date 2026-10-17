# Agent-simulated Surge / Shower comparison — 2026-10-17

The user explicitly requested an agent to simulate a user test. A separate agent played the installed native apps through the simulator UI, without inspecting source/research or receiving a preferred outcome. It played Surge first, then Shower, each fresh seed five, paused throughout with manual shower advances. No source or preferences were changed by the agent. It stopped Surge at 13 showers and Shower at 15, without loss.

Decision: keep Surge as the leading phase experiment for further comparison. The simulation provides a concrete example of decisions changing in response to the announced event, but not human enjoyment acceptance or a controlled difficulty result. Before adopting, resolve the existing accessibility/save/presentation limits and compare whether additional matches remain interesting over longer play. The original continuous Shower Lab remains the comparison until that decision; do not add more phase variants in response to this single trace.

## Reported play

| Shower | Surge Lab action | Shower Lab action |
| --- | --- | --- |
| 1–7 | Waited for mint growth; cleared aqua at 3 (+5), mint at 7 (+8), dissolving a dark star. | Same choices on the identical opening board. |
| 8 | Score 13, two ready: cleared amber (+3) to reduce a stack before the announced surge. | Score 13, two ready: held amber/aqua, judging the available space sufficient. |
| 9 | Cleared aqua (+3) before the surge. | Continued waiting for growth. |
| 10 | Held a low violet group after a central dark star appeared. | Cleared aqua (+3) to dissolve an adjacent dark star. |
| 11 | Three ready: prioritized a near-top central violet group (+3), dissolving the dark star. | One ready: waited because the amber group was low and not immediately threatening. |
| 12 | Cleared bottom-left violet (+4), dropping mint into a connected group worth eight. | Waited for growth. |
| 13 | Mint group grew to eleven; stopped at score 26 with two ready. | Cleared amber (+4), joining violet above/below. |
| 14–15 | Not played. | Held violet for growth; stopped at score 20 with one ready. |

The agent's provisional preference was **Surge**, with moderate confidence about cue clarity and low confidence about comparative gameplay. It reported that the countdown gave waiting a horizon. The high central match/dark star changed its priority, and the violet clear that joined mint was its clearest spatial-planning moment. Several early clears felt freely available because there was no visible move cost or clear penalty; meaningful decisions involved waiting for growth or removing a supporting group.

The agent found rings and ready counts useful for locating clears. It also reported having to discover that two stars can form a legal clear when their total value reaches three. A concrete follow-up is to review whether the existing visible instructions explain the starlight threshold and grown-star value at the moment the player needs them, without adding instructions over the board.

The agent questioned whether Shower Lab's paired rule was active because no event label appeared. That is not a missing-route bug: Shower Lab intentionally has continuous generation and no phase cue. The parent independently verified installed executable/debug-dylib hashes against build products and mapped their source manifests and core hashes to the intended candidates. Both use baseline `30af812aa3bf3105a55d8b960288e1d2ac672c2c`; the reference core matches the natural-only offline comparison. [Binary/source identity record](installed-builds.json).

## Evidence and limits

Native device: iPhone 17e “Starfall Mechanics Lab,” iOS 27.0, simulator `A84C81F5-AE41-496A-97AE-E17C63E18D29`. Bundles `com.starfall.surgeshowerslab` and `com.starfall.pairedshowerslab`. Parent-inspected screenshots: [Surge at 13](surge-shower-13.jpg) and [Shower at 13 before its clear](shower-shower-13.jpg). These illustrate the reported states, not equivalent controlled board positions. Source-bound native verification is in the [Surge Lab record](../surge-native-2026-10-17/README.md).

This is one agent simulation, with no participant sample or independent human enjoyment judgment. It is not blinded to visible event wording; Surge was always played first. The agent's choices diverged at shower eight, so later board/score differences combine rules and decisions. Paused play and tool deliberation cannot assess urgency, reflexes or normal-speed difficulty. System Reduce Motion was enabled; this simulation does not establish full-motion quality or actual VoiceOver listening. The parent did not interact with the simulator during the agent's play; binary inspection was read-only. No new automated test or native build was required for recording these observations.
