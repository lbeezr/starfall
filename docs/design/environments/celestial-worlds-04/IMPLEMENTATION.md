# Celestial environments: production adoption

**Status:** Implemented locally; publication held after user design revision · **Owner:** current implementer · **Updated:** October 18, 2026

The user approved all five celestial locations and requested implementation and shipping. Preserve current-main rules, saves, crystal evolution, gestures and scoring presentation while replacing the setting artwork and native fittings. Existing location preference values remain compatible.

**Decision:** Package portrait and authored landscape paintings with native text, controls and shared cell projection. Use bounded optical responses within the instruments; keep artwork and animation independent of committed game state. Separate foreground cutouts support the larger reading layout without stretching props.

**Acceptance before shipping:**

- All five locations are selectable and remembered without altering the round or save.
- Native score, forecast, menu, reading content and actions sit within the painted recesses at ordinary sizes; largest text reflows on a connected reading surface.
- All 49 targets share the rendered mapping, remain at least 44 points on supported layouts, and pass actual native boundary/corner taps and tracing.
- Portrait, authored landscape, small phone and iPad are visually inspected with sparse/dense and grown/dark/Opal states.
- Prop and ambient responses are bounded, cancellable on settings/background/restart/replacement, and usable with reduced motion. Full arrivals and clears remain enabled in normal play.
- Core, affected hosted/UI, Debug/Release simulator builds, resource membership and hygiene checks pass on recorded source. Actual VoiceOver is deferred to RC under the development cadence.
- Publish through GitHub main and use the canonical device updater; report the actual delivery outcome separately from integration.

The current-main reconciliation starts at `be75cc5`; concept approval is recorded at `98f84b6`. The final combined development runtime is `b5a7a02` (`dev.4de18c939b`); the evidence record separates sampled acceptance from remaining small-phone/device/RC checks. The [concept brief](README.md) retains the visual intent and exact initial prompts.

## Local implementation and revised decision

The five locations replace the previous roster in this local branch’s Debug and Release. Publication is held; [open skies](../open-skies-05/README.md) now explores centered gameplay without platforms. See [native results, corrected findings and delivery status](../../../evidence/celestial-boards-2026-10-18/README.md). Generated foreground cutouts serve the flowing accessibility layout; ordinary props remain grounded in the painting and respond through clipped optical animation. Whole-object pivots from the concept brief are deferred to a future layered-art pass, not simulated by rotating rectangular crops.
