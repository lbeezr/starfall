# Starfall visual reference

**Status:** Reference · **Updated:** October 18, 2026

Selected icon, screens and six-star cast, with links to their sources. **Source-bound references, not current-build certification:** check the linked source before drawing conclusions about current UI. Final art/motion approval, actual VoiceOver and device acceptance remain open. Follow [screenshot retention](../SCREENSHOTS.md) when replacing a visual.

[Icon](#adopted-app-icon) · [Screens](#welcome-and-entry) · [Cast](#current-crystal-glow-cast)

## Capture index

Status follows [the screenshot practice](../SCREENSHOTS.md). These legacy filenames retain their original provenance. Recipe controls and relay feedback were inspected against the builds linked below; the other entries retain their separate refresh limits. Use the linked reports for captured sources and environments; the next implementer touching each surface owns its refresh.

| Surface | Status | Selected evidence / next check |
| --- | --- | --- |
| Welcome | Needs refresh | [Sky-flow welcome](../evidence/sky-flow-2026-10-17/welcome.jpg), [source report](../evidence/sky-flow-2026-10-17/README.md); compare relevant UI/art inputs before relying on current parity |
| Entry | Needs refresh | [Sky-flow entry](../evidence/sky-flow-2026-10-17/entry.jpg), same source report; compare relevant UI/art inputs |
| Active play | Sampled dialogue-only HUD and default-text awards; Dusk copy fit needs refresh | [Gesture-only HUD captures](../evidence/dialogue-only-hud-2026-10-18/README.md#inspected-native-presentation) show no banners/toggle and bottom Dusk/input copy; trailing Dusk text needs scrolling. [Visible awards and open selection marks](../evidence/starlight-celebrations-2026-10-18/VISIBLE_AWARDS.md) records ordinary, square, cross, constellation and relay captures, quiet-frame correction, source hashes and native checks. [Prior 16 Pro Max award/sequence](../evidence/calibration-timing-and-arrange-2026-10-18/FRESH_ROUNDS.md#award-visibility-now-has-runtime-evidence) is historical for the earlier ringed burst. Five-feed Dusk and empty-board references retain their source limits. Dense/danger/largest-text effect appearance, smoothness and physical feel remain open. |
| Recipe input during rain | Historical — Arrange mode removed | [Earlier automatic setup acceptance](../evidence/calibration-timing-and-arrange-2026-10-18/AUTOMATIC_SETUPS.md) retains its source-bound selected-square/control evidence; current recipe selection uses direct traces. |
| Settings | Needs refresh | Dusk now uses five progress marks and five-feed help wording; capture default and largest-text How to play layouts. No selected current settings capture |
| Outcomes | Needs refresh | [First Light win](../evidence/sky-flow-2026-10-17/flow-win.jpg) and [full sky](../evidence/sky-flow-2026-10-17/flow-full.jpg), same sky-flow source report; compare relevant UI/art inputs |

## Adopted app icon

<img src="../../App/Assets.xcassets/AppIcon.appiconset/Starfall-1024.png" width="128" alt="Spark falling above lavender clouds along a curved aqua and violet trail">

**Packaged asset — Playful Tumble.** This is the current app-icon PNG, not a screenshot. The [editable source and export instructions](../../scripts/README-app-icon.md) and [native adoption record](../evidence/playful-tumble-icon-2026-10-17/README.md) explain provenance and validation. iOS applies the rounded mask.

## Character chat and script studio

| Active chat | Debug authoring studio |
| --- | --- |
| <img src="../evidence/character-chat-2026-10-17/active.jpg" width="200" alt="Native active sky with Sunny's compact bottom speech bubble and portrait"> | <img src="../evidence/character-chat-2026-10-17/studio.jpg" width="200" alt="Native script preview with the shared bubble, Continue and Close, and six character portraits"> |

**Source-bound native captures — October 17 character-chat follow-up, 17e / iOS 27.0 Simulator.** [Source hashes, later accessibility correction, small/large-phone checks and limits](../evidence/character-chat-2026-10-17/README.md). [Portrait sources/prompts](../../Artwork/Dialogue/README.md) retain the six generated masters; [authoring guide](../../App/DialogueScripts/README.md) explains future scripts. These captures establish sampled appearance, not actual VoiceOver, physical-device acceptance or parity with the newer storm phone branch.

## Welcome and entry

| Welcome | Entry |
| --- | --- |
| <img src="../evidence/sky-flow-2026-10-17/welcome.jpg" width="180" alt="Observatory welcome with crystal stars, Start a sky and Try First Light actions"> | <img src="../evidence/sky-flow-2026-10-17/entry.jpg" width="180" alt="Observatory entry with matching-star instruction, Begin and Back to Observatory"> |

**Selected native flow captures:** iPhone 17e / iOS 27.0 Simulator, normal motion, Calm effects off. [Sky-flow source hashes, checks and limits](../evidence/sky-flow-2026-10-17/README.md). Inspected October 17, 2026; these are recorded implementation frames, not a fresh capture of HEAD. Still frames do not verify the reveal animation.

**Earlier natural-orbit state:** [The natural orbit choice](../evidence/gravity-opportunities-2026-10-17/README.md) has an inspected integrated-board capture and source hashes. The [compact-HUD opening and gameplay captures](../evidence/compact-hud-2026-10-17/README.md) predate later art and flow work. Use that report to investigate historical HUD behavior; use the source-bound orbit capture for its sampled state.

**Launch screen:** A static dark storyboard and opaque app root share a named color. [Batch 1 native launch recordings and limits](../evidence/screen-flow-polish-2026-10-17/README.md) show the tested phone sequences; the opening board above remains gameplay, not a splash capture.

## Current Crystal Glow cast

<img src="../evidence/crystal-glow-integration-2026-10-17/materials.png" width="640" alt="Native Crystal Glow six-family cast export with large blue eyes, faceted bodies and four expressions">

**Native renderer export — source `6cc9efd`, iPhone 17e / iOS 27.0.** The user approved the Crystal Glow masters; [integration evidence](../evidence/crystal-glow-integration-2026-10-17/README.md) separates final material/interaction/motion checks from baseline accessibility failures and unverified device acceptance. The older cast exports below remain historical references.

## Historical cast comparisons

Crystal Glow supersedes the older body rendering. The [motion-candidate sheets](../evidence/star-cast-motion-2026-10-17/README.md) and [luminous revision](../evidence/star-cast-luminous-2026-10-17/README.md) remain historical comparison evidence; do not use them as the current cast reference. Their source and unresolved checks stay with those reports.

The [production cast contract](star-cast/README.md) owns names and recognition cues; the [runtime factory](../../App/StarCast.swift) owns rendering. Normal stars are worth 1, grown stars 2, dark stars 0. A contact sheet shows poses; it cannot demonstrate falling or turning motion.

## Reuse these visuals

Embed the existing file where it helps a decision; link this page for the full catalog. Keep paths relative, dimensions modest and proportions intact. Retain alt text, the asset/capture/concept distinction and a nearby evidence link. For the protocol and folder coverage rules, see [the writing process](../WRITING.md).

## Attraction field and gravity hole

<img src="../../App/Assets.xcassets/StarCastField.imageset/body.png" width="128" alt="Open blue-gold attraction aura with light wisps and a transparent center">
<img src="../../App/Assets.xcassets/StarCastHole.imageset/body.png" width="128" alt="Opaque dark gravity hole encircled by a luminous blue-gold accretion ribbon">

**Packaged production artwork — October 17, 2026.** Built-in imagegen sources and exact prompts are retained in [StarCast artwork](../../Artwork/StarCast/README.md#magnetic-crystal-and-gravity-hole). The field supersedes the solid magnetic crystal; [runtime evidence](../evidence/gravity-art-2026-10-17/README.md) separately covers small-size materials, native play and full/reduced motion.
