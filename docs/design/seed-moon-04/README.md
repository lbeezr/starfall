# Seed Moon

**Status:** Implemented, development-verified and delivered · **Updated:** October 19, 2026

Seed Moon restores a curled seed inside a small cracked moon until its bud opens into a sheltering canopy. The [production plan](PRODUCTION_PLAN.md) defines the fourth directly selectable seed-42, 18-light challenge. Existing rules, save behavior and the Open sky default remain; this adds no campaign, gardening system or world-travel animation.

## Start here

Read the [observable acceptance](PRODUCTION_PLAN.md), [atlas entry](../WORLD_ATLAS.md#04--seed-moon--enough-light-to-make-shelter) and [five authored beats](../world-01/world-data.js). The [composition reviewer](board.html), using the shared [review engine](../environments/restoration-review.js), compares the three viewport families, five states and a fixed sample made from actual Crystal Glow body assets. It is a static review tool, not a playable round or native evidence.

<img src="../world-01/map-v1.png" width="540" alt="Approved world concept with Seed Moon numbered 04, a luminous green shoot inside a pale cracked round shell">

**Approved generated concept — not runtime evidence.** Map inspected October 19, 2026; [original package](../world-01/README.md). Its round shell, living shoot and small sheltered garden guide the paintings. Tiny map figures are not scenery travelers.

<img src="../../../App/Assets.xcassets/SeedMoon100.imageset/scene.png" width="220" alt="Seed Moon phone source artwork with a fully open ivory-gold flower canopy over a pearl seed and pale split moon shell">

**Generated phone source artwork — not native evidence.** All fifteen paintings were inspected: shell, scoop, seed base and sky remain identifiable; the golden bud stays closed at 75% and opens into petals at 100% in every family. The final phone 75%/100% art raises and reduces the golden head after a development HUD-clearance probe. All selected files match their generation records byte for byte. Native phone/tablet checks and the subsequent phone 50% shoot-clearance correction are recorded separately; see the [evidence record](../../evidence/seed-moon-2026-10-19/README.md).

## Reviewer and ownership

Choose Phone, iPad portrait or iPad landscape, then a score/state and 24/40/49/0 stars. Scores 0/5/9/14/18 select the five artwork milestones; text reports actual progress. The existing [offline cast renderer](../environments/concept-cast.js) supplies packaged bodies and illustrative faces. The seven-column samples remain fixed between stages and views. Reference canvases are 393 × 852, 768 × 1024 and 1024 × 768 points; native geometry and safe areas remain owned by the app.

The reviewer expects `SeedMoon###`, `SeedMoonTabletPortrait###` and `SeedMoonTabletLandscape###` app asset sets. All fifteen images are packaged. The reviewer reports any unavailable image explicitly. It uses one full continuous background without masks or spatial fades. Phone sources are 887×1774 pixels and iPad portrait sources are 1086×1448. Landscape sources are 1446×1087 at 0%/25%/50% and 1447×1087 at 75%/100%; the reference is 1447×1087. After each image loads, the reviewer uses its natural dimensions and whole-image cover fitting rather than assuming every stage has the same pixel size. The native light destination is the pearl seed on phone/tablet landscape and the visible mint root seam below the HUD on tablet portrait (normalized 0.160, 0.214); the final bud/canopy has a separate protected focal region. The [prompt record](art-prompts.json) preserves all twenty generation attempts; the [asset manifest](production-assets.json) records the fifteen selected files, exact dimensions, hashes and source matches.

At 75% the central bud must remain closed; at 100% the canopy opens above a visible shelter. Completion uses ordinary light transfer, a whole-image crossfade and the normal result. Future user-generated clips may show residents using the shelter; no residents, cutscenes or extra unfolding animation are implemented by this plan.

This folder owns the plan and offline comparison. Core owns rules/saves, and the native app owns playable stars, controls, fitting and feedback. Final runtime `b77a100` / `dev.545382e6f6` changes only the phone 50% painting from `a0c7360` / `dev.017575ea43`. The earlier checkpoint passes 329 hosted checks, phone win/restore/replay and largest-text/system Reduce Motion, preview/cancel over all three prior locations, and tablet rotation/clears with all ten tablet states inspected. Final-source Debug, dense 9→13 input, manual overflow and recorded motion checks pass. At test-only follow-up `124fd21`, the unchanged runtime passes 12 focused hosted checks plus the overflow/replay UI test, four compact SE3 sibling flows, and Release with no warnings/errors. The native-plan/RC-platform suites add 15 passing checks after the new test. Earlier Core 178/178 and Python 55/55 keep their original dirty-source attribution. The canonical updater verified `dev.545382e6f6` installed from main `e823005`; [the evidence report](../../evidence/seed-moon-2026-10-19/README.md#publication-and-delivery) owns the receipt and CI-at-install status. Browser rendering remains unverified because the previous local-file denial explicitly prohibited alternate-route workarounds; only static reviewer logic checks may be reported. Actual VoiceOver follows the RC cadence; physical play and human satisfaction need their own observations.

## Reviewer checks

JavaScript syntax and a minimal-DOM check pass for all 57 score/view combinations, fixed star identities, 24/40/49/0 sample counts, five milestone buttons, geometry guides, image status, query precedence, natural-size updates across loads and same-state score changes, and existing cast asset paths. These verify static logic only; no browser rendering or native acceptance is claimed. All fifteen expected background paths are packaged.
