# Hosted app tests

Native tests for stores, presentation and materials that require Apple frameworks.

## Start here

Use the Starfall Xcode scheme and the relevant test identifiers. Pure package tests do not execute this suite; retain source-bound native results.

`SkyLeaderboardTests` checks pending-best durability, per-player ownership, stale callbacks, scoped caches, legacy/corrupt metadata and committed terminal-result eligibility with an injected transport; it never submits to Game Center.
