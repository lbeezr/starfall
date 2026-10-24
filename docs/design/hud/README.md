# Native HUD

The HUD uses the official [game UI system](../GAME_UI_SYSTEM.md): small instruments over continuous scenery, exact score and forecast, a reachable pause action, and a dominant playable star field. The middle **Play** screen in the [approved concept](../interface/observatory-game-ui-concept-2026-10-19.png) supplies the visual direction. It is a concept, not proof of native layout or accessibility.

**Current acceptance:** [HUD goal 1 is reopened after the user's October 24 rejection](../../evidence/hud-stack-2026-10-24/README.md). Its mechanical checks passed; its visual verdict failed. The oversized optional inspection action and disconnected header must be corrected before goal 2. See the [visual reference](../VISUAL_REFERENCE.md) for capture status; rejected captures are counterexamples, not a design baseline to preserve.

## Find the responsible owner

| Responsibility | Existing owner |
| --- | --- |
| Shared typography, material and control roles | [StarfallTheme](../../../App/StarfallTheme.swift), [ObservatoryArtwork](../../../App/ObservatoryArtwork.swift), [official component roster](../GAME_UI_SYSTEM.md#3-shared-native-components) |
| Native composition, menu/inspection presentation and receipt anchors | [FallingSkyView](../../../App/FallingSkyView.swift) |
| Exact score and shower trail | [FallingSkyHUD](../../../App/FallingSkyHUD.swift) |
| Ordered forecast destinations and optional column selection | [SkyForecastDestinations](../../../App/SkyForecastDestinations.swift) |
| Board, hit-cell and accessibility projection | [LandingGeometry](../../../App/LandingGeometry.swift) |
| Evidence and ordered delivery | [HUD stack record](../../evidence/hud-stack-2026-10-24/README.md) |

HUD source currently lives directly under `App/`; there is no `App/HUD/` source folder. [App instructions](../../../App/AGENTS.md) govern those files, and the [UI production skill](../../../.agents/skills/starfall-ui-production/SKILL.md) routes HUD work here. Do not move files merely to make a nested instruction file apply.

## Before accepting a change

Use the [UI production workflow](../UI_PRODUCTION.md) and its [separate visual acceptance review](../UI_PRODUCTION.md#decide-visual-acceptance-separately). Map changed elements to official roles; design/register missing pieces in shared owners. Review the whole native screen against the approved direction at default and largest text, preserving readable content and full targets. An independent reviewer records a visual verdict separately from mechanical results. Correct visible hierarchy or composition failures in the current goal before advancing; passing fit assertions cannot override them.

Core owns rules and committed facts. HUD composition cannot recalculate score, forecast supply or deadlines. Preserve the common board projection, receipt/source invalidation and the existing clock/save boundaries. Native interaction, visual judgment, animation, actual VoiceOver and physical-device evidence retain their separate scopes under the [verification matrix](../../ENGINEERING.md#verification-by-change).
