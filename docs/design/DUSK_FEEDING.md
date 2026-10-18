# Dusk is a feeding hazard players can use

**Status:** Accepted · **Owner:** current implementer · **Updated:** October 17, 2026

The user selected production adoption: Dusk drains touching stars and becomes a finite black hole if left feeding. Players can dissolve it early to recover scoring opportunities, or let it swallow an awkward cluster for space. This replaces growth-only suppression and the separate drain prototype; no new mode, progression or bonus is added.

**Decision:** Five feeding showers, one bounded collapse. Core commits every stage and consumed star. The normal target uses this rule in Debug and Release.

## Player contract

- Dusk arrives unfed. At the start of each subsequent shower, it gains one stage if it currently touches a colored star or Opal orthogonally. Empty neighborhoods pause feeding without resetting progress. Pausing, settings and backgrounding never advance it.
- Touching colored stars/Opals look gray and score zero; their original matching weight, family, grown shape and trace eligibility remain. Growth is allowed. A valid ordinary match or selected constellation touching Dusk dissolves it before its next feeding event. Rewards are sampled before dissolution; surviving stars recover after settling if no Dusk still touches them.
- Show five progress marks, a growing dark core, inward threads, exact threatened neighbors, and a “one feeding shower left” warning in bottom character dialogue, with no top banner. Accessibility names stage, feeding condition and consumed cells. Quiet motion preserves the same static information.
- On its fifth feeding shower, Dusk swallows its currently touching colored/Opal stars, disappears, and survivors settle **before new arrivals**. Each consumed star is counted once, even between multiple collapsing Dusks. No score. Other Dusks are not swallowed; there is no chain. Historical Debug gravity fixtures additionally verify that fields/holes are excluded and consuming a captive closes/releases that orbit safely. Normal production preserves the accepted retirement of gravity specials.

## Save and presentation boundaries

A saved Dusk rule marker and per-star feeding count preserve replay and decoding. Missing markers retain historical core replay. The v7 app archive adopts the five-feed rule on restored skies, retaining score, RNG, cadence, lost light and existing feed counts. Historical three-feed Core saves still replay with their stored rule. The v6 bytes remain untouched; v7 is written only on activation. Legacy nonfeeding Dusks begin unfed. Gravity-free rounds retain board, IDs, previews and generation exactly. The existing gravity-retirement normalization runs first on historical gravity rounds, retaining survivor IDs and converting their pending specials under that contract. Old archive bytes remain untouched and current invalid data never resurrects an older round. Lost reward/consumed starlight has one conservation counter; magnetic retirement remains separate. First Light stays unchanged.

Turns report influence-column changes and collapse snapshots. Ordinary responsive input remains available outside those columns; a collapse/orbit change reserves the board until its committed phases settle. Scene callbacks never choose targets or score. Restart, resize, settings, background and motion changes cancel presentation through the established store generation contract.

## Acceptance before implementation

- Focused rules: five feeds plus historical three-feed replay, starvation pause, birth-shower exclusion, before-arrival relief of full columns, clear versus wait choice, trace clears, grown/Opal reward, simultaneous overlap, last-source restoration, and active-orbit consumption. Validate every resulting state and deterministic continuation.
- Compatibility: historical core replay unchanged; v3/v4/v5/v6 migration is explicit/idempotent, preserves announced state, and writes only on activation. Reject unknown versions, impossible stages/loss and malformed current archives. Replay resets stage/loss.
- Native: inspect actual stages/gray/target cues, a full-motion swallow/settlement/arrival and color release; real taps, rapid input, settings dismissal, background/resume, restore/restart, win/full sky and Reduce Motion/large text. Keep actual VoiceOver/device acceptance separate under the development cadence.
- Run core, affected hosted/UI checks, Debug/Release builds, hygiene and whitespace checks. Verify added file membership and record source-bound captures with the current screenshot naming policy. Merge the verified change into GitHub main and confirm the merged tree.

**Remaining judgment:** Five feeds and four neighbors are production tuning, not demonstrated enjoyment. Observe whether players recognize the imminent collapse and deliberately use it; tune the existing mechanic if recognition or choice is weak. Actual VoiceOver and physical-device acceptance remain release-candidate work.


## Production evidence

[Source-bound results and inspected native captures](../evidence/dusk-feeding-2026-10-18/README.md) record rule/save, interruption, accessibility, visual and animation acceptance separately. The screenshots are runtime captures; human recognition, actual VoiceOver and physical-device acceptance remain separate checks.

<img src="../evidence/input-dusk-refinement-2026-10-18/dev-11a16fc-wip-3cded269c037__dusk-imminent__iphone-17e__default-text.png" width="240" alt="Native Dusk with three gray threatened neighbors, inward connections and one feeding shower left">

**Runtime capture:** iPhone 17e / iOS 27.0 Simulator, normal motion, default text, snapshot `3cded269c037` on base `11a16fc`, before the final input timer ticket (presentation unchanged). [Five-feed refinement evidence](../evidence/input-dusk-refinement-2026-10-18/README.md) separates native outcome/visual checks from physical feel and actual VoiceOver.
