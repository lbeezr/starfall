# Starfall music direction

16 October 2026. Exploration proposal aligned with [the game Bible](../STARFALL_GAME_BIBLE.md), not an amendment to it. One 12-second theme take completed; all eight gameplay-bed takes and three other theme takes failed with “Insufficient funds.” See the [overview](README.md) and [manifest](AUDITION_MANIFEST.json) for final result status. No listening or runtime integration has been performed.

## Creative recommendation

**Current anchor:** the user selected all four quiet-tuck SFX takes and asked for an expanded world around them. [SONIC_WORLD.md](SONIC_WORLD.md) sets the current direction: **Warm Stillness**, sparse middle-register felt piano, softly damped plucked strings and a distant warm sustain, with long quiet gaps. **A Small Light** is a possible short three-note theme in the same material. This establishes a creative brief, not a chosen soundtrack. The glass-led briefs below remain historical exploration records.

**Warm objects in a spacious night.** The action sound should feel close enough to hold; music should feel farther away. Start with felt piano, damped strings and a barely present warm sustain. The player supplies the rhythm by choosing groups. The score offers room to think. The selected tucks are the reference when judging a future music sketch; do not brighten them to fit an older glass-led track.

Use an instrumental identity, rather than lyrics or a narrator. A small three-note motif can connect a possible title treatment and the harmonic color of completion without requiring a story screen. A full song, separate scene soundtrack, adaptive score, ambience engine and low-move tension layer are unnecessary for this prototype.

Silence remains a complete direction, and the baseline for the listening comparison. The existing Gentle sound setting stays off by default. These sketches do not authorize turning music on for existing users or coupling a new soundtrack to that existing preference.

## Original three audition briefs — production history

| Draft | Shape | What it tests | Main rejection risk |
| --- | --- | --- | --- |
| A: Felt Moonlight | 30 seconds; warm felt piano, damped glass, faint bowed pad; unhurried approximate 64 BPM without a driving beat | Can the music make the crystals feel intimate and precious while leaving decisions unhurried? | Too sentimental, too much melody, mechanical piano pulse |
| B: Glass Observatory | 30 seconds; soft bowed glass, velvety pad, isolated plucks; no discernible pulse | Does a more spacious, suspended sound better support quiet concentration? | Cold science fiction, eerie drones, treble fatigue, musical vagueness |
| Theme: A Little Pocket of Moonlight | 12 seconds; one small motif in the A palette with a tender resolution | Does Starfall have a memorable musical identity without a fanfare? | Commercial jingle, music-box cliché, overly grand ending |

A was the provisional lead and B the contrast before the user's quiet-tuck selection. The current lead is Warm Stillness in [the expanded brief](SONIC_WORLD.md). The existing theme remains an unselected concept sketch, not approved menu or launch behavior. Do not play it at every restart or while dismissing Settings.

## Initial musical grammar — revise around the selected material

- Provisional D-major pentatonic palette: D, E, F-sharp, A, B, with restrained D/A support. Avoid busy chord changes; independently generated cues need a simple harmonic home.
- Theme contour proposal: D4 → A4 → F-sharp4, with pauses, then resolution. The short win cue can use D5 → A4 → D5; it shares the tonal world rather than reproducing the whole title phrase.
- All specified notes, tempo and instruments are prompt intent. Verify the actual output by ear or analysis before selecting or tuning cues. Generated files are not guaranteed to obey pitch instructions or match one another.
- No vocals, choir, spoken rewards, ticking, percussion pressure, bass drops, crescendos tied to remaining moves, or escalating pitch for repeated clears.
- Prefer a warm middle register, rounded attacks and narrow, comfortable stereo. A phone speaker and mono fold-down must retain the essential body. No hard-pan motion tied to cells or jewel types.
- Music should never carry progress, group size, recovery or outcome information exclusively. Existing visual and VoiceOver information remains authoritative.

## Use during a round

If a bed is selected for a later implementation, keep it steady across thinking, clearing and refill. No faster tempo, extra stems or louder mix near the goal or last move. The first effects pilot uses a selected tuck on winning moves too. If a completion extension is later selected, it replaces that contact with one integrated phrase; avoid stacking a second musical climax over it. A loss needs no punitive sting. Free board recovery needs no reward sound.

Do not hold the next interaction for music. A terminal phrase can decay under the existing result UI and must be cancellable on New game, leaving play, disabling sound or app interruption. Resume must not replay the last clear or outcome. Exact fade and audio-session policy belongs to [the implementation handoff](IMPLEMENTATION_HANDOFF.md).

## Loop and mix preparation after selection

The 30-second clips are mood sketches, **not verified seamless loops**. Prompting for compatible endpoints is only a starting point. Select the tone first; only then prepare a longer, quiet repeat if listening shows the short material becomes obvious. Do not commission a full soundtrack before this decision.

For any candidate loop, find musically compatible boundaries, preserve reverb tails, edit a crossfade if needed, then listen across at least ten consecutive seams. Check for clicks, level jumps, shortened notes, phase cancellation and an obvious recurring event. Confirm the exported format and actual native player also repeat cleanly. A waveform inspection or successful decode alone cannot establish that the seam sounds good.

Match perceived loudness before comparing A and B; avoid choosing the louder file by accident. For the first combined audition, start music roughly 8–12 dB below the clear cue's perceived prominence and adjust by listening. This is a mix starting point, not a loudness standard. Short cues need peak and transient inspection as well as ears; integrated loudness numbers are weak comparisons for sub-second sounds.

Leave headroom for coincident music and the single foreground cue. Reject clipping, brittle glass, excessive low end, audible background hiss and loss of body in mono. Keep final short cues dry enough that repeated legal moves do not build a wash of reverb. The proposed settle accent must earn its place in an A/B comparison with silence.

## Production checkpoint

The complete exact prompt text, model IDs, durations and remote node IDs are in [AUDITION_MANIFEST.json](AUDITION_MANIFEST.json). The connected workspace exposed Music v2 and Sound Effects v2; their parameter schemas were read before drafting. Music v2 is selected explicitly, consistent with the Music skill, rather than assuming the workspace default.

The board has two gameplay sketches, one theme sketch and five sound-effect briefs. The initial quote for four takes per brief was **8,087.2 credits / USD 1.4704**. The user approved this batch up to USD 2. Three overlong SFX briefs passed preflight but failed the provider's 450-character limit; distinct shorter revisions were quoted at another **123.2 credits / USD 0.0224** and submitted. Conservatively counting both full quotes gives **USD 1.4928**. These are estimates, not a reconciled bill or proof of available account credit. Music jobs subsequently reported insufficient funds; they were not resubmitted. No subscription change, overage purchase, publishing or runtime dependency is included.

Audition candidates are not production assets until they pass the [interaction-feel listening protocol](INTERACTION_FEEL.md), are edited and checked for the intended use, and an implementation is separately validated. No current listening, simulator, device, performance or loop-seam acceptance is claimed.
