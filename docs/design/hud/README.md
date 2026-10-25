# Native HUD

The HUD uses the official [game UI system](../GAME_UI_SYSTEM.md): small instruments over continuous scenery, exact score and forecast, a reachable pause action, and a dominant playable star field. The middle **Play** screen in the [approved concept](../interface/observatory-game-ui-concept-2026-10-19.png) supplies the visual direction. It is a concept, not proof of native layout or accessibility.

**Current acceptance:** [Goal 1's corrected development slice](../../evidence/hud-stack-2026-10-24/README.md#goal-1-correction-native-and-visual-acceptance) passes independent whole-native-screen and retained-export review against the approved Play direction. Goal 1 App source was `bf5e6d23` / `dev.3ebf052fca`; test checkpoint `3fe9f9a8` preserves exact complete-reader extent/hit and unchanged real-pan gates. Earlier rejected layouts and pan failures remain explicit; actual tablet settled-state equivalence is source-bound. Goal 1 merged in [PR #402](https://github.com/lbeezr/starfall/pull/402); [Goal 2 typography](../../evidence/hud-stack-2026-10-24/README.md#goal-2-instrument-typography) follows from that main: earned-line symbol alignment and shared numeric/label roles pass the named native phone/tablet states and exact-export review at `ac78832a` / `dev.f4ecc1c437`; [PR #403](https://github.com/lbeezr/starfall/pull/403) merged as `1ed733bb` and completed issue #383. [Goal 3 pause separation](../../evidence/hud-stack-2026-10-24/README.md#goal-3-pause-separation-over-scenery) passes its named bright/darker, default/AX5 native states and final export review at `4d7cfa21` / `dev.189706f888`; [PR #404](https://github.com/lbeezr/starfall/pull/404) merged as `47b0b5e9` and completed issue #384. [Goal 4 contact](../../evidence/hud-stack-2026-10-24/README.md#goal-4-stable-glyphs-and-shared-contact-material) passes its named native, sampled press/cancel and final export reviews; [PR #405](https://github.com/lbeezr/starfall/pull/405) merged as `bac7bcf3` and completed issue #385. [Goal 5 forecast](../../evidence/hud-stack-2026-10-24/README.md#goal-5-one-forecast-row-and-a-timing-only-trail) passes its bounded native, sampled-motion and final export reviews; its individual merge is next.

## Find the responsible owner

| Responsibility | Existing owner |
| --- | --- |
| Shared typography, material and control roles | [StarfallTheme](../../../App/StarfallTheme.swift), [ObservatoryArtwork](../../../App/ObservatoryArtwork.swift), [official component roster](../GAME_UI_SYSTEM.md#3-shared-native-components) |
| Native composition, menu/inspection presentation and receipt anchors | [FallingSkyView](../../../App/FallingSkyView.swift) |
| Exact score and shower trail | [FallingSkyHUD](../../../App/FallingSkyHUD.swift) |
| Ordered forecast destinations and optional column selection | [SkyForecastDestinations](../../../App/SkyForecastDestinations.swift) |
| Board, hit-cell and accessibility projection | [LandingGeometry](../../../App/LandingGeometry.swift) |
| Hosted reading-layout, exact score fit and receipt registration probe | [SkyReadingPlayfieldTests](../../../AppTests/SkyReadingPlayfieldTests.swift) |
| Evidence and ordered delivery | [HUD stack record](../../evidence/hud-stack-2026-10-24/README.md) |

HUD source currently lives directly under `App/`; there is no `App/HUD/` source folder. [App instructions](../../../App/AGENTS.md) govern those files, and the [UI production skill](../../../.agents/skills/starfall-ui-production/SKILL.md) routes HUD work here. Do not move files merely to make a nested instruction file apply.

## Before accepting a change

Use the [UI production workflow](../UI_PRODUCTION.md) and its [separate visual acceptance review](../UI_PRODUCTION.md#decide-visual-acceptance-separately). Map changed elements to official roles; design/register missing pieces in shared owners. Review the whole native screen against the approved direction at default and largest text, preserving readable content and full targets. An independent reviewer records a visual verdict separately from mechanical results. Correct visible hierarchy or composition failures in the current goal before advancing; passing fit assertions cannot override them.

Core owns rules and committed facts. HUD composition cannot recalculate score, forecast supply or deadlines. Preserve the common board projection, receipt/source invalidation and the existing clock/save boundaries. Native interaction, visual judgment, animation, actual VoiceOver and physical-device evidence retain their separate scopes under the [verification matrix](../../ENGINEERING.md#verification-by-change).

The pinned header owns its complete intrinsic vertical size under a finite viewport proposal; the reading viewport yields scroll space. Score-fit measurements use supported sibling child hosts with the official type and matching traits, preserving the live game's safe areas. Compare scene/native canvas dimensions locally and anchor/native placement in their common overlay space. Fractional return-band fitting must retain exact containment. The [correction record](../../evidence/hud-stack-2026-10-24/verification-01-correction.json), [capture index](../../evidence/hud-stack-2026-10-24/captures-01-correction.json) and [independent review](../../evidence/hud-stack-2026-10-24/visual-review-01-correction.json) retain the separate evidence and limits.
