# Five playable night journeys

**Status:** Accepted for production · **Owner:** current implementer · **Updated:** 2026-10-18

Ship Moonwake, Nebula Cradle, Shatterlight Reach, Night Garden and Ringdrift as cosmetic settings for the existing game. The approved [color keys](../night-keys-08/README.md) establish their appearance; the [scene kits](../scene-kits-07/README.md) establish their layers and props. User approval now includes native integration and delivery.

**Implementation:** sixteen alpha assets are packaged in the regular Debug/Release app. `LandingGeometry` centers gameplay; `NightSceneLayout` composes the scenery around it. [Native verification and delivery](../../../evidence/nightscapes-2026-10-18/README.md) records the tested source and remaining physical/RC limits.

## Scope and success

- All five settings are selectable and persist using compatible existing preference values. No progression or rule changes.
- Seven gameplay columns remain centered at phone and iPad sizes, including rotation. Native hit cells and SpriteKit use the same mapping; a native tap and directional swipe must verify it.
- Each setting has five separately controlled depth planes. Landmarks, near scenery and local light effects are independently placed; no platform, contact shadow or decorative cast row.
- Existing shooting-star forecast, exact grouped score (including 100,000 and larger), menu, dialogue and actions stay readable. Large text reflows and scrolls without obscuring stars.
- Motion is bounded and pauses on interruption; Calm effects and Reduce Motion are still. Ambient scenery cannot mutate game state or receive gameplay touches.
- Core and affected hosted/UI tests, Debug and Release simulator builds, normal play, rapid input, outcome/restart, settings, interruption and sampled accessibility checks pass. Screenshots and motion inspection use native runs.
- Reconcile with current main again before publishing. Deliver the original phone app only through `scripts/device-update.py`; record its verified installed receipt, or explicitly report the connection blocker.

## Production batches

1. Reconcile current gameplay and save contracts.
2. Produce alpha art and implement shared centered geometry and scenic assembly.
3. Validate all five settings and preserve source-bound evidence.
4. Integrate verified work into main and run canonical delivery.

## Boundaries

This folder owns production decisions and generation provenance. Packaged image sets inherit App/README.md; generated tool intermediates remain outside Git. Image generation produces the raster art; native code composes it and draws only small analytic light effects. The approved flat keys remain concepts, not runtime evidence. Actual VoiceOver and physical-device claims require actual runs; simulator checks do not substitute for either.

## The assembled kits

All destinations share a still dark field and a very faint separate veil. These five planes remain behind the real cast and native HUD; no decorative hit target competes with a star.

| Destination | Distant landmark | Independent story detail | Near plane |
| --- | --- | --- | --- |
| Moonwake | Pearl moon | Separate hull and softly turning sail cloth; local lantern glow | Ice fragment |
| Nebula Cradle | Left gas bank | Right bank with sheltered local birth-light | Faint cloud fringe |
| Shatterlight Reach | Three separated curved fragments, each drifting independently | Small surviving observatory shelter and window light | Dim near shard |
| Night Garden | Broad alien canopy | Separate amber pod and small dark moth | Near canopy silhouette |
| Ringdrift | Planet between rear/front portions of a separate ring asset | The recurring sail | Shepherd moon and ice |

Phone/tablet portrait keeps major silhouettes above and below the field. Wide tablets place larger silhouettes in side margins. The hull/cloth retains common source coordinates, and Ringdrift's two native masks place the same rings behind and before the planet. Motion is tiny (at most two points of drift, 1.2 degrees of sail rotation), with no camera shake or catch-up after an interruption.

## Generation provenance

The built-in `image_gen` tool produced every raster component from the approved color keys. [assets.json](assets.json) records the sixteen selected files, exact prompts/references, dimensions, alpha extrema and SHA-256; [generation.json](generation.json) also retains the two rejected combined intermediates. Selected PNGs were copied unchanged into named image sets. Alpha inspection confirmed transparent pixels; no matte removal, pixel resampling or CLI generation was used. Native code supplies only small local light effects, the static star field and composition.

The approved [five-key overview](../night-keys-08/overview.jpg) remains the concept reference. Actual native screenshots belong in the linked verification record, because this production manifest alone cannot establish visual acceptance or animation quality.
