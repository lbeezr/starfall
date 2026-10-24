---
name: starfall-ui-production
description: Turn Starfall UI concepts into reusable native components and production assets with state and layout contracts. Use for screen, HUD or interactive-map production; use the level-design skill for restoration gameplay paintings.
---
# Produce a Starfall interface

Read the applicable repository boundary and [UI production workflow](../../../docs/design/UI_PRODUCTION.md). The [game UI system](../../../docs/design/GAME_UI_SYSTEM.md) owns visual roles; the [Observatory handoff](../../../Artwork/ObservatoryUI/INTEGRATION.md) owns existing asset registration. Read only the relevant sections.

Treat an approved mock as direction for materials, hierarchy and composition. It does not establish reusable components, target geometry, responsive behavior or a production asset roster.

- Inspect the existing screen, state, navigation and component owners before designing replacements. Reuse `StarfallTheme`, `ObservatoryArtwork`, native controls and narrow actions.
- For HUD work, start from the [HUD guide](../../../docs/design/hud/README.md). Use official components in their documented context; design and register a missing role/state in the shared owner before use. Token reuse alone does not establish compliance.
- Inventory the affected behaviors, simultaneous states, content extremes, viewport/text layouts and interruption paths. State observable acceptance before generating the asset family.
- Decompose native text/input from decoration. Split art only when independent placement, state, motion or loading requires it; preserve cohesive paintings where appropriate.
- Record each needed asset's role, logical/pixel dimensions, anchors, alpha, safe content and hit bounds, caps/stretch rules, state coverage, provenance hashes and resource budget. Distinguish proposed values from measured exports.
- Build one representative slice in the real normal-app route, including input, state change and return path. A development harness uses the same production components and deterministic reset-only/Debug fixtures in the existing target. A browser specimen or assembled mock cannot establish native acceptance.
- Inspect real taps, mixed states, long labels, compact/largest text, relevant tablet layouts, bright/dark backgrounds and normal/quiet motion. Check interruption and cancellation. Fix failing contracts before expanding the family.
- Before adoption, apply the [separate visual acceptance review](../../../docs/design/UI_PRODUCTION.md#decide-visual-acceptance-separately). An independent reviewer compares complete source-bound native captures with the approved direction before seeing the implementer's verdict. Report mechanical results and visual judgment separately; a known visual failure keeps its current goal open rather than becoming a later goal's repair. This is internal verification, not routine user approval.
- Expand only the asset/component variations the proven slice needs. Reuse the same owners across sibling screens; recheck the slice when its contract changes.
- Follow existing verification and experiment adoption/removal rules. Keep source art, build, interaction, inspected visual, motion, actual VoiceOver and physical-device evidence distinct. Remove rejected runtime experiments without deleting useful provenance.

For an interactive map, independent island repair states, marker controls, connectors and background may need separate assets. Prove one island and a neighboring different state before producing the world. Keep names, selection and entry native. Use a bounded map-specific renderer when needed: Core progress → app read-only snapshot/content catalogue → renderer → asset layers. The renderer owns presentation/resource lifetime and emits input intents; existing owners retain legality, unlocks and saves.

For a HUD button, start with the existing native action style and glyph. Prove its target, press/cancel, disabled/focus and wrapping behavior in the HUD before adding or multiplying skins.

This workflow adds no approval gates, separate apps, speculative frameworks or mandatory layer count. Complete restoration gameplay paintings follow the [level-design kit](../../../docs/design/level-design-kit/README.md); do not apply map decomposition rules to them indiscriminately.
