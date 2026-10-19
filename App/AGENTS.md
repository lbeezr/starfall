# Native app, hosted and UI checks

Read the [App map](README.md). The root contract also routes `AppTests` and `UITests` work here. Keep one normal Starfall target; do not turn reset fixtures into player routes.

## State and presentation

- Keep app/store/scene mutation on the main actor. Own and cancel tasks, deadlines, observers and actions explicitly. Restart, backgrounding, settings and scene replacement must reject stale completions. Preserve generation guards, the single-deadline clock and no queued catch-up showers.
- Keep injected clock, presenter and feedback capabilities small. Pass values or narrow dependencies instead of entire stores or unrelated mutable state. Cross concurrency boundaries with value snapshots. Do not suppress isolation diagnostics with unchecked Sendable or unsafe isolation without documenting and testing actual synchronization.
- Save committed Core state; validate restores and preserve replay/old-save contracts. Scenes present committed turns. Never derive rules or schedule decisions from node positions or animation completion.
- Bound nodes, particles, textures, audio voices and caches. Keep IO, decoding, artwork generation and broad SwiftUI updates out of per-frame paths. Profile a reproducible scenario before pooling, background work or new abstractions.

## UI contracts

- Own reusable typography, spacing, colors and control roles in `StarfallTheme`. Reuse the bounded jewel material/asset factory. Keep the board dominant, secondary actions/instructions outside the playfield, jewel proportions intact and visible square cell backgrounds absent unless requested.
- Rendering, native hit cells and accessibility cells share one coordinate mapping, including resize and row direction. Geometry changes need real native taps. Preserve stable cell/gem identities, native button semantics, non-color cues, full touch targets and readable Dynamic Type; reflow controls instead of shrinking text.
- Keep full animations in normal play. Calm effects, VoiceOver and system Reduce Motion must preserve committed outcomes and usable input. Still screenshots and animation-suppressed tests cannot establish falling-animation behavior.

## Native evidence

Use the [verification matrix](../docs/ENGINEERING.md#verification-by-change). Exercise relevant normal play, rapid input, win/loss, restart, background/resume, Reduce Motion and settings dismissal. Inspect screenshots as well as assertions: hittable controls can still wrap or crowd the board. Follow [screenshot practice](../docs/SCREENSHOTS.md), starting from the selected capture index and updating affected entries.

Use lightweight development accessibility checks; full actual VoiceOver acceptance belongs at RC, including the first release, under the [stage policy](../docs/DEVELOPMENT_BUILDS.md#accessibility-checks-by-build-stage). Do not run full sessions for routine iteration. A targeted VoiceOver defect still needs its actual reproduction.

Keep reset data deterministic, local and isolated from normal saves. Use bounded condition waits and existing native scroll helpers. A historical-mechanic test needs a retained-history fixture; fresh-sky tests must assert current rules. Preserve outcome assertions and test counts when repairing setup. Verify new source/resource membership and Release for routing/build/resource/Debug-fixture changes. Record unverified interaction, motion and physical acceptance explicitly.
