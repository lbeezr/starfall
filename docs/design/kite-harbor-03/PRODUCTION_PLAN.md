# Restore Kite Harbor in the regular app

**Status:** Implemented, development-verified and delivered · **Owner:** Current implementer · **Updated:** October 19, 2026

Add **Kite Harbor** as the third directly selectable 18-starlight challenge beside **First Light / Lantern Landing** and **Ribbon Crossing**. Restore a fleet of paper-kite boats through five complete paintings: folded sails open, mooring lights return and the lead mast star lights the fleet's gentle lift. The final painting shows the boats buoyant and ready for departure. Use the existing light transfer, full-image crossfade and normal result.

**Next action:** Observe physical play and revisit portrait contrast before RC accessibility acceptance. Development implementation and canonical delivery are complete. [Development evidence](../../evidence/kite-harbor-2026-10-19/README.md) records the scoped checks and limits. No new campaign, unlock, objective, generation algorithm or traversal animation. World travel and Murk's reaction belong to future user-generated clips/cutscenes; none are implemented here. The [atlas](../WORLD_ATLAS.md#03--kite-harbor--a-departure-made-possible) owns the location; [world-data.js](../world-01/world-data.js) owns the exact five beats.

<img src="../world-01/map-v1.png" width="540" alt="Approved twelve-location map, with Kite Harbor numbered 03 at the lower right, its pale kite sails fanning above rosewood docks">

**Approved generated map concept — not native evidence.** Inspected October 19, 2026; [original artwork and provenance](../world-01/README.md). Preserve the harbor's recognizable sails, small hulls and welcoming dock. Tiny figures in the map are not part of the new scene paintings.

## Scope and observable acceptance

- [x] Normal Welcome/menu offer Kite Harbor directly, with a named Entry, Help, result and replay. All three challenges retain seed 42, the current fixed opening, steady showers, 18-light target and existing overflow rule. Open sky stays the default. No campaign progress, unlock, extra currency or new scoring rule is added.
- [x] Core owns committed score and outcome. Scores 0/5/9/14/18 select the 0/25/50/75/100 paintings; text reports actual clamped progress, including truthful overshoot. Reaching 18 commits the win without waiting for a mast, boat or animation callback.
- [x] Existing survival, First Light and Ribbon saves preserve board, score, preview/RNG, pause and generation behavior. Kite Harbor round-trips through validated saves. Entry/replay previews zero without replacing the retained round until Begin; cancel resumes that round. Pending Open sky selects ordinary scenery.
- [x] Phone portrait, iPad portrait and iPad landscape each have five bespoke, consistent paintings of the same harbor. Compact-phone portrait is inspected; landscape uses the existing supported composition path but was not independently sampled for Kite. Render one continuous whole image with proportion-preserving cropping, without center masks, clearing patches, spatial fades or separately positioned image regions.
- [x] Source-art review: camera, dock outline, berth order, boat count, sail motifs and light fittings stay identifiable within each family. Previously restored lights/sails stay restored. At 75%, the lead mast star is visibly dark; at 100%, it is lit and the boats float slightly above their berths, ready to depart. The complete image retains the harbor and fleet rather than sending them out of frame.
- [x] Sparse and crowded native visual samples retain clear HUD/dialogue, recognizable cast and seven-column mapping. Standard native clears pass on phone and both tablet orientations, with full target geometry and stable progress through rotation. Inspect default and largest text; native dense-board interaction is reported separately from a visual sample.
- [x] Normal finishing light reaches the registered harbor focus before the existing result handoff; the full-image transition reveals the restored fleet. No tiny walkers, passengers, separate boat-flight effect, traversal clip or additional ripple is added. Playable SpriteKit stars and the ordinary ceremony cast remain unchanged.
- [x] Existing feedback and transitions stay bounded. Calm effects/system Reduce Motion and interrupted/restored states settle to the same committed result. Background, settings, restart, replay, rotation and scene replacement reject obsolete work. Reopening a completed save shows the restored harbor without replaying an unearned ceremony.
- [x] Focused Core, hosted/native, Debug/Release and resource-membership checks pass. Inspect all fifteen scenes, a crowded native sample and a normal-motion finishing clear. Exercise representative Lantern, Ribbon and survival siblings. Record source/build/device, failures and limits; actual VoiceOver is deferred to RC and physical play remains separate.
- [x] Verified changes merged in [PR #171](https://github.com/lbeezr/starfall/pull/171). The [canonical receipt](../../evidence/kite-harbor-2026-10-19/delivery.json) verifies current main installed in the original app, with unchanged identity and no reset/uninstall. Main CI was pending at installation.

## Five authored beats, one readable finish

| State | Exact authored beat | In-game interpretation |
| --- | --- | --- |
| **0%** | Folded boats sit at a still harbor, sails drooping and mooring stars unlit. | Intact but dormant craft, recognizable folds and berths; ambient sky stays bright enough to play. |
| **25%** | Light returns to the nearest mooring and one sail lifts. | One small, unmistakable recovery; retain the other dormant sails. |
| **50%** | Several sails unfold; breeze draws long curves through the harbor flags. | More open kite planes and curved flag silhouettes in the painting; keep the first mooring lit. |
| **75%** | The lead boat is ready except for its dark mast star. | All prior restoration remains; one unlit star creates anticipation. |
| **100%** | The mast catches light and the kite fleet lifts gently into the sky. | The final painting depicts the fleet buoyant just above the berths, with a lit mast star. A complete-scene crossfade presents that lift; no traveler or departure animation follows. |

The authored puzzle question is **“A first combined round: notice useful groups while keeping room for arrivals.”** Exercise that through the existing fixed round and clear feedback, without prescribing a move or inventing a new mechanic. The proposed story continues from Ribbon Crossing toward Seed Moon. Murk's double take and the cast's journey are future cinematic beats; the current result neither transports characters nor unlocks another place.

## Three views of the same harbor

| View | Composition and clearance |
| --- | --- |
| Phone portrait | Look down into an oval harbor in the upper third of the phone painting. A lead paper-kite boat supplies the final-star focus above the playable field; smaller berths recede to the sides. Preserve open navy sky through the center and lower field, with clouds/dock fragments only at outer edges. Keep tall sail tips clear of the score/header. |
| iPad portrait | Reveal a curved quay with three pale sails and lighter hull trim at the upper/side edges. Preserve the shared boat construction, rosewood decks and cream star fittings; keep the lead sail/mast focus outside the central seven-column field. |
| iPad landscape | Reveal longer connected quays and wider cloud banks, with the fleet spread through the upper/outer scenery. Keep the lead mast focal point above or beside the board and reserve a quiet continuous center; do not place rigging across the stars. |

Use rosewood docks, rounded cream ceramic moorings, pale cream/rose/blue or seafoam sails, lavender cloth accents and violet cloud banks over deep navy sky. The map and atlas establish these material relationships; exact hues are production choices. Craft should have broad folded-paper/kite planes, slender hulls and simple rigging, with modest differences between boats. Gold-white light returns to existing fittings instead of introducing new ornaments. The region's shared materials connect this harbor to Lantern and Ribbon without repeating their silhouettes.

Compose the quiet center into each painting. Ropes, pennants and sail seams must not resemble legal connections between pieces. No stars with faces, game pieces, text, HUD, labels or grid are baked into the art. `RestorationArtwork` and `RestorationLayout` in the [shared renderer](../../../App/RestorationEnvironment.swift) own native image selection, fitting and focal registration. The selected source paintings are 887 × 1774 pixels for phone, 1086 × 1448 for iPad portrait and 1448 × 1086 for iPad landscape. Their selected normalized light destinations are (0.326, 0.064) at the phone lead mast star, (0.254, 0.133) at the portrait lead sail/mast fitting and (0.092, 0.115) at the landscape lead mast fitting. These are artwork registration notes, not a second geometry implementation; native fitting/HUD clearance is inspected across all fifteen states. Portrait play HUD partly overlaps the lead sail/star; the result exposes it fully.

## Work in small batches

| Step | Owner | Exit |
| --- | --- | --- |
| Scope and artwork | Docs/art | This plan, inspected masters and five-state continuity in all three formats; provenance retained. |
| Challenge and compatibility | Core/flow | Third selectable identity, safe preview/cancel/replay, old-save compatibility and focused tests. |
| Shared scene integration | Native renderer | Complete paintings, score-derived state and registered light destination; no new cinematic subsystem. |
| Verification and delivery | Root | Native scene/input/lifecycle/motion checks, affected siblings, builds and canonical installation receipt. |

## Risk and verification

The main visual risk is broad sails or dense rigging competing with the HUD and puzzle. A stable 75% dark mast star and 100% lit star must remain legible in every crop. Review the paintings with actual cast bodies before native acceptance; inspect all fifteen states and real clears after registration. A still image does not prove the light-transfer/result sequence, and an offline full field does not prove native input.

Use the [verification matrix](../../ENGINEERING.md#verification-by-change) and [development accessibility cadence](../../DEVELOPMENT_BUILDS.md#accessibility-checks-by-build-stage). Record Core/save, hosted, native interaction, visual, normal-motion, Release, actual VoiceOver and physical-device results separately. All fifteen packaged source paintings were inspected on October 19. Each viewport family retains its camera, three boats, dock connections and open central sky. Sails and mooring lights recover cumulatively; the final lead star stays dark at 75% and lights at 100%, while the fleet remains visible and ready for departure. No baked-in characters or material artwork blockers were found. Separate [runtime evidence](../../evidence/kite-harbor-2026-10-19/README.md) verifies all fifteen native states, phone/tablet/compact portrait interaction, 49-star input, normal finish, Core/save and Debug/Release. The first full hosted run had one canvas-probe failure; the corrected 17-test affected rerun passes. Merge and canonical installation are verified. The portrait HUD partly covers the lead sail/star and lower white controls have weaker contrast over bright clouds; physical contrast, human satisfaction and actual VoiceOver remain follow-ups. The offline reviewer receives static logic checks only: the earlier local-file browser denial prohibits alternate-route workarounds, and browser rendering remains unverified.
