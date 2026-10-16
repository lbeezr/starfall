# Starfall soundscape exploration

16 October 2026. User-requested agent swarm for music, effects and a complementary interaction-feel pass. This directory is a separate exploration handoff; the game Bible remains the design authority and the active runtime work keeps ownership of app/source/project files.

**Integration update:** the user's follow-up request connects all four selected tucks to gameplay. See [how to enable them and the implementation/validation record](INTEGRATION.md). The exploration history below predates this runtime slice.

## Selected starting direction

**A little pocket of moonlight, heard through a dry, warm, muted contact.** The user selected **all four quiet-tuck takes, 06–09**, as the starting palette and asked us to expand the world around them. The [preserved originals](selected/README.md) now have distinct filenames and provenance. Use them as alternate primary clear contacts; their original “settle” label is not a role requirement. The [current sonic direction](SONIC_WORLD.md) develops fuller contacts, a soft completion resolution, sparse warm music and a short theme from that anchor. Music remains undecided, and silence is a complete supported experience.

The first pilot uses the selected family across every group size and terminal clear. Fuller contacts and a completion phrase are later comparisons, with no reward-machine escalation. There are no cascade, streak, multiplier or automatic-clear mechanics to sonify. Invalid taps, selection preview, canceled gestures, free recovery, Settings and restart are silent. Omit a separate settling accent.

## Outputs and ownership

| Lane | Owner | Deliverable |
| --- | --- | --- |
| Audio direction and ElevenLabs preparation | Parent coordinator | [Music direction](MUSIC_DIRECTION.md), this index and [exact audition manifest](AUDITION_MANIFEST.json) |
| Sound palette | `sound_palette` | [Event coverage, bounded variants and exact SFX prompts](SOUND_EFFECTS.md) |
| Audio implementation planning | `audio_integration` | [Current seams, device policies and integration acceptance](IMPLEMENTATION_HANDOFF.md) |
| Companion interaction-feel lane | `interaction_feel` | [Sound/motion/haptic choreography and blank A/B listening protocol](INTERACTION_FEEL.md) |

The companion lane is deliberately about feel: whether the crystal contact, visual release and feedback read as one action. It does not add a mechanic, mascot, progression system or extra screen.

## ElevenLabs checkpoint

[Open the clean listening board — 21 finished takes](https://elevenlabs.io/app/flows/6OuJ7O4Fq6mbMSKCc0tG). All 21 asset references and unique labels were read back successfully. Takes 06–09 are marked **SELECTED STARTER**. This board was assembled from existing results with no new generations or spending.

Browser verification on 16 October 2026: the initial canvas appeared empty at 5% zoom with the clips outside the visible area. The Structure panel listed all 21 assets. Focusing take 06, restoring 100% zoom and panning the canvas brought its labeled waveform and Play button visibly into the user's browser. Connector readback alone had not established a usable view. This is UI visibility evidence, not listening or in-game validation.

[Original generation board, including failed attempts](https://elevenlabs.io/app/flows/wA5xekjp38SbZnBNnC0l).

Use the [numbered listening index](AUDITION_INDEX.md) to identify individual takes. It gives every successful clip a fixed number and distinct name; it does not assume that an external player displayed the same order.

- Eight original briefs: Felt Moonlight, Glass Observatory, a 12-second theme, two ordinary-clear treatments, a full-body clear, optional settle and win. Four takes per brief were submitted once, as authorized by the user up to USD 2.
- Three SFX briefs failed the provider's 450-character limit despite passing its parameter/estimate preflight. Three distinct concise revisions were submitted; original jobs and revisions remain identifiable in the manifest.
- The full original quote plus the corrective pass is **8,210.4 credits / USD 1.4928**, conservatively below the ceiling. This is a quote total, not a reconciled charge; failed-job billing/refunds are unverified.
- **Ready to hear: 20 sound-effect takes and one 12-second theme sketch.** Every SFX brief has four completed takes. A representative first take of each SFX brief plus the theme has been presented through the plugin's native audio preview; this is not a quality ranking.
- **The gameplay beds and remaining theme takes are blocked by “Insufficient funds.”** All jobs reached a terminal state at 19:10:59 UTC on 16 October 2026: 21 completed; 11 music jobs failed for funds; 12 original SFX jobs failed for prompt length and were replaced by the successful concise revisions. No music resubmission or account top-up was attempted. Job-level status is retained in the manifest.
- Exact prompts, verified parameter names and job IDs are retained locally. Only original creative briefs were sent to the plugin, not repository source or a full private design-document upload.

The repository's [AGENTS.md](../../../AGENTS.md) says “No … paid assets”; the user's explicit approval supplies a bounded exception for this audition batch. It does not approve an account top-up, subscription change or further generation. No external SDK, app network feature, account integration or publication is part of this work.

## Source reality versus the Bible's status snapshot

The current shared working tree is ahead of some implementation-status text in the Bible: touch-down preview/cancel and bounded diagonal arrival code already exist. Authored sound still does not. `GameFeedbackProviding` supplies a useful small boundary: a committed valid turn plays system sound 1104 only when Gentle sound is enabled; that setting defaults to false. There is no background music or authored sound bank today.

The team treats the Bible's aesthetic and rules as authoritative while grounding event hooks in current source. This exploration does not change the Bible's status text or the other workstreams' files. Re-read source before integration because other runtime work is active in the shared checkout.

## Review and next action

| Brief | Completed takes | Intended listening question |
| --- | ---:| --- |
| Felt Moonlight gameplay bed | 0 | Does intimate felt piano support concentration? Held for credits. |
| Glass Observatory gameplay bed | 0 | Does airy bowed glass feel spacious without becoming cold? Held for credits. |
| A Little Pocket of Moonlight theme | 1 | Does the short instrumental phrase suggest Starfall's world? |
| Warm glass clear A | 4 | Does the rounded glass/wood contact feel substantial? |
| Felt glass clear B | 4 | Is the softer contact more comfortable to repeat? |
| Full-body clear | 4 | Does body add satisfaction without a loudness reward? |
| Optional settling tuck | 4 | Does this clarify readiness better than silence? |
| Sky illuminated win | 4 | Does it resolve quietly while retaining one initial clear contact? |

Parent cross-review reconciled group thresholds (3–5 ordinary, 6+ fuller), final win duration (1.1–1.4 seconds after editing), the two-SFX-voice cap, and rapid-input coalescing. The technical owner independently checked event/lifecycle consistency. Relative document links, whitespace, manifest IDs, concise-prompt lengths and the quoted budget arithmetic passed local checks. Those checks establish handoff consistency, not sound quality.

The user has selected the four quiet-tuck takes by listening. Their in-game performance remains unverified. Generation/session IDs and original files are retained; failed music jobs have not been resubmitted. Compare effects-only against silence in native context, then test any future music with the same selected effects.

The requested integration replaces the system clear sound with a rotation of the four selected tucks, including the last clear on a win or loss. The earlier bright win candidates are not selected. Playback is local to the app, rules remain in StarfallCore, and Gentle sound stays off by default. Any later music option must be independently opt-in; an existing effects preference must not unexpectedly start a soundtrack.

The original exploration changed no source files and used document/manifest consistency checks. The subsequent runtime integration has its own [validation record](INTEGRATION.md); it does not establish subjective audible quality or physical-device acceptance.
