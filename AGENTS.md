# Starfall repository instructions

Keep one small, offline iOS 17+ game using SwiftUI and SpriteKit, shared scheme `Starfall`. Falling sky is the normal Debug/Release game: deterministic accumulating stars, automatic showers with pause, local balance controls, and traces through at least five actual matching stars that clear only the traced set. Automatic critical-mass aging stays disabled in fresh and restored survival skies; historical Dusk rounds remain supported. New falling-sky Lantern Landing and Ribbon Crossing visits use revision-4 authored rules with 150,000/220,000-point objectives. Ribbon Entry also offers revision-7 Full Board: untimed refill toward 220,000 points with its own survivor opening. Lantern Entry offers revision-6 Full Board: untimed refill toward 150,000 points with a revised opening. Retained Full Board revision-5 saves and same-round Replay keep their exact opening and supply; explicit new Lantern Full Board visits select revision 6. New Kite Harbor visits use its revision-4 headroom encounter and 17,000-point objective. New Seed Moon visits use its revision-4 grown-ingredient encounter and 11,000-point objective. New Silver Pools visits use the development-verified revision-4 sequencing encounter and 12,000-point objective. New Frostfruit Orchard visits use revision 8’s pressure/growth encounter and 15,000-point objective; retained Frostfruit0 keeps manual 18-light rules. Authored Frostfruit1–7 and Kite/Seed/Silver1–3 do not exist. Historical revision-0 challenge saves and same-round replay retain their original 18-light rules; explicit new visits select the current definition. The original 7×7 puzzle remains Debug regression tooling.

The user-authorized local world journey unlocks ready restoration locations and records completed repairs; tutorial practice never earns progression. No XP, power-ups, backend, accounts, paid assets, external SDKs, purchases or analytics. Ad/IAP SDKs, entitlements, tracking and monetization UI must remain absent. Any future monetized product needs a separate opt-in target with conditionally linked dependencies; a runtime hide flag is insufficient. Do not change another repository or add network features without a new request. Apply accepted work to the normal app; separate lab/control apps require an explicit user request. Reset-only Debug fixtures are test tooling.

## Read the applicable boundary

Before editing, inspect `git status --short`, the relevant folder README and local instructions. A root-started session must explicitly read these files; child instructions are not assumed to be preloaded.

| Work | Read |
| --- | --- |
| Rules, RNG, saves, Core tests | [Core instructions](Sources/StarfallCore/AGENTS.md), including work under `Tests/StarfallCoreTests` |
| App, hosted tests, native UI tests, resources | [App instructions](App/AGENTS.md), including `AppTests` and `UITests` |
| Scripts, CI, build or delivery tooling | [Tooling instructions](scripts/AGENTS.md), including `.github/workflows` |
| Plans, designs, reports, README changes | [Documentation instructions](docs/AGENTS.md) |

For level artwork and restoration compositions, use the [level-design kit](docs/design/level-design-kit/README.md) and [level-design skill](.agents/skills/starfall-level-design/SKILL.md), including the camera, native layout/bleed templates and actual-star scale references.

For screen, HUD and interactive-map production, use the [UI production skill](.agents/skills/starfall-ui-production/SKILL.md): establish component/state/asset contracts and prove one native slice before expanding the artwork family. Complete gameplay paintings retain the level-design contract.

The user's primary gameplay inspiration is **Pokémon Puzzle League (Nintendo 64)**. When uncertain about mechanics, progression, difficulty, scoring, spectacle or multiplayer, consult the [reference and adaptation guide](docs/design/POKEMON_PUZZLE_LEAGUE_REFERENCE.md), verify its actual behavior and propose how Starfall can develop it further. Keep reference facts, proposed adaptations and implemented rules distinct.

Future local-network versus and cooperative restoration between nearby iPhones/iPads are user-requested directions, evoking linked handhelds and couch play. Record them in design work; the current scope remains offline until a multiplayer implementation task. No account, backend or online matchmaking is implied.

For recurring work, load only the relevant repo skill: [verify](.agents/skills/starfall-verify/SKILL.md), [CI triage](.agents/skills/starfall-ci-triage/SKILL.md), or [bounded maintenance](.agents/skills/starfall-maintenance/SKILL.md). Skills reuse the contracts below; they add no approval gates or delivery authorization.

For a requested agent factory/swarm or substantial parallel delivery, use the [factory skill](.agents/skills/starfall-factory/SKILL.md) and [execution contract](docs/AGENT_FACTORY.md). Delegate independent tasks with disjoint write ownership, bound running and unintegrated work, and integrate ready slices continuously. GitHub leaf issues close through default-branch PR closing references; confirm closure and Project Done state after merge. Small fixes stay with one agent; the workflow adds no approval stages or background execution.

## Ownership and durable fixes

Core owns deterministic rules, seeded randomness and committed outcomes, with no UI imports. Stores coordinate input, clocks, persistence and feedback; scenes present committed turns. Never derive legality, score, saves or shower schedules from animation callbacks or node positions. Save committed core state and validate invariants before restore. Rule/RNG/schema changes require deterministic replay and old-save coverage; preserve previews and saved generation behavior or explicitly migrate/version them.

Search for an existing owner before adding behavior. Share rules, geometry, materials, tokens and persistence contracts where they have the same reason to change. Prefer composition, narrow capabilities and explicit dependency direction; avoid circular dependencies, multipurpose managers and speculative frameworks. Review files approaching 1,200 lines for cohesive extraction, not arbitrary chunks. If a touched oversized file stays intact, record why and a concrete follow-up in [ENGINEERING](docs/ENGINEERING.md). Keep structural refactors separate from rule/save changes where practical and verify target membership.

For a bug, reproduce the failure, identify the violated invariant and inspect representative sibling paths. Correct the responsible ownership, validation, mapping or cancellation boundary. Add the smallest useful behavioral or native regression; verify the original and boundary cases. Report the extent examined, cause and residual risk. If only a mitigation can ship, label it and record the remaining correction, trigger and verification in ENGINEERING; integrate the safe mitigation independently.

## Completion and integration

Define observable acceptance before implementation. Follow [EXPERIMENTS](docs/EXPERIMENTS.md) for a hypothesis, bounded scope and adoption/removal point; keep shipped names/routing distinct from candidates. Adopt verified results or remove temporary routes/assets/code. Record why and when any continuing comparison must be revisited. Fixed seeds establish reproducibility and balance, not enjoyment.

Use the [verification matrix](docs/ENGINEERING.md#verification-by-change). Every batch needs `python3 scripts/ci-hygiene.py` and `git diff --check`; Swift changes need `swift test`, affected hosted/UI tests and a simulator build where tooling exists. Routing, build settings, resources and Debug fixtures also need Release and membership checks. Preserve bounded condition-based waits, selected test counts and zero-skip gates. Never weaken assertions, add blanket retries or force reduced motion to obtain green tests.

Record source, build-affecting dirty paths, commands, configuration, simulator/OS and results. Published-commit acceptance needs a clean checkout/export or explicit working-tree differences. Separate core, build, interaction, visual, animation, actual VoiceOver and physical-device evidence; never claim Apple validation without running it. Keep raw output disposable and small summaries in `docs/evidence`. A passing build alone does not establish gameplay quality.

Merge completed, verified batches as ready. Stage explicit paths/hunks and preserve unrelated edits; shared schemes and intentional membership belong in Git, user Xcode state and generated artifacts do not. Keep README/ROADMAP current and deferred concrete risks in ENGINEERING. Avoid speculative dependencies, warning suppressions and formatting churn.

Deliver to the original phone only through `scripts/device-update.py`, which archives current main and verifies actual installation. Reconcile accepted work and the current save contract first. Do not install feature checkouts using raw `devicectl`, Xcode Run or another bypass. Keep deployment tooling separate from gameplay. Explicit emergency recovery must verify the exact prior signed production build, hold the updater lock and record the result without resetting player data.

The original paired iPhone supports local Wi-Fi delivery. If it is not physically connected or the updater reports waiting, check its local-network reachability and existing pairing before suggesting a cable or declaring delivery blocked. A disconnected CoreDevice tunnel can be idle rather than unreachable; follow the [wireless delivery check](scripts/README.md#wireless-delivery-check). Continue through the canonical updater when reachable. If it remains unavailable, ask the user to unlock the phone and confirm it shares the Mac's local Wi-Fi network.
