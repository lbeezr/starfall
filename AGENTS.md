# Starfall repository instructions

Keep the prototype small. Falling sky is the default game in Debug and Release: deterministic accumulating stars, automatic showers with pause, dark stars, and local balance controls. One optional First Light challenge tests a fixed 18-starlight objective; there is no campaign, XP or unlock progression. The original 7×7 orthogonal puzzle remains available for Debug testing: five jewel types, groups of 3+, 70 cleared jewels in 18 valid moves, no timer, invalid taps spend no move, win takes precedence on the last move, and dead-board recovery is free and bounded. No power-ups, progression, backend, accounts, paid assets or external SDKs.

- Keep deterministic rules in Sources/StarfallCore, with no UI imports; test with `swift test`.
- App uses SwiftUI and SpriteKit, iOS 17+. Shared scheme: Starfall.
- Every current build is clean. Ad and IAP SDKs, entitlements, tracking and monetization UI must remain absent. Any future monetized edition must be a separate opt-in target/product with dependencies conditionally linked; a runtime hide flag is insufficient.
- Do not claim simulator/device or visual validation unless actually run on Apple tooling.
- Do not change another repository or add network features, purchases or analytics without a new request.
- Run tests and a simulator build after source changes where tooling exists. Inspect normal play, rapid taps, win/loss, restart, background/resume, VoiceOver, Reduce Motion, and settings dismissal.

## Code quality
- Stay DRY: give shared rules, geometry, materials, design tokens and persistence contracts one authoritative owner. Search for an existing implementation before adding another; consolidate duplicated behavior when touching it. Similar-looking code with different reasons to change need not share an abstraction.
- Actively decouple responsibilities. Keep deterministic rules independent from rendering; keep presentation, saved state and feedback behind small, explicit boundaries. Pass the values or narrow capabilities a component needs instead of an entire store, global singleton or unrelated mutable state. Prefer composition and clear dependency direction; avoid circular dependencies and multipurpose managers.
- Review files approaching or exceeding roughly 1,200 lines for modularization. Extract cohesive responsibilities into focused files/types and verify target membership and behavior. This is a review trigger, not a hard cap: split earlier when responsibilities diverge, and avoid arbitrary chunks or extensions that merely hide the same coupling. If a touched oversized file remains intact, document the reason and a concrete follow-up in docs/ENGINEERING.md.
- Add focused tests for behavioral changes. Keep structural refactors separate from rule/save changes where practical, preserve public contracts, and run the affected checks after extraction. Do not introduce speculative frameworks or generalize beyond demonstrated reuse. Reuse the bounded jewel material factory rather than duplicating drawing logic.

## Incremental integration
Merge completed, verified work in small batches as it becomes ready. Do not let an unrelated blocked workstream delay integration or allow a large backlog of changes to accumulate. Keep each commit scoped to its workstream, preserve other agents' in-progress edits, and run the checks appropriate to each batch before integrating it.

## Swift game boundaries
- Core owns rules, seeded randomness and committed outcomes. Stores coordinate input, clocks, persistence and feedback; scenes present committed turns. Never derive a legal move, score, save or shower schedule from an animation callback or node position.
- Keep app/store/scene mutation on the main actor. Own and cancel tasks, deadlines, observers and actions explicitly. Restart, backgrounding, settings and scene replacement must reject stale completions; preserve the existing generation guards and single-deadline clock. No queued catch-up showers.
- Keep the injected clock/presenter/feedback boundaries small. Use value snapshots across concurrency boundaries; do not silence isolation diagnostics with unchecked Sendable or unsafe isolation without documenting and testing the actual synchronization.
- Save committed core state, not transient animation state. Decoding success is insufficient: validate invariants before restore. Rule, RNG or schema changes need deterministic replay and old-save coverage; preserve existing previews and saved generation behavior or explicitly migrate/version them.
- Keep nodes, particles, textures, audio voices and caches bounded. Avoid file IO, asset decoding, procedural artwork generation and broad SwiftUI state updates in per-frame paths. Profile a reproducible scenario before introducing pooling, background work or a new abstraction.

## UI and gameplay acceptance
- Put reusable typography, spacing, colors and control roles in StarfallTheme; use the existing jewel material/asset boundary. Keep the board dominant and instructions/secondary actions out of the active playfield. Do not restore visible square cell backgrounds without a design request.
- Rendering and native hit/accessibility cells must share the same coordinate mapping, including resized boards and row direction. Geometry changes require a real native tap check; keep jewel aspect ratio intact.
- Preserve stable cell/gem identity, native button semantics, non-color cues, full touch targets and readable Dynamic Type. Reflow controls rather than shrinking text to fit. Inspect screenshots as well as test assertions: a hittable control can still wrap badly or crowd the board.
- Keep full animations in normal play. Calm effects, VoiceOver and system Reduce Motion must preserve the same committed outcomes and usable input. Still screenshots and animation-suppressed tests are not evidence that falling animations work.
- Fixed-seed samples describe reproducibility and balance, not human enjoyment. Keep experimental mechanics isolated until comparison and relevant checks justify adoption; do not accumulate permanent pilot flags or new progression systems by default.

## Verification and repository hygiene
- Before editing, inspect status and applicable guidance. Stage explicit paths/hunks; never sweep unrelated Xcode edits, generated workspace files or artifacts into a feature commit. Shared schemes and deliberate project/resource membership belong in Git; user-specific Xcode state does not.
- Run `python3 scripts/ci-hygiene.py` and `git diff --check`. Source changes also need `swift test`, affected hosted/UI tests, and a simulator build. Check Release when changing routing, build settings, resources or Debug-only fixtures. Check source/resource membership when adding files; a package test cannot prove an app target includes them.
- Use condition/expectation-based test waits with bounded timeouts. Keep reset data local, deterministic and isolated from normal saves. Do not weaken assertions, add blanket retries, or force reduced motion merely to obtain green tests.
- Record the tested source, dirty paths affecting the build, command, configuration, simulator/OS and result. For acceptance of a published commit, use a clean checkout/export or explicitly report working-tree differences. Separate core, build, interaction, visual, actual VoiceOver and physical-device evidence; retain small durable summaries under docs/evidence, raw output under ignored artifacts or temporary storage.
- Keep README/ROADMAP current and historical evidence source-bound. Record deferred concrete risks with a trigger and verification in docs/ENGINEERING.md; address them when touching that boundary. Do not add frameworks, dependencies, blanket warning suppressions or large formatting churn as speculative debt prevention.
