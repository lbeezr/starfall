# Native interaction tests

XCTest flows exercising the app through native controls on Apple tooling.

## Start here

Run relevant flows through the Starfall scheme. Keep bounded condition-based waits and isolated test saves. Report actual VoiceOver and full-motion observations separately from automation.

`ConstellationTraceNativeTests` verifies selected five from six, short/outside cancellation, ordinary taps, retained relaunch and largest-text tracing/build metadata in the same Starfall target. Fixtures require Debug and explicit local reset arguments.

`ShowerForecastInteractionTests` checks production camera/header placement, ordered forecast speech value, menu/background lifecycle and maximum-text fallback. Run it on a calibrated island phone and a non-island phone; inspect the attached captures separately from physical-device acceptance.
