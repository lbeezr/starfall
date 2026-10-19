# Readiness and reward cues match the actual action

**Result:** Partially verified · **Owner:** current implementer · **Date:** 2026-10-18

A four-star square now receives its ready haptic when Core accepts that path. Retracing or adding a fifth star to an already-ready square does not signal readiness again. Recipes and relays have distinct short local sounds, routed through the existing one-voice cancellation boundary. Physical sound/haptic preference remains unmeasured.

**Delivery:** [PR #149](https://github.com/lbeezr/starfall/pull/149) merged to `b621588`; canonical updater verified **dev.9de7f44c3c** on the original phone. [Receipt](delivery.json): Core and signature passed; main CI pending at installation. No player-data reset or automatic launch.

**Next action:** Observe physical sound/haptic preference on the installed app; continue ending/replay.

## Correction and examined boundaries

The old haptic rule was `count == 5`, separate from Core's actual selected-path rule. The Store now validates path, snapshot, generation and hold ownership, asks Core whether release is legal, and sends a first-ready transition. Per-contact state resets with its existing owner. Repeated selection adds no cue. A coarse pointer sample sends one cue for its completed selection, while retaining every selected star. No feedback callback commits a move.

Focused checks cover a four-star square inside a larger group, retracing, continued selection, a regular five-star trace, invalid prefixes and expired hold/generation/snapshot requests. Existing preference, suspension, restart and selection-speech checks remain. The initial updated preference test incorrectly reused a generation invalidated by changing motion; the new guard correctly rejected it. Supplying the new live generation fixes the test without relaxing stale-input protection.

Ordinary takes still rotate across four existing files. Brilliant and constellation assets are byte-identical. Two original cues distinguish an exact recipe (0.42 seconds) and causal relay (0.54 seconds), without escalating volume or creating a queued sequence. Growth keeps its existing visual landing/grown expression and adds no automatic audio. All eight sources use the same ambient session and latest-request token: mute, background, headphone disconnection or interruption cancels pending/current audio; missed sounds never replay.

Reproduce WAVs with `python3 scripts/generate-celebration-audio.py`. [Audio metrics](audio-metrics.json) record sample rate, channels, duration, hashes, peak and RMS; new peak/RMS levels stay within the existing celebration range, with no clipped samples. Native tests decode all celebration files and actually start each of the eight bundled sources. Starting a player does not prove physical listening comfort or perceived distinction.

## Source and verification

[Source record](source.json): clean runtime `37b6198`, **dev.9de7f44c3c**, plus the subsequent native test commit. Xcode 27.1 (27A9275), Swift 6.4; Debug/Release iPhone 16 Pro Max QA, iOS 27.0 (24A434) Simulator. Only documentation/evidence paths were dirty for final acceptance.

Commands: `swift test --disable-sandbox` with `/tmp/starfall-swipe-clang` module caches; XcodeBuildMCP `test_sim` with `-sdk iphonesimulator CODE_SIGNING_ALLOWED=NO ARCHS=arm64 ONLY_ACTIVE_ARCH=YES`, the recorded runtime ID, sequential scoped tests and unique result bundles. Raw logs/bundles remain under `artifacts/reward-rhythm/`; [verification.json](verification.json) separates the original failed expectation, correction, broad hosted run and final source.

Core **172 passed**. Full hosted **301 passed** before pointer-sample coalescing; final acceptance repeats 28 affected hosted checks and three native cases successfully. Native cases cover full-motion recipe/relay results, fast same-color swaps followed by held five-star tracing, and settings/background recovery. The fourth native check verifies the same rapid swap/held trace under actual system Reduce Motion. Release Simulator build, hygiene and whitespace checks pass. No rule, RNG, save, geometry, visual award, growth animation or external dependency change. The existing Audio folder resource includes the new cues; actual bundled decoding/playback confirms membership.

Actual VoiceOver and physical haptic/audio feel remain RC/player acceptance. The wider compact-device CI triage recorded in the forecast evidence remains separate from these targeted passing checks.
