# Hosted app tests

Native tests for stores, presentation and materials that require Apple frameworks.

## Start here

Use the Starfall Xcode scheme and the relevant test identifiers. Pure package tests do not execute this suite; retain source-bound native results.

`SkyLeaderboardTests` checks pending-best durability, per-player ownership, stale callbacks, scoped caches, legacy/corrupt metadata and committed terminal-result eligibility with an injected transport; it never submits to Game Center.

`FallingSkyStoreTests` covers fresh opening cadence and clearing, alongside historical saved-clock, interruption and replay regressions.

Starlight receipt checks cover grown-value classification, dark-star exclusion, commit/restore, duplicate input, independent expiry and interruption cancellation. Audio checks cover distinct cue routing, resource decoding and ordinary-take continuity.
