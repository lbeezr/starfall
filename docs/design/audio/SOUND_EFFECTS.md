# Starfall sound-effects palette

Prepared 16 October 2026. **Four quiet-tuck takes selected by the user; native playback remains unvalidated.** The authorized generation batch is terminal; see the [audition index](README.md) and [exact batch manifest](AUDITION_MANIFEST.json) for results. This is a bounded proposal under the [game bible](../STARFALL_GAME_BIBLE.md), especially its quiet wonder, tactile delight and one-note-per-action direction. It changes no rules, app settings or source. Silence remains a complete experience; Gentle sound remains optional and off by default.

## Recommendation

**Current selection:** all four quiet-tuck takes, 06–09, are the starting palette. The user finds glassy resonance lightweight and sparkly. Use these [preserved originals](selected/README.md) as alternate primary-clear contacts, despite their original settle label. Prefer a rounded warm body, a small definite attack and a short damped decay. [SONIC_WORLD.md](SONIC_WORLD.md) carries the expanded direction and supersedes the initial glass-led material briefs below.

The audible gesture remains **contact → release → rest**. In the first pilot, rotate all four tucks through every group size and terminal clear, independently of the game's RNG. A group of three should already feel satisfying. Use the same material family for all five kinds and omit a separate settle accent. Later, a larger group may sound fuller, but never harsher, dramatically louder or progressively faster. Reject brittle shattering, per-fragment clicks, reward-machine runs, sparkling noise beds and constant ambient activity.

The original briefs proposed a **D-major pentatonic family: D, E, F♯, A, B**. Prompts request pitch; they do not prove it. Preserve the selected tucks unchanged as references and choose future music around the material that actually works. Retuning is not required by the selection. Do not map pitches to jewel kinds, moves remaining or a running streak. There is no combo, multiplier or automatic cascade mechanic.

## What exists in the inspected working tree

| Source boundary | Current behavior | Audio implication |
|---|---|---|
| [`GameFeedback.swift`](../../../App/GameFeedback.swift), `cleared` | Plays system sound `1104` once for a valid turn when sound is enabled. Outcome currently changes haptics, not the sound. | Replace through this small presentation boundary if authored audio is later approved. Do not attach sound to each rendered piece. |
| [`GameStore.swift`](../../../App/GameStore.swift), `tap` | Rejects input while busy, in Settings, outside play or after the outcome. Invalid groups announce a message and nudge a cell. Valid rules commit and save before feedback and animation. | A committed turn is the authoritative audio event. Rejected input must not request a clear cue. |
| `GameStore.settlePresentation`, `restart` | Cancels the presentation; committed state survives interruption. | Future audio needs matching cancellation and stale-event rejection; that audio capability does not exist yet. |
| [`JewelScene.swift`](../../../App/JewelScene.swift), touch methods | Has a silent touch-down group preview; movement out of the start cell, cancellation and unsupported multitouch cancel it. A same-cell touch end commits. | Keep preview and cancellation silent. A preview sound would be a new proposal, not an existing hook in `GameFeedback`. |
| `JewelScene.animate` and [`StarfallArrivalEffects.swift`](../../../App/StarfallArrivalEffects.swift) | Normal presentation has a 0.20 s clear followed by a 0.28 s arrival phase. Survivors descend; new pieces arrive diagonally. Suppressed motion can complete synchronously. | An optional settle cue must follow actual completion, not a fixed timer or a callback per piece. |
| [`Game.swift`](../../../Sources/StarfallCore/Game.swift), `tap` / `ensureMove` | A valid group clears once. A still-playing dead board receives three bottom-row replacements, free. | No cascade sound, shuffle sound, recovery award or extra clear. |

The bible still calls touch preview and diagonal refill proposed; these visual paths are present in the inspected uncommitted working tree. That observation is **source inspection**, not visual, device or listening validation. This document does not change their approval status or the bible.

## Initial event and cue matrix — exploration history

This records the initial tier/settle/win proposals, not the selected starter assignments. The current pilot uses four quiet tucks for every committed clear, including win/loss, and no separate settle or outcome phrase. Later extensions must follow [the selected sound world](SONIC_WORLD.md). “Silent” means no added game sound; accessibility announcements remain independent and informative.

| Event / permutation | Proposed sound | Bound and reason |
|---|---|---|
| Valid group, 3–5 shards, round continues | `clear_small_a` / `clear_small_b` | Exactly one request per committed turn. Alternate two matched variants using a presentation-only counter; never consume gameplay RNG. |
| Valid group, 6–9 shards, round continues | `clear_full_a` | Fuller body at matched perceived loudness, not a reward jingle. Tier is presentation only. |
| Valid group, 10–49 shards, round continues | Same `clear_full_a` | Saturate the treatment here. No larger stack, longer chain or more notes. The rule count stays exact. |
| Rose / aqua / amber / violet / mint | Same tier mapping | Material unity and a finite asset count; shape/color remains readable without sound. No five-way pitch or sample bank. |
| Consecutive clears / fast valid input | Same mapping; no escalating sequence | Each is an independent turn. No streak meter, combo language, pitch ladder or combo bonus is implied. |
| Invalid 1–2 group or diagonal-only connection | Silent | Existing nudge/message explains it. No buzzer, scolding tone or move-loss implication. |
| Touch preview, held finger, drag cancellation, touch cancellation | Silent | The clear sound belongs to commitment. Prevent repeated chirps while exploring. A preview audition is deferred unless silent preview proves unclear. |
| Tap on padding, busy board, terminal board; unsupported multitouch | Silent | No committed action. Never queue a rejected tap for later playback. |
| Clear fragments, sparks, constellation travel / progress decoration | Silent | Their visual counts must not produce sound counts. They do not award extra starlight. |
| Survivor gravity and individual refills | Silent | Avoid 49 collisions, column rhythms or a second apparent clear. |
| Whole board finishes settling | Optional `settle_a`, default omit | At most one very quiet accent per nonterminal turn; keep only if an A/B audition improves clarity. No accent in Calm effects, Reduce Motion or VoiceOver. |
| Free dead-board recovery | Silent; suppress optional settle on that turn | Three bottom-row replacements are not a full-board shuffle or bonus. Preserve its text / VoiceOver explanation. |
| Win, including reaching 70+ on last move | `win_a` **replaces** normal clear cue | One composite file begins with the clear contact, then resolves. Never layer a clear and win file. Never play a loss sound because moves also reached zero. |
| Loss after final valid move | Normal group clear cue; then silence | The last clear still worked. Let the inline result and announcement explain the outcome without a sad or punitive sting. |
| New game, Continue, Menu, opening / dismissing Settings | Silent | Cancel previous transients. No restart fanfare or sonic navigation layer is needed. |
| Gentle sound switched on / off | Silent toggle | No unsolicited test chirp. Off cancels playing and pending game audio. Do not replay the last action when enabled. |
| Low moves, idle board, idle menu, target nearly reached | Silent | No urgency pulse, ticking, escalating music or near-miss cue. |
| Background, audio interruption, route change | Stop/cancel transient game audio | No delayed settling or completion phrase after the app loses activity. Resume silently into the committed state. Exact device behavior needs implementation and Apple-device validation. |
| Restore a saved win/loss or return from Settings | Silent | State restoration is not a new outcome event. |

## Scheduling and mix proposal for later extensions

These are starting audition values, not measured requirements or an implemented audio engine. For the selected starter, match the four tuck contacts gently by perceived level, preserve their envelopes and omit settle/music/win layers. The former 0.10–0.16 second settling edit target below does not apply to the selected primary-clear originals.

- **Small surface:** preserve `GameFeedbackProviding` as the gameplay-facing boundary. An eventual local sample player can own cue selection, bounded voices and cancellation. Keep audio out of `StarfallCore`; use no network playback or external runtime SDK. Avoid making SpriteKit nodes the source of truth for a turn cue.
- **Priorities:** terminal phrase 100, committed clear 80, optional settling accent 20. At most **two simultaneous SFX voices**, normally one: a previous tail may overlap the next attack briefly. Music has a separate bounded voice and must not multiply with each turn.
- **No backlog:** request the primary cue immediately after commitment. Deduplicate by the presentation's turn identity, not shard count. A new valid turn cancels any pending settle accent; never queue old attacks behind a busy player. Preempt a prior clear tail with a 15–25 ms fade if it would exceed the voice cap.
- **Very rapid synchronous turns:** after at least one audible clear, coalesce ordinary clear requests within a provisional **120 ms** window; preserve every rule action and result announcement. Do not defer a suppressed cue. Terminal outcomes bypass this acoustic cooldown, fade lower-priority tails and play once. The existing normal animation lock already spaces ordinary taps farther apart; this bound covers motion-suppressed/accessibility paths without assuming that lock's timing.
- **Optional settle:** only from successful completion for the same still-active turn; cancel on interruption, new turn or outcome. Start immediately at completion or drop it if already stale by more than **30 ms**. No hard-coded 0.48 s timer: calm/accessible completion can be synchronous. Never delay input for audio. Use the smaller of one accent per turn and a **350 ms** accent cooldown.
- **Mix:** loudness-match the three clear files by ear at phone scale. Start full-clear gain equal to small-clear gain, settle **8–12 dB quieter**, and win contacts no louder than the normal clear. Check decoded peaks with headroom (provisional peak ceiling −3 dBFS), but do not use peak matching as a substitute for listening. The music bed should leave the short glass attack and spoken accessibility feedback intelligible.
- **Accessibility:** sound never carries exclusive state. Calm effects / Reduce Motion preserve an enabled primary clear or outcome cue while dropping decorative settle. Under VoiceOver, drop settle and shorten or duck game-audio tails so the existing result announcement can start immediately; never delay speech to finish a flourish. Validate with actual VoiceOver before selecting the final envelope.
- **Interruption:** restart, Menu, Settings, background, renderer removal, sound-off and audio interruption invalidate queued cues and fade active tails promptly. A turn token cancelled by `settlePresentation` must not later trigger a settle or replay an outcome. Audio route and silent-switch policy belongs in the integration proposal; this draft makes no claim about present system-cue behavior on devices.

## Five bounded ElevenLabs audition requests

The approved audition target was **eight briefs with four takes each: 32 candidates**, including **20 SFX candidates**. Three overlong SFX prompts received distinct shorter revisions within the same USD 2 ceiling. Original prompts, rejected jobs and revisions are preserved in the manifest. All jobs are terminal; music failures report insufficient funds. The later user selection establishes four quiet-tuck starters and supersedes the initial two-variant clear plan. No further generation or top-up accompanies selection. The [index](README.md) and [manifest](AUDITION_MANIFEST.json) hold actual results, costs and exact parameters.

The prepared Sound Effects nodes use non-looping output and prompt influence **0.7**, as recorded in the verified batch manifest. Requested durations respect the installed skill's 0.5 s generation minimum. The final edit is often shorter than the generated file. A loss/invalid/preview sample is intentionally absent.

| Candidate | Generate | Target final duration | Editing need |
|---|---:|---:|---|
| `sf_clear_small_a` | 0.5 s | 0.24–0.32 s | Trim onset silence; preserve the rounded attack and shorten the tail. |
| `sf_clear_small_b` | 0.5 s | 0.24–0.32 s | Match A's attack timing, perceived loudness and pitch center; reject a conspicuously different “instrument.” |
| `sf_clear_full_a` | 0.7 s | 0.32–0.42 s | Retain body; remove excess reverb or secondary attacks. |
| `sf_settle_a` | 0.5 s | 0.10–0.16 s | Extract one muted contact, not the entire generated tail. Optional candidate, not a shipping requirement. |
| `sf_win_a` | 1.6 s | 1.10–1.40 s | Keep immediate clear contact and two-note resolution; trim trailing silence without chopping decay. |

**1 — `sf_clear_small_a`**

> One isolated soft crystal contact for a calm moonlit puzzle game. A rounded glass note centered on D5, with a warm woody low body, a tiny dry tactile click at the onset and a short silky decay. One clear attack immediately at the start, then silence. Delicate, close and reassuring. No shattering, shards rattling, hiss, sparkle spray, whoosh, bass hit, voices, music bed or repeated notes. Original sound, centered mono-compatible image.

**2 — `sf_clear_small_b`**

> One soft rounded glass contact centered on D5, warm felt-like low body and a smooth glass overtone. Immediate single gentle attack, short silky decay, then silence. Intimate wooden-bead weight; centered, mono compatible. No shattering, rattle, hiss, glitter, whoosh, bass hit, voices, backing music or repeated notes.

**3 — `sf_clear_full_a`**

> One rounded glass release centered on D5 with a warm D4 body. Immediate soft tactile attack, fuller body and a smooth short luminous tail, then silence. Substantial but no louder than a gentle tap; centered, mono compatible. No crash, fragment rattle, rapid arpeggio, rising sweep, fanfare, hiss, whoosh, voices or backing music.

**4 — `sf_settle_a`**

> One very quiet rounded crystal seating gently into a felt-lined recess. A short muted D4 glass-and-wood tuck, one soft attack immediately at the start and almost no ring. Intimate tactile punctuation, quieter than a normal crystal tap. Then silence. No bounce, multiple contacts, debris, click burst, shattering, swoosh, bell melody, voices or music bed. Original sound, centered mono-compatible image.

**5 — `sf_win_a`**

> One tiny resolved glass-celesta phrase: soft rounded D5 contact immediately, then gently spaced A4 and D5, resting peacefully on D. Three restrained notes total, warm low body, rounded attacks, short soft decay, clean silent ending. Intimate, unhurried, centered, mono compatible. No fanfare, drums, cymbals, sweep, glitter shower, applause, voices, bass boom or backing music.

For selected masters, keep a lossless edit master and record the generator, prompt, original duration, trim, gain and any tuning. Check decoded output for clicks, clipped samples, unintended speech and extra contacts. Apply short edge fades where needed; do not stretch a poor result to fit. Audition mono compatibility and the final exported format. Reject a noisy/sharp generation before attempting heavy repair. File names, final format and bundle placement remain an integration decision.

## Listening acceptance and review order

No row below is marked passed. It requires actual generated audio and, for in-app behavior, Apple tooling plus a supported device. Source review cannot establish pleasantness, device latency, silent-switch behavior or accessibility mixing.

1. **Dry samples, volume matched:** compare both small variants and the full contact on phone speaker and headphones at comfortable low/moderate volume. Each should suggest one solid object releasing light. Reject a thin notification beep, metallic clang, harsh hiss or identifiable real-world breaking glass. B must feel like the same material as A. Full must be fuller without a startling loudness jump.
2. **One round's repetition:** audition 18 contacts in ordinary play timing, including repeated 3-shard clears and maximum-size treatment. Then audition a short rapid-input sequence. Listen for fatigue, obvious alternate cycling, smear and any accidental musical “streak.” The finite palette must remain calm after several rounds.
3. **Settling A/B:** compare otherwise identical turns with and without `settle_a`. Keep it only if listeners can better hear readiness without thinking another group cleared. The silent version is the baseline and acceptable winner.
4. **Outcomes:** test a normal win, overshoot and final-move win. Hear one primary contact and one quiet resolution, never simultaneous clear/win/loss files. A lost round should end without mockery, urgency or a reward cue. An immediately restarted round must not inherit the prior phrase.
5. **Music compatibility:** audition each retained cue against both music candidates and silence. Verify actual pitch, body and tail; no beating, tonal clash or swallowed attack. The two-note completion should feel related to the theme while remaining small enough for a single round.
6. **Actual accessibility and interruptions:** enabled sound with Calm effects, Reduce Motion and VoiceOver; invalid taps, rapid taps, Settings dismissal, restart, background/resume, interruptions and headphone-route changes. Verify one committed event maximum, clear speech, immediate cancellation, no queued burst and no sound when disabled. Exercise normal and synchronous presentation paths.
7. **Complete silence:** play a full round with Gentle sound off. Preview, legal groups, progress, recovery and win/loss must remain understandable through the existing visual and accessibility information. No rule, timing or input opportunity depends on an audio tail.

The user has made the material decision: all four quiet tucks are the anchor. The next comparison is their repeated use in native context against silence. Fuller contacts, completion and music follow in that order as bounded extensions; they must retain the chosen material. Further generation requires its own authorized scope.
