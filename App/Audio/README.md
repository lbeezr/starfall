# Runtime audio

Four selected quiet-tuck MP3 variations accompany ordinary clears. Six original synthesized WAV cues distinguish large clears, drawn constellations, exact recipes, historical causal relays and current Story cascade phases; reproduce them with `python3 scripts/generate-celebration-audio.py` from the repository root. The generator uses only the Python standard library and contains no third-party samples. The four selected MP3s and four earlier WAVs remain byte-identical.

`QuietTuckPlayer` owns one audible voice, mute and interruption cancellation. All ten files are bundled by the existing Audio folder resource; ordinary take rotation and historical relay routing remain unchanged. See [audio integration](../../docs/design/audio/INTEGRATION.md) for the historical tuck acceptance and [starlight celebrations](../../docs/design/STARLIGHT_CELEBRATIONS.md) for tier behavior. Saved sound preferences remain authoritative.

## Current Story chain phrase

The existing recipe accent resolves E5 → G5. A committed `.cascade(2)` answers A5 → C6 with `sf_cascade_2.wav`; `.cascade(3)` and every deeper phase resolve D6 → E6 with `sf_cascade_3.wav`. Each accent contains two short bright paired tones over the same soft contact/envelope as the recipe. These are original synthesized notes, not shifted copies of the selected sounds. The contour is a design choice for this bounded enhancement, not measured listening preference.

Each new accent is 0.42 seconds, mono 16-bit PCM at 44,100 Hz, exactly 37,088 bytes. Added file bytes total 74,176. Gain, duration and the number of audible voices do not grow with depth; audio variation caps at phase three independently of the existing ×5 scoring cap. A new independent action's recipe receipt returns to E5 → G5 without a remembered streak, clock or reset callback. Historical `.relay` receipts keep `sf_relay.wav` at every depth.

Measured generated PCM has no clipped samples. Peak/RMS levels are −9.039/−23.189 dBFS for the recipe, −5.981/−23.186 for cascade two and −6.722/−23.154 for cascade three. The new peaks are higher than the earlier WAV maximum of −8.787 dBFS; their similar RMS values do not establish equal perceived loudness. Native playback and physical listening remain separate checks.

Normal presentation requests each committed phase's accent. Existing quiet presentation requests only its final aggregate receipt; it never queues the omitted phases. Muting, supersession, interruption, background and route changes retain the existing cancellation owner and never replay a missed cue. No playback callback awards points or controls input. Physical listening and enjoyment remain separate from PCM analysis, decoding and native playback-start checks.
