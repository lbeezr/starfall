# Living Observatory — first native landing integration

**Historical lab proof.** The [production adoption](../../../evidence/observatory-adoption-2026-10-17/README.md) supersedes this route. Duplicate lab templates/exporters were removed; production owners now live under `App/Observatory…`. Results below retain their original source boundaries.

## Scope and hypothesis

Selected direction: five distinct places, starting with Moonlit Observatory. This pass integrates the existing StarCast and Falling Sky rules into a clean, full-screen Observatory with a shallow receding landing surface. The telescope and lantern respond to native button input; two fog layers drift independently at the edges. The main app's default route is unchanged. The lab uses `com.starfall.landinglab`, so it does not replace normal saves or preferences.

Hypothesis: real star silhouettes, upright presentation, contact shadows and an angled tactile surface can preserve readable seven-column play while giving stars a coherent place to land. The unchanged row-collapse behavior reads as settling forward across a gently raked terrace. Whether this communicates well to players is still a human-play question, not established by coordinate tests.

Acceptance was recorded in [ACCEPTANCE.txt](ACCEPTANCE.txt) before source work. Scope extended during implementation at the user's request to require edge-to-edge scenery, interactive telescope/lantern and gentle living atmosphere.

## Implementation boundaries

- The retired `prepare-landing-lab.py` exported tracked current working-tree bytes, then applies isolated presentation overrides. No new production flags or core/save contracts. `ENVIRONMENT-LAB-SOURCE.json` hashes source bytes and records HEAD/dirty status; `LANDING-LAB-OVERRIDES.json` hashes lab sources and art. This is not clean published-commit acceptance.
- `LandingGeometry.swift` is the one owner of artwork aspect-fill cropping, tapered cell polygons, native button frames, SpriteKit centers, inverse probes and prop placement. Upright cast sprites retain their existing size/aspect, expression actions and identity. Touch cells use projected polygon shapes, not a rotated rectangular overlay. No visible square tiles.
- Geometry and fixture helpers are appended into existing target members only in the export. Tests are appended into existing hosted/UI members; the already included asset catalog owns the four new imagesets. A hosted resource check confirms the images actually load from the app bundle with alpha.
- `ObservatoryEnvironment.swift` receives only active/reduced-motion values. A small TimelineView refreshes environmental layers at at most 24 Hz; neither core RNG nor the store's shower clock is used. The ambient clock records monotonic active elapsed time, excludes suspended time and never catches up.
- One owned cancellable response task handles prop responses, with a generation guard. Repeated taps replace it; settings, background and disappearance cancel it. Reduced motion/Calm/VoiceOver keep feedback quiet. Native prop accessibility values report response/rest state. Props lie outside gameplay polygons.
- The full-screen artwork lives behind controls whose layout reads safe-area insets from an outer geometry reader. Only small score/menu surfaces and bottom controls have containment. The shower cue sits on the terrace's far rim.
- No store rule/clock/persistence changes; only export-local deterministic sparse/dense fixture initialization is injected. Fixtures include all five families, Dusk and a grown star; they validate and round-trip through the existing save contract. They are not game balance evidence.

## Art and bounds

All art generated/edited with the built-in image generator. The original mock's baked stars, trails, shadows and floor glows were removed. The base plate then had telescope and lantern removed; both props were extracted as real alpha layers. Fog is a separate alpha layer. Generated layers did not preserve exact prop scale, so registration uses measured alpha bounds and explicit normalized placement shared with hit geometry.

Files: `observatory-background.png` (clean initial plate/reference), `observatory-base.png`, `observatory-telescope.png`, `observatory-lantern.png`, `observatory-fog.png`. Exact cleanup prompt in `prompt.txt`, layer prompts in `layer-prompts.json`.

Four live textures total about 6.3 million source pixels / approximately 25 MB of raw RGBA storage before framework copies, plus the pre-existing bounded cast cache. This is an estimate, not a memory profile. Fog reuses one texture twice, not an emitter or accumulating particle stream. No per-frame asset decoding or procedural artwork generation is introduced by application code. Frame pacing and device memory still need measurement in a reproducible native scenario before adoption.

## Checks and decision

[Source-bound verification and native captures](../../../evidence/living-observatory-2026-10-17/README.md): 61 core tests passed; five integrated native UI checks passed; 30 hosted checks had zero failures and one motion skip, closed by a separate full-motion pass on identical runtime source. Final Release simulator build passed. Actual VoiceOver, physical device, landscape/iPad layout, long-play enjoyment and profile evidence remain separate from simulator build/UI checks. No claim that a still image proves moving fog or full falling animation. Production adoption requires dense-board human play and supported-layout/accessibility acceptance. Extend only this bounded lab while resolving those questions; do not expand five separate runtime implementations.

## Human art-direction feedback

On October 17, 2026, the user reported tapping both the telescope and lantern, confirmed that both reacted as hoped, and endorsed the setting/depth as a direction they would be proud to ship. Exact tapped build was not independently pinned; this records reviewer acceptance of the experience and visual direction, not a claim about a particular Release binary, general player preference, actual VoiceOver or device performance. The requested next step is the [replicable production strategy and five-place roadmap](../PRODUCTION.md).
