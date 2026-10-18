# Integrate the selected Crystal Comet lettering

**Status:** Implemented; development verification passes · **Owner:** current implementer · **Date:** October 18, 2026

The user approved the complete design set and requested normal-game integration, a PR and merge. Keep all existing scoring, save, input, shower and receipt-lifecycle owners unchanged. Adopt one illustrated family, not five unrelated fonts or new achievement categories.

**Format decision:** package transparent neutral-material PNG title masters and a 12-glyph numeral/sign atlas. The selected artwork is raster illustration; mechanically tracing its painted facets into SVG would not preserve that appearance. Earlier SVG suggestions are superseded for this integration. Original concept sheets and exact production generation prompts remain editable briefs; these PNGs are not advertised as SVG masters or a font. Runtime tint supplies the actual contributor family. No SVG loader, external font or dependency.

## Observable acceptance before implementation

- All five title spellings match the current copy catalogue. Compose relay depth separately; the exact positive award remains the committed receipt value. Ordinary awards use the same companion digits without acquiring a title or invented multiplier.
- Package complete title/glyph assets in the existing asset catalog. Decode/crop once into a fixed cache, including failure; never generate art or scan pixels in the timeline's per-frame path. If a member is unavailable/malformed, fall back coherently to readable native text.
- Match harvest colors through a neutral faceted material. Keep central placement, bounded entrance/hold/dissolve and quiet/static modes. Avoid board/node movement or changed native hit mapping.
- Keep live score/accessible result authoritative. Art is decorative and hidden from exploration. Accessibility Dynamic Type and unsupported/localized copy use native readable text; do not squeeze reading text into fixed art.
- Verify asset/glyph membership and exact reward/relay composition, original receipt replacement/cancellation, small/large/default/large-text appearance, normal-motion rendering and interruption/native gesture siblings. Run hygiene, diff, core, hosted/UI tests and Debug/Release simulator builds. Record actual VoiceOver as deferred to RC and physical preference separately.

**Next action:** review physical feel and dense-board readability at the next phone/RC pass. [Final integration evidence](../../../evidence/crystal-comet-integration-2026-10-18/README.md) records 160 core, a final full 247-case hosted run and seven native checks across the named source contexts, Debug/Release builds and actual native captures on reconciled main. Phone installation is separate and uses the canonical updater if requested.


## First integration checkpoint

On main ancestry `1ed6290` plus this branch: 152 core, 241 hosted and six native checks pass; Debug and Release simulator builds pass. The four artwork checks cover complete packaged titles/glyphs, cached failure, exact repeated-digit composition and source-coordinate alpha bounds shared with jewel loading. Native checks include recipe/relay, trace cancellation, settings/background, normal/largest text, system Reduce Motion and First Light win/replay/full-sky restore. Actual VoiceOver is deferred to RC; physical review not run. Raw output: ignored `artifacts/crystal-lettering/`. That checkpoint is superseded by the linked final checks after preserving accepted main `c2695e6`.

The initial build caught a syntax typo, corrected before runtime checks. A first full hosted run passed 240/241; its only failure was an unchanged legacy test expecting the old word “captive” after main’s copy rewrite. The exact current trapped-star sentence replaces that substring assertion while keeping both rapid-clear/state invariants. No store or copy-source change was made for that correction. The original render probe also assumed white ink; source-bound native captures showed the intended colored art, so it now requires the same extra bright-ink area in the same region with family colors admitted. Final source passes these checks without retries or assertion relaxation.
