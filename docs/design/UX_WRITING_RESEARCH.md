# Make Starfall understandable, then give its characters a voice

**Status:** Research complete; rewrite authorized October 18 · **Owner:** current implementer · **Researched:** October 18, 2026

Starfall needs clearer explanations and more specific character reactions. The sampled copy switches between technical shorthand, vague encouragement and dense instructions. Recommend one player vocabulary, short explanations tied to actual actions, and six distinct voices reacting to committed events. More catchphrases alone will not solve this.

This document records the research and original proposals. The user subsequently authorized a runtime rewrite, including distinct character phrases and playful teasing. The [authoring guide](../../App/DialogueScripts/README.md) owns the resulting content system; [implementation evidence](../evidence/copy-rewrite-2026-10-18/README.md) separates checks from open player-comprehension questions. Tables below remain research drafts rather than an exact inventory of shipped strings.

**Next action:** Finish native review of the rewrite, then observe uncoached player comprehension and tune reaction frequency from actual play.

## What the research supports

| Source inspected | Relevant finding | Application to Starfall |
| --- | --- | --- |
| [NN/g: The 3 C’s of Informational Microcopy](https://www.nngroup.com/articles/3-cs-microcopy/), March 20, 2026 | Prioritize clarity, then concision, then character. Extra words are justified when they improve understanding. | Explain the action and consequence before decorating a line. Do not replace an accurate rule with a shorter inaccurate one. |
| [Mailchimp: Voice and Tone](https://styleguide.mailchimp.com/voice-and-tone/) | Voice stays recognizable; tone changes with the reader's situation. Clarity takes precedence over entertainment; humor should feel natural. | Keep the cast warm, but make a warning direct and an ending considerate. Avoid forced jokes and reassurance that contradicts time pressure. |
| [Valve / Elan Ruskin: AI-driven Dynamic Dialog](https://www.gdcvault.com/play/1015528/AI-driven-Dynamic-Dialog-through), GDC 2012 | The public session overview describes dialogue selected from facts about the current world and history. | Each reaction needs an explicit event and truth condition. Borrow the contextual writing principle; Starfall does not need Valve's large dialogue system. |
| [Supergiant / Greg Kasavin and Darren Korb: The Dialogue of Hades](https://www.gdcvault.com/play/1026975/Breathing-Life-into-Greek-Myth), GDC 2021 | The public overview describes developing distinct character voices and integrating the script through a collaborative production process. | Define how each character notices and phrases things before writing variants. This is our small-game application, not a prescription from the talk. |
| [Xbox Accessibility Guideline 101](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/101) and [104](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/104) | Support readable text; subtitle guidance includes speaker identification, manageable reading demands and avoiding obscured gameplay at larger sizes. | Preserve named speakers and native scaling; test actual phone layouts. These are useful design references, not iOS certification criteria or a reason to impose console subtitle dimensions on our bubble. |

All pages above were opened during this research. GDC evidence is limited to public session descriptions; the full videos were not watched. Research supports the principles, not proof that these particular drafts improve play. Frequency limits and character assignments below are proposals.

## What is wrong in the current copy

Audit source: clean `5bec506ab2899ff69538fcfd233338ba8a516bb1`. Inspected the complete [bundled catalogue](../../App/DialogueScripts/observatory-dialogue.json), its [library/composition](../../App/SkyDialogueLibrary.swift), production event selection in [FallingSkyStore](../../App/FallingSkyStore.swift), [HUD pacing copy](../../App/FallingSkyHUD.swift), [menu](../../App/FallingSkyMenu.swift), [flow actions](../../App/SkyFlowCeremony.swift), [result snapshots](../../App/SkyFlowSnapshots.swift), and relevant Core matching/orbit/Dusk paths. This is a targeted audit, not a complete inventory of every accessibility label, fixture and help page.

| Observed text / path | Why it needs work | Proposed treatment |
| --- | --- | --- |
| “Match three light side by side” / “five actual matching stars” | “Light” does not clearly distinguish matching weight from reward; “actual” explains an implementation distinction without explaining the gesture. “Side by side” can imply a horizontal row. | Separate tap and trace instructions. Explain grown-star matching weight in help. |
| “Orbit: {windows} windows left. Clear a captive…” | “Windows” has no established player meaning; “captive” adds another term. | Describe trapped stars and the shower countdown. Check the final pre-release count explicitly. |
| “Faster passage” / “Breathing window” | Atmospheric names obscure the observable difference: time between showers. | “Showers are closer together now.” / “More time between showers now.” |
| “A little wonder. A little room to breathe.” | Provides atmosphere but no purpose or action; “room to breathe” also recurs in clear feedback. | Reserve atmosphere for optional flavor. Opening should explain clearing stars to make space. |
| “{score} starlight gathered. Every sky tells a different story.” | Does not explain why the round ended; repeated seeded replay also makes “different” unhelpful. | Lead with the blocked-column reason already available in `SkyResultSnapshot`. |
| Twinkle: “Take your time.” | In the cast studio it sounds soothing, but transferring it to active automatic showers would be misleading. | Use only while automatic showers are paused. |
| Dusk help describes two strategies, feeding, swallowing, gray matches and zero score in one timed line | Too many decisions for a small eight-second message. It also hard-codes five feeds while retained rule versions include three. | Give the immediate effect/action first; explain the tradeoff in help. Derive any feed count from the current rule. |
| `guide.context` joins result and pacing; orbit can replace another result in `present` | Even good individual sentences can become an overlong or poorly attributed combined message. Nova can inherit Sunny's wording. | Review fully rendered messages and event precedence. Any selection change is a separate behavior change with focused tests. |

The cast studio establishes portraits and names, but its six samples mostly express interchangeable encouragement. Production informational lines are predominantly Sunny, with pacing/context assigned to Nova. The source does not establish six developed verbal personalities.

<img src="../evidence/character-chat-2026-10-17/active.jpg" width="240" alt="Historical phone capture with a two-line Sunny instruction in the compact bubble beneath the star board">

**Inspected historical native reference, not current-build validation.** [October 17 character-chat evidence](../evidence/character-chat-2026-10-17/README.md), iPhone 17e / iOS 27.0 Simulator. This illustrates the limited reading space; it does not show the proposed copy or certify today's layout. No visual changes or new captures in this research batch.

## A vocabulary players can learn once

Use **star** for a board piece and **starlight** for the score. Use **grown star** consistently, with its visible large form explained once. A grown star counts as two toward an ordinary tap match; a trace counts distinct stars, regardless of size. Gray stars retain matching weight but earn zero while drained. Therefore “worth two” needs context: it is not always two earned points.

Use **matching stars** in prose, anchored to the cast's color, shape and name cues. Teach **constellation** as a traced group rather than requiring the term before the action is understood. Use **shower** for incoming stars; distinguish a **heavy shower** (more stars) from **faster showers** (less time between them). Those are separate facts.

Use **trapped stars** in help instead of “captives,” and express orbit duration in showers instead of “windows.” Keep established object names such as **Opal Orb** until a coordinated naming review; avoid introducing another synonym in each message.

Name actions consistently across screens: **New sky** and **Replay this sky** are useful existing anchors. Explain that replay restarts the same seeded sky. For pause copy, say that automatic showers stop while clearing and Next shower remain available. Match button references to the visible label.

## Original copy drafts

These are candidates, not shipped strings. Bracketed conditions are authoring requirements, never player text. Longer help belongs in player-paced reading, not an automatic bubble.

| Situation | Candidate | Required context |
| --- | --- | --- |
| Entry | “Clear matching stars to make space for the next shower.” | Basic purpose; teach input separately. |
| Tap help | “Tap a matching group connected up, down, left or right. You need a total of 3: small stars count as 1, grown stars as 2.” | Matching weight, not guaranteed reward. Explain gray rewards separately. |
| Trace help | “Drag through 5 or more matching stars, then lift your finger to clear them. Only the stars you trace will clear. Each star counts once, even when grown.” | Follow with diagonal-neighbor help and separate square-recipe help; five-star tracing is not the only special clear. Supply equivalent accessible-action instructions. |
| Paused | “Automatic showers are paused. Keep clearing, or tap Next shower.” | Paused active round, not settings suspension. |
| Faster phase | “Showers are closer together now.” | Current phase, not a forecast. Preserve “after the next shower” when warning ahead. |
| Orbit help | “Clear a matching group that includes a trapped star to free the others.” | Valid orbit; countdown explained separately as “The hole releases its stars after … showers.” Render correct singular/plural. |
| Dusk arrival | “Stars touching Dusk turn gray and earn no starlight. Clear a matching group beside Dusk to remove it.” | Feeding rule only; legacy dark-star help remains separate. Explain intentional waiting/collapse in full help. |
| First Light entry | “Collect 18 starlight before a column fills.” | Challenge-specific objective. |
| Full sky | “Column 4 had no room for the next star. You collected 27 starlight.” | Example values from committed result; retain generic fallback if column is unavailable. |
| Challenge won | “First Light complete! You collected 18 starlight.” | Use actual score, including an overshoot; keep replay/new-sky buttons outside the sentence. |

Do not simplify the tap rule to “three stars,” collapse diagonals into tap adjacency, describe a trace as clearing the entire connected group, promise that pause freezes every interaction, or rename a forecast as a current condition.

## Give each character a different way of noticing

The following voice extensions build on the [approved visual temperaments](star-cast/README.md). They are proposed writing direction, not newly accepted personalities or gameplay roles. Keep Sunny as the initial guide. Other speakers need deliberate event assignments; do not distribute technical notices randomly just to use every portrait.

| Character | Proposed verbal habit | Original reaction and exact trigger | Avoid |
| --- | --- | --- | --- |
| Sunny | Friendly, practical; invites the next action | “There we go. Space for more.” — a clear actually frees space | Repeating generic praise after every tap |
| Spark | Curious; notices specific changes | “Oh! That one's grown.” — one star grows | Claiming to see a legal move without checking it |
| Pip | Compact, lightly dry | “That was getting crowded.” — a clear relieves measured crowding | Mocking the player's mistakes |
| Twinkle | Gentle; offers permission without pressure | “We can stay here a while.” — automatic showers paused | “Take your time” during a live countdown |
| Nova | Unhurried, observant; warnings stay explicit | “Heavy showers are over. Fewer stars next.” — transition to lighter arrivals | Sleepy jokes that hide timing or quantity |
| Dusk | Mischievous, matter-of-fact about appetite | “I may have eaten those.” — Dusk has actually consumed stars | Threats, blame, or implying a new choice/input |

These are short reactions, often called barks in game writing. They supplement understandable rules and status. Dusk's joke cannot replace the zero-starlight consequence; Spark's reaction cannot replace teaching what growth means. All samples are original; no commercial-game catchphrases were copied.

Proposed frequency policy: allow silence after ordinary events; reserve automatic speech for useful changes, first explanations and outcomes. Begin with one strong reaction per chosen event, not a large variant bank. If repetition is observed, adjust frequency before adding synonyms. A phrase should survive being heard repeatedly; recognition should come from the character's outlook, not an obligatory catchphrase.

Author each line with event, truth condition, player need, speaker, priority, repeat policy and dismissal behavior. Preserve stable script/line IDs. The current JSON format has no variant/history policy fields; keep those notes in the writing inventory unless a demonstrated need justifies a small runtime change. Never use gameplay RNG for cosmetic variety.

## Acceptance for the rewrite

- A new player can explain tap matching, traced-set clearing, grown-star counts, pause and the losing condition after reading the relevant help. Observe a short first-play session; editorial review alone cannot pass this.
- Each shipped fact holds for the actual challenge, saved rule version and committed state. Check zero/one/many values, gray grown stars, three/five-feed Dusk saves, the last orbit window, and score overshoot.
- Review complete token-expanded/composed messages, not only catalogue entries. Outcomes must win over lower-priority chatter; old forecasts must not reopen as current advice. Preserve existing cancellation, reopening and save contracts.
- Read character samples aloud without their names. Confirm that wording distinguishes them without turning each into a caricature. This is an editorial check, not proof of player preference.
- Inspect the normal phone bubble and largest Dynamic Type in the studio and real flows. No truncation, board obstruction or shrinking text to fit. Preserve native speaker attribution, accessible input alternatives and retained message reading. Routine development accessibility checks apply; actual VoiceOver acceptance remains an RC gate.
- Run Core tests, affected hosted/UI checks and a simulator build for the implementation batch; inspect normal motion and Reduce Motion separately. Content validation cannot establish comprehension or good timing.

Research verification: web pages and historical image inspected; no new simulator, physical-device, animation or VoiceOver session run. Rule/save/interruption changes are inapplicable to this documentation-only batch. Native layout and human comprehension of the drafts remain unverified. Repository hygiene and diff checks are recorded with the delivery.
