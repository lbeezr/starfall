# Native interaction tests

XCTest flows exercising the app through native controls on Apple tooling.

## Start here

Run relevant flows through the Starfall scheme. Keep bounded condition-based waits and isolated test saves. Report actual VoiceOver and full-motion observations separately from automation.

`ConstellationTraceNativeTests` verifies selected five from six, short/outside cancellation, ordinary taps, retained relaunch and largest-text tracing/build metadata in the same Starfall target. Fixtures require Debug and explicit local reset arguments.

`testNativeTraceHeldAcrossAutomaticDeadlineCannotCommitStaleSelection` moves through the five-star diagonal fixture, holds the finger down across automatic rain, and checks that the stale selection cannot score. Hosted checks own exact deadline arithmetic; native execution and its limits belong in the source-bound acceptance report.

`testOpeningCascadeAllowsNativeClearBeforeLastWave` verifies an actual clear during the intro with Calm and system Reduce Motion off, restoring the system preference afterward. Inspect recorded motion separately from the tap assertion.

`PacingCueUITests` checks baseline isolation; B flows run only in the explicit pacing candidate export. They cover one-wave warning, faster/breathing labels, Settings dismissal, persistent largest-text cues and system Reduce Motion with restoration.

Its active forecast/phase check verifies the final presentation integration: separate vertical space, conservative B header fallback, accessible forecast value and unchanged native cell frames.

`ShowerForecastInteractionTests` checks production camera/header placement, ordered forecast speech value, menu/background lifecycle and maximum-text fallback. Run it on a calibrated island phone and a non-island phone; inspect the attached captures separately from physical-device acceptance.
