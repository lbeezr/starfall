# Core rules and compatibility

Read the [Core map](README.md); the root contract also routes `Tests/StarfallCoreTests` work here.

- Keep Core free of UI/platform imports. Core owns seeded randomness, legality, committed outcomes and timing lookup values; rendering and animation cannot decide them.
- Preserve the Debug classic puzzle: 7×7 orthogonal board, five jewel types, groups of 3+, 70 cleared jewels in 18 valid moves, no timer. Invalid taps spend no move; a win takes precedence on the last move; dead-board recovery is free and bounded.
- Save committed state, never transient animation. Successful decoding is insufficient: validate semantic invariants before restore. Rule, RNG and schema changes need deterministic replay and old-save coverage. Preserve previews, saved generations and historical Dusk/gravity compatibility unless an explicit versioned migration supersedes them.
- Test behavioral changes with focused examples and boundary/sibling cases; keep structural extraction separate from rule/save changes. Use `swift test` from the root. Check the app consumer and target membership too: package success does not prove native integration.
- Historical rules, reset fixtures and encoded raw values are not unused merely because fresh survival no longer selects them. Inspect migration, replay, tests and offline tool consumers before removal. Consult the [experiment register](../../docs/EXPERIMENTS.md) for status and the [verification matrix](../../docs/ENGINEERING.md#verification-by-change) for consumer checks.
