# Quiet-tuck gameplay integration

16 October 2026. User requested the four selected sounds in actual play. After trying the integration, the user confirmed: “I like the sounds when I touch the little stars in the game,” and requested the changes be merged. The four-take palette is accepted as the starting sound for valid clears.

## Try it

Open **Settings → Gentle sound**, turn it on, then return to play. Every valid clear rotates through quiet tucks 01, 02, 03 and 04. The four variants are shared across group sizes and jewel kinds, including the final clear on a win or loss. Invalid taps, canceled previews, refill, recovery and navigation add no sounds. Gentle sound remains off on a fresh install.

## Implemented behavior

- `GameFeedback` replaces system sound 1104 with a local `QuietTuckPlayer`. Gameplay commits still happen before feedback; sound never controls moves, saving, animation or unlocking input.
- The selected MP3s are bundled under `App/Audio` and match the [original checksums](selected/file-integrity.json). No source edits, normalization, pitch shifting or regeneration were applied. Playback gain is 0.7 for headroom; there is no group-size gain increase.
- Four players load lazily at the first eligible clear, on a dedicated serial audio queue. Decoding, session activation/deactivation and playback setup stay off the UI thread. One player is audible at a time; a new clear replaces the previous tail. Rotation belongs to feedback and does not consume core RNG. Playback failures leave the game playable and do not queue retries.
- Muting, restart, opening Settings, leaving play, scene settlement, inactivity and headphone disconnection invalidate pending requests synchronously and stop playback on the audio queue. The worker rechecks its request token after loading, activation and preparation, so a slow operation cannot revive an obsolete contact. Interruption start suppresses new contacts; ending it does not replay missed cues. The next eligible explicit tap resumes the rotation.
- The app uses Apple's optional `.ambient` session category. It does not enable background audio or add external SDKs/network access. Platform intent is mixing with other audio and respecting system silent mode; physical-device behavior still needs listening checks.
- Calm effects and Reduce Motion keep the sound preference independent. An actual VoiceOver result announcement stops any remaining game-audio tail before posting speech, without delaying the announcement.

The user-selected palette is integrated; a special completion phrase and music remain future exploration in [the sound-world brief](SONIC_WORLD.md).

## Validation

Executed with Xcode 27.0 (27A266a), iPhone 17 Pro simulator “Starfall QA iPhone,” iOS 27.0 (24A434), on 16 October 2026:

- `swift test`: all 27 core tests passed. Simulator build succeeded; all four bundled MP3 hashes match the selected originals, and no background-audio mode was added.
- Initial native regression run: 43 hosted app tests and six UI tests passed (49 total, zero failures/skips), recorded in `/private/tmp/starfall-audio-tests.xcresult`. UI coverage included normal play, rapid input and drag cancellation, accessible-board controls, Settings Done and interactive dismissal, restart, saved resume/Calm effects, win, final-move win and loss.
- The shared working tree included another workstream's interactive Settings dismissal test edit. It was exercised in that run and remains with its owner; this audio commit contains only the added sound-on UI test.
- That run exposed synchronous audio-session activation on the UI thread. The final worker moves all player/session setup to a serial queue and rejects stale tokens. Rebuilt and reran the affected store/audio tests and sound-on UI scenario: **18 passed, zero failures/skips and zero runtime warnings**, in `/private/tmp/starfall-audio-queue-tests.xcresult`. This includes all four native playback-start callbacks, missing-resource handling, interruption/route policy, queued mute cancellation and replacement of superseded requests. The compiler emitted no Swift warnings; Xcode's unrelated AppIntents metadata-extraction notice remained.
- The intermediate `/private/tmp/starfall-audio-final-tests.xcresult` run completed its test cases but its command hung resolving the local package; it was terminated and is not the final acceptance result. The clean final run used `-disableAutomaticPackageResolution -skipPackageUpdates` and exited successfully.
- Opened the final app in Device Hub, visually verified Gentle sound on, dismissed Settings, continued the terminal fixture and started a fresh normal round at 0/70 with 18 moves. Left that round open for the user's audition. No demo arguments or gameplay bypass are active in this handoff.

A successful native player start establishes decoding/playback API behavior, not the sound heard from a speaker. Actual VoiceOver speech and live system Reduce Motion operation were not exercised; accessible controls, Calm effects and the reduced-motion code paths were checked. Physical silent-switch/routes, haptics, speaker balance, first-contact latency and subjective repetition comfort need listening on the intended device. The agent has not claimed to hear or approve the final mix.
