# Runtime audio

Four selected quiet-tuck MP3 variations accompany ordinary clears. Four original synthesized WAV cues distinguish large clears, drawn constellations, exact recipes and causal relays; reproduce them with `python3 scripts/generate-celebration-audio.py` from the repository root. The generator uses only the Python standard library and contains no third-party samples.

`QuietTuckPlayer` owns one audible voice, mute and interruption cancellation. All eight files are bundled by the existing Audio folder resource; ordinary take rotation remains unchanged. See [audio integration](../../docs/design/audio/INTEGRATION.md) for the historical tuck acceptance and [starlight celebrations](../../docs/design/STARLIGHT_CELEBRATIONS.md) for current tier behavior. Saved sound preferences remain authoritative.

Recipe and relay cues last 0.42 and 0.54 seconds, respectively. Their peak/RMS levels remain within the existing celebration range; they use the same single-voice replacement, mute and interruption boundary. Existing ordinary/brilliant/constellation assets are unchanged. Physical listening remains separate from decoding and native playback-start checks.
