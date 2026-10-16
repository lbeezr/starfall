# Starfall interaction feel and audition plan

Prepared 16 October 2026. **Design proposal and blank test materials only.** This interaction-feel lane generated no audio and performed no listening, integration, participant, simulator or device session. A separate authorized generation batch is tracked in the [audio overview](README.md) and [audition manifest](AUDITION_MANIFEST.json); consult those records for its current status. The companion workstream is the feel of one complete turn: sound, crystal motion, optional haptics and silence.

## Direction and evidence boundary

Follow the [game bible](../STARFALL_GAME_BIBLE.md): quiet wonder, tactile delight and gentle concentration. A group releases one small pocket of light. Let the crystal feel substantial at contact and airy as its light escapes. Silence between actions is part of the rhythm; nothing urges the next tap. A large group is a fuller release, never a slot-machine payout, multiplier or automatic chain reaction.

Keep the existing 7×7, five-kind, orthogonal 3+ game and 70-in-18 tuning. One accepted group is one move; invalid taps are free; newly formed groups need another tap. A final-move win wins. Free recovery replaces three bottom cells and does not shuffle the board. These constraints govern both what a cue suggests and what it actually triggers.

The bible is the creative authority, but its implementation-status paragraphs are older than parts of this working tree. Baseline below comes from source inspected on this date: [GameFeedback.swift](../../../App/GameFeedback.swift), [GameStore.swift](../../../App/GameStore.swift), [JewelScene.swift](../../../App/JewelScene.swift), [StarfallArrivalEffects.swift](../../../App/StarfallArrivalEffects.swift) and [StarfallApp.swift](../../../App/StarfallApp.swift). The checkout contains uncommitted work; a base commit alone cannot identify an audition build. Source inspection does not establish how these effects feel or sound on a phone.

- **Sound now:** Gentle sound is off by default. When enabled, every accepted clear calls system sound `1104`, including terminal turns. No bespoke clear, music, loss, recovery or per-shard cue is present in this feedback boundary.
- **Haptics now:** a soft impact at intensity `0.45` occurs on ordinary accepted turns, including loss; a success notification replaces it on a win. Calm effects and system Reduce Motion suppress both. This is independent of Gentle sound and currently has **no separate haptic opt-in**. Sound off alone is not haptics off.
- **Touch now:** one touch previews a valid connected group with static emphasis; ending in the same cell commits. Moving to another cell or cancelling abandons it. Preview does not spend a move. Invalid taps update explanatory text and may nudge the tapped piece; they do not call the clear sound/haptic path.
- **Turn now:** rules, score and save commit before presentation. The normal source timeline is 200 ms clear plus up to 280 ms arrival: survivors move down first, refills enter diagonally down-left, recovery cells appear in place. These are scheduled durations, not measured device timings. Calm effects/Reduce Motion use a settled alternative. Settings, restart and backgrounding settle committed state and invalidate old presentation callbacks.

## One-turn choreography proposal

**User listening update:** all four quiet-tuck takes, 06–09, are selected as the starter palette and wider world's inspiration. Use one short, dry, warm contact at commitment, rotating the four through all group sizes and terminal clears. The initial references below to a glass note, airy tail, wider harmony or win phrase are historical extension proposals. The [current direction](SONIC_WORLD.md) takes precedence. User selection does not establish haptic preference or synchronization on a device.

Timing is relative to an accepted touch-end (`t = 0`), never to touch-down. Preserve the current input lock and its settled completion; audio duration must not extend that lock. The windows below are creative starting points, not measured performance requirements.

| Event | Existing behavior | Proposed sound, motion and haptic relationship |
| --- | --- | --- |
| Touch preview / cancellation | Static valid-group emphasis; no sound or haptic | Keep it quiet. The visible group is the preview; cancellation must leave no clear cue or trailing “reward.” Avoid a touch-down note followed by a second note for the same choice. |
| Invalid or diagonal-only tap | Free explanatory feedback; optional nudge; no clear cue | Keep sound and haptics silent. Preserve text and VoiceOver explanation. No error buzzer, failure chord or warning color flash. |
| Normal clear, 3–5 shards | System cue at commit; one soft impact; bounded clear and arrival | At `t = 0`, one warm glass note with a soft, definite attack, aligned with the beginning of release. An optional soft impact occupies that same moment, never the end of the ring. Let a quiet airy tail decay through the 0–480 ms turn. Start with **no separate landing sound**; compare a single very low settling accent only if it helps explain completion. |
| Full clear, 6–9 shards; 10+ reuses the same full cue | Same feedback call; visual debris/trails have global caps | Use the same gesture and timing with a slightly rounder body or wider harmony. Do not raise intensity with every shard, add one note per cell or increase haptic count. These buckets align with the [sound-effects proposal](SOUND_EFFECTS.md) and add no gameplay rule or reward tier. Test the largest reachable group as well as an ordinary full clear. |
| Win, including a win at zero moves | Same system cue; success haptic replaces ordinary impact; result text is authoritative | Replace the ordinary clear sound with one short resolved phrase whose opening is the clear attack; target 1.1–1.4 seconds including decay after editing a 1.6-second generated source. No stacked clear-plus-win blast. Existing result information and New game remain immediately usable. A completion glow stays within the bible's restrained proposal; it is not a prerequisite for the sound study. Optional success haptic replaces, never adds to, the ordinary pulse. |
| Loss after the last valid clear | Ordinary clear cue/soft impact; terminal text | Keep the final clear dignified and satisfying, then allow silence. First audition has **no loss sting**. If testing a closing tone later, make it brief and neutral; no descending scold, depleted heartbeat, ticking or restart prompt. A loss cannot take precedence over a simultaneous win. |
| Free dead-board recovery | Same accepted-turn feedback; bottom replacements fade in; status explains no extra move | Keep recovery silent in the first audition. The replacement and message carry its meaning. No shuffle sweep, extra impact or three-hit sequence that suggests three paid actions. If a subtle air accent is tested, it belongs to the same turn and replaces a settling accent. |
| Menu / restart / settings / resume | Controls and committed-state recovery already exist | First audition adds no decorative UI cues. New game and resume must not replay an old clear, win or recovery. Stop pending turn tails on interruption; return quietly and never auto-enable sound. |

If background music is auditioned, use a sparse instrumental bed that leaves room for the clear attack and pauses. Test **effects alone first**, then compare the exact same effects with the bed. A theme motif can live in that bed or the completion phrase; a separate vocal song or repeated musical reward is not needed to establish the world. Do not make music accelerate, brighten or become insistent near zero moves. Music remains an optional creative experiment, not a new gameplay requirement.

For a future local audio pilot, keep a hard cap of two simultaneous action voices, including attacks, tails and any settling accent, plus one optional music bed; a new action may shorten the older voice. Count a completion phrase as one action voice. Do not queue ignored taps, randomize using the game's RNG, derive points from an audio callback or wait for a tail to unlock play. On the synchronous Calm/Reduce Motion path, after at least one audible clear, coalesce ordinary cue requests within a provisional 120 ms window, as specified in [SOUND_EFFECTS.md](SOUND_EFFECTS.md), while preserving every accepted rule action and its visible/spoken result. Do not defer suppressed cues; terminal cues bypass this cooldown and retain priority. The voice cap holds on every path. These are proposed integration constraints, not implemented behavior.

## Access, silence and participant choice

The round must be understandable with sound and haptics absent: current group emphasis, score/moves, result text and accessible group/result descriptions remain sufficient. Do not assign essential meaning only to pitch, stereo location, vibration or a music change. No separate sound is needed for the five colors/shapes; their identity already has visual and spoken descriptions.

Keep Gentle sound off by default and preserve the existing Calm effects/Reduce Motion suppression. Do not silently reinterpret the current settings during an audition. Ask participants which setup they normally prefer and obtain an explicit opt-in before a physical haptic comparison. In the current build, enabling Calm effects suppresses haptics **and changes motion**, so it is not a controlled haptics-only A/B. Record that confound. An independent haptic preference for a future build would need a small explicit settings change, default-off migration and acceptance review; this document does not implement or claim that control.

With VoiceOver, speech takes priority: audition cue tails beneath actual announcements and omit optional music/settling detail if it masks them. Test traversal and outcome focus, not merely the existence of labels. Reduce Motion/Calm effects retain static emphasis and immediate settled states without tilt, flying fragments or trails; no replacement pulse or louder sound should compensate for omitted motion. Haptics are optional decoration and cannot be validated in a simulator. Do not ask participants to disable an access preference to complete a trial.

## Quick listening comparison, then native context

Use this as an optional module **after** the uncoached play and replay questions in [FIRST_PLAYTEST_PROTOCOL.md](../FIRST_PLAYTEST_PROTOCOL.md). The [playtest kit](../PLAYTEST_KIT.md) remains the separate survivor-planning probe; audio testing must not pre-teach its answer. A short listening comparison can reject a brittle or busy candidate, but cannot establish native timing, haptic feel, overall accessibility or replay appeal.

1. **Prepare two matched candidate sets, when assets exist.** Use the same events, spacing, format and perceived playback level. Keep meaningful attack/decay differences; do not compare a deliberately louder “premium” candidate. Give sets neutral codes X/Y; keep generation prompts and style names out of view. The moderator retains the code key. This is single-blind listening, not a claim that creators or moderators are blind.
2. **Start with control and comfort.** Let the listener choose a comfortable low volume on their preferred output and stop at any time. Record speaker/headphones and volume setting; keep that setting unchanged within the pair. Do not force headphones or a hearing threshold. A person preferring silence can evaluate the silent in-context path instead.
3. **Play one 20–30-second sequence per set.** Include three ordinary clears, a large clear, another ordinary clear and a win; leave enough silence to hear each decay. Present a second short ending sequence with the same final clear followed by silence to represent loss. Do not narrate candidate qualities or score labels over playback. Six participants, if available: alternate XY/YX with three in each order. Do not reuse repeated exposure as another participant.
4. **Ask before revealing labels.** “What did these sounds make you picture?” “Which feels more comfortable to hear repeatedly, or neither?” “Did anything feel sharp, urgent, rewarding in the wrong way, or hard to hear?” Rate warmth/tactility, calmness, clarity and fatigue each 1–5 (fatigue: 1 none, 5 strong), with one reason. Permit tie/neither/silence. These are informal design ratings, not validated scales.
5. **Isolate the music question.** With the preferred effect set unchanged, compare 30 seconds with no music and 30 seconds with the proposed bed. Alternate order across listeners. Ask whether it supports attention or competes with choices. Do not conflate an effects preference with a preference for music.
6. **Check repetition.** If comfortable, replay 12 clear cues at one-second spacing, then a 10-second denser sequence at the native pilot's accepted-action cadence. Compare first and last impressions. Never encourage hurried game decisions; this is an optional prepared playback. Stop on discomfort. Record a wish to mute as a useful finding, not a failed participant.
7. **Validate the selected candidate in an identified native pilot later.** Run normal play uncoached with the person's preferred access setup. Manual playback beside the app does not prove synchronization. Test rapid input and lifecycle separately as QA, with real integrated playback. For win/loss/recovery that do not arise naturally, mark participant evidence not observed; native QA may use existing authorized fixtures, separately labeled.

Prefer the simpler cue when preferences tie. Reject a candidate with repeated sharpness/pressure complaints even if its first impression is impressive. With six listeners, report exact counts and disagreements; do not claim statistical superiority or a universal preference. Do not tune 70/18 from this study.

### Blank listening sheet

Date: ______ Build/source or playback version: ______ Asset hashes/versions: ______ Moderator: ______

Keep the X/Y code key in moderator notes until answers are complete: X = ______ Y = ______

| Listener | Output + volume; access preferences | Order | Preferred X/Y/tie/neither/silence + why | Warmth / calmness / clarity / fatigue, X then Y | Music or silence + why | Repetition change; exact quote |
| --- | --- | --- | --- | --- | --- | --- |
| P1 | | | | | | |
| P2 | | | | | | |
| P3 | | | | | | |
| P4 | | | | | | |
| P5 | | | | | | |
| P6 | | | | | | |

Missing exposures / stop requests / assistance: ______

Exact preference counts and shared concerns: ______ Next bounded revision: ______

### Blank in-context acceptance sheet

Build + source snapshot: ______ Device/OS: ______ Candidate assets: ______ Tester/date: ______

Use P = observed pass, F = observed failure, NO = not observed. Leave rows blank until run; record expected and actual separately. Speaker and headphones are separate exposures. Audio behavior on Ring/Silent, other audio playing and interruptions is unverified until observed on the target device; choose and record the intended native audio policy before testing.

| Exposure | Expected acceptance | Result P/F/NO + actual observation / evidence |
| --- | --- | --- |
| Ordinary clear; preview; cancel; invalid tap | One cue only on an accepted clear. Preview/cancel/invalid taps spend no move and produce no reward cue; group, count and result remain understandable. | |
| Large clear; refill; recovery | Fuller release has no extra points/hits. Survivors still read as vertical; recovery reads as three free replacements, not a shuffle. No per-piece audio barrage. | |
| Rapid taps, normal and Calm paths | Ignored touches produce nothing. Every accepted action preserves its correct state/result, while ordinary cues less than 120 ms apart may coalesce on the synchronous path. At most two action voices sound together; tails do not accumulate or get loud. Terminal cues retain priority. No queued cue plays after the board is settled or reopened. | |
| Win at zero moves; ordinary loss | Correct result and one appropriate cue family; no failure sound on a win, no stacked success pulses, no pressure to restart. | |
| Restart; background/resume mid-clear; Settings open/Done/swipe dismissal | Correct saved board and counters; pending feedback does not replay; controls regain access. Sound preference persists and returning is quiet. | |
| Five minutes or a completed round, whichever is comfortable | No increasing brittleness, masking, repetitive irritation or feeling hurried. Record discomfort, mute choice and duration; incomplete rounds stay incomplete. | |
| Phone speaker, quiet ordinary room | Warm attack remains intelligible at comfortable low volume; no need to boost a disappearing bass-only cue. Music does not hide clear feedback. Record room and volume. | |
| Headphones, chosen comfortable volume | No piercing transient, excessive stereo movement or tiring high ring; clarity survives mono playback. Do not increase volume to compensate for a weak design. | |
| Sound off; haptics suppressed | Complete playable information survives; no essential event is lost. Current Calm effects setting also changes motion: record it. | |
| Calm effects; system Reduce Motion | Settled/static presentation; no forbidden motion or added vibration. Rapid accepted-action sound overlap remains bounded. | |
| VoiceOver, actual use | Group/position/size, invalid reason and results can be heard; cues do not obscure speech; activation/focus/settings return work without sight. | |
| Physical haptics, explicitly opted in | One quiet tactile acknowledgement per accepted turn; win replaces it. Invalid/cancel taps stay quiet; recovery adds no separate vibration. Suppression works. Record device and participant preference. | |
| Ring/Silent, other audio, audio interruption/output change | Behavior matches the recorded policy; no surprise resume blast, forced volume change, new sound enablement or stale outcome replay. | |

## Best next companion workstream

**Run a bounded native interaction-and-accessibility acceptance pass before adding more presentation.** The repo already has a first-playtest protocol and verified print kit, while their human observation fields are empty. This inspection also exposes an actionable decision gap: haptics are currently automatic outside Calm effects/Reduce Motion, and authored sound has no device evidence. Together, these warrant testing one whole interaction on a real phone with sound on/off, preferred motion settings, VoiceOver and rapid/interrupted input.

The output should be a completed sheet above, with build/asset identity and one prioritized correction supported by observations. Reuse the existing runtime owner and native fixtures; do not create another UI framework, balance study, mechanics lane or asset-generation backlog. Keep any crystal-source recovery work with its existing owner. A listening winner becomes a candidate for this pass, not an accepted production soundscape.
