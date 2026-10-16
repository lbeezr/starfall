# STARFALL
## Mini game bible · 16 October 2026

**A little pocket of moonlight. Release the light inside fallen crystals and help the sky shine again.**

Design direction and compact art/game handoff. This document describes the approved premise and separates existing behavior from planned presentation. Numerical balance remains provisional. It does not expand the prototype's feature scope.

## 1. The world and the promise

**Premise.** Starshards hold starlight. Joining matching shards releases their light toward a constellation; reaching the round's goal illuminates the sky. The player is restoring a small, beautiful night sky, one satisfying choice at a time.

**Feeling.** Quiet wonder, tactile delight, gentle concentration. A round should feel like handling precious little objects in a moonlit dream. Relaxing does not mean passive: the move limit gives choices weight, without a timer or urgency effects.

**Three pillars**
- **Beautiful to touch:** solid, chunky crystals with believable facets, small tilts and responsive highlights
- **A readable little ritual:** choose a group, release its light, watch the board settle, choose again
- **One coherent night:** materials, sky, motion, words and sound all express the same calm celestial world

**World boundaries.** The sky, the starshards and their released light are enough story for the first version. No exposition screen, named kingdom, factions or lore glossary. A distant hill silhouette or crystal-ball-like intimacy may inform atmosphere, but is a proposed composition, not a new scene or feature requirement. Moon imagery is atmospheric; no moon-phase rules, calendar or changing difficulty is implied.

The references contribute a sense of falling-star magic, storybook warmth and lunar spectacle. All artwork and visual grammar must be original: do not reproduce recognizable characters, spell icons, interfaces, names or signature compositions. The quality ambition is precision and charm at every interaction, not the size of a commercial adventure.

**Optional later companion.** A small original guide could notice or gather released light. It never eats paid resources, demands feeding or establishes a collection economy. No mascot design is approved for production; the companion in the older concept image is illustrative, not a requirement.

## 2. The game, in one round

**Platform:** iPhone first, iOS 17+, SwiftUI shell and SpriteKit board. The deterministic game rules remain independent of rendering.

- A **7 × 7** board contains five kinds of starshard, each with a unique color and silhouette
- Tap **3 or more matching shards connected horizontally or vertically**; diagonal contact does not count
- Every valid group uses **one move**. Each cleared shard contributes **one starlight** toward this round's goal
- Provisional tuning: **70 starlight in 18 valid moves**. There is no timer; invalid taps spend nothing
- Surviving shards fall down within their columns. Refill restores the board; newly formed groups do not automatically clear or score
- Reaching the goal wins, including on the final move. Otherwise zero moves ends the round
- A dead board receives bounded, free recovery so play can continue. The current implementation replaces three bottom-row cells to ensure a group; do not depict this as a full-board shuffle

**Starlight is the fiction for the existing cleared-shard count.** It is not an additional score formula, persistent balance, inventory, purchasable currency or reward to spend. The static HUD constellation visualizes that same progress, with no second goal or extra animation before another turn. The score remains truthful above 70; only the progress fraction caps at its goal.

**Screen hierarchy.** Keep Menu / Starfall / Settings, then progress and moves, then the dominant square board, a status area that can grow with text and New game. Use the existing safe-area layout and full-cell hit targets. Atmosphere stays behind play. The compact constellation sits beside the progress rail; preserve the board and essential labels as layouts adapt to larger text.

**Words the player sees — implemented copy**
- Goal label: **Starlight · 0 / 70**; turns: **18 moves** / **1 move**
- Menu instruction: **Tap 3 or more matching starshards connected horizontally or vertically.**
- Menu rules/help: **1 shard = 1 starlight. No timer. Groups of one or two spend no move.**
- Ordinary clear: **+{N} starlight**; recovery and terminal messages take precedence
- Win: **Sky illuminated**; detail: **{N} starlight released**
- Loss: **Out of moves**; detail: **{N} of 70 starlight released**
- Actions/settings: **New game**, **Continue**, **Menu**, **Settings**, **Gentle sound**, **Calm effects**

Use “starshard” for a board piece, “group” for connected matching pieces, “starlight” for round progress and “constellation” for its sky visualization. The [screen copy](../../App/StarfallApp.swift) and [HUD](../../App/StarlightHUD.swift) already use much of this vocabulary. **Remaining consistency pass:** [GameStore](../../App/GameStore.swift) still uses “jewels” in initial/invalid instructions and score announcements, and “cluster” in restart/recovery messages. The proposed invalid wording is **Find 3 matching shards connected horizontally or vertically**; recovery wording is **A new group is ready**, retaining the existing explanation that no extra move was used. VoiceOver keeps descriptive kind names, position and group size; the score accessibility label still reads “{N} of 70 jewels cleared” for compatibility. Changing that contract to starlight needs its own source and native verification.

## 3. Art direction: Candy Glass / Moonlight

**Palette and silhouettes are a contract, not decoration.** Rose circle **#FF5999**; aqua diamond **#47D9FF**; amber upward triangle **#FFC247**; violet hexagon **#B37DFF**; mint axis-aligned square **#59FFB8**. Keep shapes identifiable without color. Background moves from midnight **#090E2B** toward muted plum **#2E1A4A**. Near-white text and pale-cyan progress accents sit above subdued scenery.

**Material.** Candy Glass means luminous colored crystal, not gummy candy or flat neon. A generous body, broad bevels and a few purposeful facets should read at actual phone size. Use a consistent camera, light direction, scale and center pivot across all five types. Highlights should reveal volume without bleaching away the identifying color. Preserve spacing between pieces; sparkle never obscures a neighboring silhouette.

**Approved material reference.** The first aqua tilt video remains the approved directional pilot: 3D geometry rendered offline at several angles, then displayed as 2D sprite frames. Keep that genuine change of visible facet and reflection. It is not runtime 3D, physics-based gameplay glass or dynamic refraction of the live board. The original aqua asset remains available through the explicit Debug-only `--crystal-pilot` comparison; it is separate from the current default family. The [earlier quality review](CRYSTAL_QUALITY_REVIEW.md) records that older family's pale highlights and grain. Directional approval does not establish native acceptance of a replacement.

**Art handoff and runtime adoption.** The [sealed v2 family](../../Artwork/Crystals/v2/README.md) is now the default in Debug and Release. This is newly authored editable Blender geometry, material and lighting, not recovered original source or an alpha-identical replacement. Its [manifest](../../Artwork/Crystals/v2/manifest.json) and [recreation review](../../Artwork/Crystals/v2/review/REVIEW.md) preserve provenance, source-reproduction receipts and explicit old-to-new geometry differences. The package's `runtime_adopted: false` records its sealed pre-adoption handoff state; runtime integration copies the five imagesets into the app without rewriting that evidence.

Each transparent atlas contains nine 256 px frames, with neutral index 4 (zero-based) and a fixed center pivot. [StarshardArtwork](../../App/StarshardArtwork.swift) validates padded frames, caches textures and normalizes neutral silhouette size. The scene uses the family only when all five kinds load; any missing or malformed member selects the existing procedural material factory for the complete board. Preserve full canvases and centered anchors during material refinement. Protect atlas edges from filtering bleed and check dark-background fringes. Judge both neutral and moving crystals at roughly **34 pt visible size** on the existing narrow-phone layout, not only enlarged renders. Offline package checks and runtime activation do not establish native sampling, motion, accessibility or device-memory acceptance; exact executed checks belong in the [validation record](../VALIDATION.md).

**The sky.** Sparse, low-contrast stars and restrained moonlight provide depth. The current backdrop is static and the board uses a quiet opaque surface. The HUD has a small original constellation showing the existing progress fraction; keep its arrangement distinct from a copied zodiac or branded emblem. No scenic effect may compete with the group under the player's finger.

## 4. Motion, sound and finish

**One turn has one readable sequence.** Touch responds; the selected group clears; surviving pieces settle; refill arrives; control returns. Keep the existing single-turn input lock and interruption safety. Visual drama must never create an extra move, score event or accidental double tap.

**Touch and clear.** Target a small tilt with a facet-light change, not continuous wobbling. Clearing should feel like chunky crystal breaking into a few substantial fragments and releasing soft sparks. Keep fragments local and short-lived, with a hard total cap; a large group must not produce a proportional screenful of debris. The desired feeling is a crisp release, not an explosive blast. [JewelScene](../../App/JewelScene.swift) implements a static touch-down preview of valid groups by dimming other pieces. Moving off the starting cell cancels; input commits only when the tracked touch ends in that same cell. The preview does not spend a move.

**Shooting-star refill — implemented, aesthetic acceptance pending.** [StarfallArrivalEffects](../../App/StarfallArrivalEffects.swift) moves survivors straight down within their own columns before new shards travel diagonally down-left from beyond the board's upper/right edge into their assigned cells. The board clips the off-board portion; this is not yet travel through the surrounding sky. Arrival staggering and trails are bounded, with at most one trail per affected column; recovery replacements fade in place. These are presentation paths over deterministic destinations, with no change to adjacency, scoring or piece identity. Inspect trajectories, crossing paths, timing and settled clarity in play before approving the treatment's feel.

**Constellation release — planned presentation beyond the static HUD.** A restrained stream of light may connect the clear to sky progress, with one brief completion glow at the goal. Neither effect is implemented. Coalesce sparks for large groups. HUD progress remains immediate and authoritative; decorative travel must not hold input or simulate extra points.

**Calm effects / Reduce Motion.** Preserve all rules, outcomes and information. Omit tilt, flying fragments, long trails and moving sky effects; use settled states and restrained static emphasis. Respect the system setting. VoiceOver must identify groups and results without needing to see animation. No shake, flash, strobe or flashing low-move warning.

**Sound direction — quiet-tuck starter integrated.** The user selected all four short, muted quiet-tuck takes as the material anchor, finding glassy resonance lightweight and sparkly. [GameFeedback](../../App/GameFeedback.swift) now rotates those four local contacts once per valid clear, including terminal clears, through [QuietTuckPlayer](../../App/QuietTuckPlayer.swift). Keep rounded warmth, short damping and space between actions; avoid brittle shattering, reward-machine fanfares and one note per shard. Gentle sound stays optional and off by default; silence is a complete experience. Haptics retain their existing Calm effects/Reduce Motion policy. Fuller clears, a soft completion resolution and sparse warm music remain exploration; no extra settle or music layer is connected. The [integration record](audio/INTEGRATION.md) separates native checks from audible/haptic quality and physical-device acceptance.

## 5. Scope, status and acceptance

**Implementation status:** this revision describes the sealed v2 family's runtime adoption and the integrated quiet-tuck sound starter. The [design system](DESIGN_SYSTEM.md) records shared presentation contracts; the [validation record](../VALIDATION.md) identifies executed native checks and their exact source/evidence limits. The sealed artwork package retains its earlier handoff status. Source existence is not visual, device or human acceptance, and this documentation update performs no new native run.

**Existing baseline:** 7 × 7 rules, five color/shape kinds, 70/18 tuning, downward gravity and top refill, immediate starlight HUD with a static constellation, inline outcomes, local save/resume, touch preview/cancellation, diagonal refill presentation and accessibility/settings paths. The complete v2 crystal family and its bounded fragments are now the ordinary Debug and Release rendering path, with a complete procedural fallback and no family-enabling launch argument. The original aqua pilot remains an explicit Debug-only `--crystal-pilot` comparison, using procedural artwork for the other four kinds. The legacy asset and sealed v2 source package remain distinct.

**Approved direction, still to finish:** cohesive moonlit starshard world; the aqua pilot's pre-rendered 3D material direction; satisfying touch/clear effects. Remaining work includes copy consistency, native review and device profiling of the adopted family, motion/feel review, the proposed clear-to-constellation light/glow and sound exploration beyond the integrated quiet-tuck starter. Actual VoiceOver, system Reduce Motion operation, broader layout coverage, audible/haptic feel, physical-device performance and human play balance retain their source-bound evidence limits. Settings now opens directly in a large sheet at every text size; its old medium-height presentation is retired. The captured medium-sheet text-clipping report remains unresolved historical evidence, not a proven false positive. Preserve these boundaries when assessing the checklist below.

**Avoid outright:** timer pressure; power-ups; level maps; progression systems; accounts/backend; shop, currencies, ads, IAP or external SDKs; random reward language; consumptive mascot loops; overlapping jewel silhouettes; full-screen bloom; idle jewel movement; aggressive camera motion; extra modal celebration steps; copied IP. No paid assets or external publication are part of this handoff.

**Done means checked at phone scale**
1. All 49 cells and five silhouettes are immediately legible; text, safe areas, large text and at least 44 pt control targets are verified on Apple tooling
2. Valid, invalid and diagonal taps, rapid taps, final-move wins, free recovery, restart and interrupted/resumed turns produce exactly the correct settled board, move count and score
3. Neutral/tilted art keeps color identity, aligned pivots, clean alpha edges and stable apparent size; no atlas bleeding or distracting grain at device size
4. Clear fragments and refill trails are bounded, cannot obscure the next decision, and leave no transient nodes behind; frame pacing and memory are profiled on a supported device
5. Calm effects, Reduce Motion, VoiceOver labels/focus/results and sound off/on work in play, settings and resume. Decoration carries no exclusive information
6. A first-time player can explain: “Match three connected shards, release their light, illuminate the sky.” No new feature is needed to make that premise clear

**Working references:** VISUAL_HANDOFF.md supplies the earlier implementation/layout baseline; STARFALL_VISUAL_TARGET.png is a mood mockup, not a screenshot or production atlas. Its mascot and result overlay are not approved scope, and its idle progress/highlight are illustration errors. The approved aqua v1 pilot supplies the material/multi-angle reference. Where the older layered-material recommendation differs, this bible establishes the newer pre-rendered-3D direction while preserving 2D runtime and the small prototype scope.
