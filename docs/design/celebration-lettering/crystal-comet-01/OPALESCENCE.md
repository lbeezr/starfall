# Restore opalescent light within the crystal faces

**Status:** User-approved shipping checkpoint; development checks pass · **Owner:** current implementer · **Updated:** October 18, 2026

The approved [numerals and swatches](numerals-and-light.png) have warm and cool light within each material. The first integration multiplied the neutral art by one family tint and screened a 55% neutral copy over it. That retained shape but washed out color and made the material read flatter than the concept.

**Decision:** retain the existing registered PNGs and family tint; replace the uniform white wash with a shared static refraction material. Luminance masks let peach, pink, violet and ice light catch the authored faces. A separate narrow highlight restores pearl edges. A final source-alpha mask keeps the treatment inside the letters, including counters and transparent fringe. The result approaches the reference through compositing; it does not reproduce every individually painted multicolored facet.

<img src="numerals-and-light.png" width="360" alt="Approved opalescent numerals and six family-color swatches">

**Approved concept — not runtime evidence.** Notice the neighboring warm/cool faces and pearl highlights, rather than an overall rainbow glow.

## Acceptance and scope

- Native six-family comparison shows multiple warm/cool facet colors, strong light/dark separation, clear numeral counters and recognizable source-family differences. Include 0–9 and long/short titles at phone scale.
- Inspect actual full-game scoring samples and normal/quiet rendering; preserve exact awards, title fallbacks, receipt expiry/replacement and settings/background cancellation.
- Keep all material colors in StarfallTheme. Reuse one material for every title and glyph; no new assets, per-frame raster generation, timer, motion, cache or dependency.
- Check core, affected hosted/native tests, Debug/Release simulator builds, hygiene and whitespace. Actual VoiceOver and physical feel retain their RC/phone boundaries. No coordinate mapping or gameplay/save change.

**User decision:** accepted this checkpoint for shipping. Selective saturation could further strengthen reflected colors while keeping pearl highlights clear; no additional saturation change is included in the accepted checkpoint.

**Next action:** ship the approved material using the source-bound [native follow-up](../../../evidence/crystal-comet-integration-2026-10-18/OPALESCENCE.md) with the concept. Tune the balance after player review; avoid treating stills as proof of motion comfort.
