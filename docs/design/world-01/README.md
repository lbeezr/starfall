# Starfall world concept package

**Status:** Murk and all twelve locations approved by the user · **Owner:** Current implementer · **Updated:** October 18, 2026

The approved foundation is **Murk, the Hungry Moon**, and twelve connected places the star cast restores. Preserve the character sheet and the map’s destinations. The user subsequently requested a full creative rewrite: the [game bible](../STARFALL_GAME_BIBLE.md) now owns lore, characters and story; the [world atlas](../WORLD_ATLAS.md) develops every place’s life, appearance and distinctive reward.

**Start here:** Open the [concept explorer](index.html) to select a numbered location and read its five restoration states. The [restoration contract](../STARLIGHT_RESTORATION.md) owns progress and the win boundary. **Revised visual study:** [Lantern Landing’s overhead playfield](../lantern-landing-01/board.html) places existing star bodies in the seven-column field above the landing. It supersedes the rejected close-up scene composition. **Current production slice:** Lantern Landing is implemented and development-verified in optional First Light; see its [native evidence](../../evidence/lantern-landing-2026-10-19/README.md). Main integration and phone delivery are pending. The twelve-location traversal remains a design concept.

## The approved images

<img src="murk-v1.png" width="900" alt="Approved Murk character concept, including crescent-rimmed moon body, floating hands, smoky tail, expressions and a four-beat theft sequence">

**User-approved character concept — not gameplay or a production model.** Generated with the built-in image tool on October 18, 2026. Use this sheet for Murk’s appearance; the embedded “working concept” label records its creation state. The later approval does not require regenerating or redesigning him. The glowing shapes inside him represent ambient starlight, not captured living helpers; make that distinction clear through production staging.

<img src="map-v1.png" width="700" alt="Approved twelve-location Starfall map, a winding route across four tiers of miniature realms">

**User-approved map and location concept — not runtime UI or a saved progress state.** The artwork mostly depicts restored destinations. Dormant/intermediate states remain written storyboards except for the separate [Lantern Landing implementation and concept study](../lantern-landing-01/README.md). The small map cameo is sharper than the character sheet; match future close appearances to that sheet. Tiny helper shapes are placeholders for the approved Crystal Glow cast.

Both original PNGs and the exact [generation prompts](prompts.json) are retained. No new character or map images were generated for the bible rewrite.

## What the explorer contains

The route has twelve levels total in four regions: Soft Skies, Wild Moons, Clockwork Belt and Night’s Edge. The illustration’s route runs across the bottom tier from left to right, reverses on the next tier and continues to Hollow Crown at upper left.

[world-data.js](world-data.js) supplies the twelve ordered location records, sixty restoration notes, local payoffs and connections. The buttons show **written states**, not five rendered versions of the art. Selecting a new place resets the review state to 0%; this is a document control, not game progress or persistence.

The explorer is local HTML with no external dependencies. Open index.html directly, or serve the design folder from the repository root and visit `/world-01/`:

```sh
python3 -m http.server 8769 --bind 127.0.0.1 --directory docs/design
```

## Decisions retained from the conversation

- The user approved Murk **as made** and loved all twelve map locations. The final spelling is **Murk**. Earlier non-celestial antagonist exploration is closed by this choice.
- The user suggested these might be the stars’ homes. The bible and atlas develop shared neighborhoods, gardens, workplaces and routes; exact residences remain an authored proposal.
- A separate recurring hero remains open. It is not a prerequisite for the ensemble story and does not reopen Murk’s design.
- The journey, detailed lore, state pacing and finale are design work. Current app rules, routing, environments and saves are unchanged.

## References and provenance

The user’s Mario, Paper Mario, Mario 3D World and Kamek references inform readable miniature realms, connected travel and brief character performances. Nintendo’s [Mario 3D World manual](https://www.nintendo.com/eu/media/downloads/games_8/emanuals/wii_u_6/super_mario_3d_world_3/ElectronicManual_WiiU_SuperMario3DWorld_EN.pdf) describes course selection and cleared-state visibility; its [Paper Mario: The Origami King description](https://www.nintendo.com/us/store/products/paper-mario-the-origami-king-switch/) connects travel with repairing a damaged world. The [Kamek reference note](../STARLIGHT_RESTORATION.md#kamek-reference-a-brief-entrance-with-a-clear-consequence) records source limits. Reference text was consulted; no comparative play session was performed.

The prompt record preserves original wording even where generation differed: the map request described mixed progress, while the resulting image mostly depicts restored destinations. The map is used accordingly. The original generated files remain in Codex storage; these repository copies are durable design assets outside the app target.

## Verification

The approved map, Murk sheet and existing native cast export were visually inspected. The explorer’s location menu, map selection, first/last boundaries, restoration buttons and keyboard activation were checked in the desktop in-app browser. Source for this work is the documentation/concept working tree based on `f35eba8`; no app, Core, project or packaged resource files were changed.

**Passed:** local file/image references; twelve unique ordered locations in four groups of three; all sixty nonempty state notes; all twelve names present in the bible and atlas; byte-for-byte preservation of the old bible; `python3 scripts/ci-hygiene.py`; `git diff --check`. A final browser check confirmed Hollow Crown at 100%, disabled Next at the last location, keyboard activation and no captured console warnings/errors.

[Desktop explorer review](explorer-review.jpg): in-app browser, 1280 × 720, October 18, 2026. It shows a written finale state beside the approved art; it is not a restored gameplay render. The Markdown manuscripts were structurally reviewed and link-checked; a separate rendered Markdown review was not performed. Mobile layout, actual VoiceOver and native gameplay are unverified for this concept. No new Apple build, simulator play, physical-device or human-play acceptance is claimed. The atlas and bible are creative documents, not runtime evidence.

**Publication reconciliation — October 19, 2026:** Rebased the design package onto main `69dd27d`, preserving its five native nightscapes, gameplay changes, delivery records and historical environment production document. The obsolete map-section link was corrected and Dusk’s narrative was aligned with the bible. Clean candidate `41f19c4` passed repository hygiene, range whitespace checks and 472 local file/heading references; all twelve ordered locations and sixty state notes were checked, and the original bible remains byte-identical to `f35eba8`. All 20 changed paths are documentation or offline concept assets. Core tests, native builds and phone installation are not applicable to this shipment because no app, resource, build or rule files change. The prior browser capture remains source-bound to the October 18 document snapshot.
