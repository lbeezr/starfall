# StarfallCore

Deterministic rules, seeded randomness and committed save/outcome values, without UI imports.

## Start here

Run `swift test` from the repository root. Preserve replay and old-save invariants when rules, RNG or schema change; see [repository boundaries](../../AGENTS.md).

Constellation walks add explicit five-distinct-star validation and selected-set clearing; ordinary `group`, `legalGroups`, `clear`, save fields and generator relief remain compatible. `ConstellationFixture` compiles only in Debug for deterministic native/core tests.
