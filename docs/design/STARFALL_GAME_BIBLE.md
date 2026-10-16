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

**Starlight is the fiction for the existing cleared-shard count.** It is not an additional score formula, persistent balance, inventory, purchasable currency or reward to spend. A constellation would visualize that same progress, never introduce a second goal or force an extra animation before another turn.

**Screen hierarchy.** Keep Menu / Starfall / Settings, then progress and moves, then the dominant square board, a stable-height status area and New game. Use the existing safe-area layout and full-cell hit targets. Atmosphere stays behind play. A proposed compact constellation belongs near the progress area; it must not shrink the board or displace essential labels.

**Words the player sees — proposed consistent copy pass**
- Goal label: **Starlight · 0 / 70**; turns: **18 moves** / **1 move**
- First instruction: **Tap 3 or more matching starshards**
- Rules/help: **Match shards connected horizontally or vertically. Each shard releases 1 starlight. Reach 70 in 18 moves.**
- Invalid group: **Find 3 matching shards connected horizontally or vertically**
- Valid clear: **+{N} starlight**; free recovery: **A new group is ready**
- Win: **Sky illuminated**; detail: **{N} starlight released**
- Loss: **Out of moves**; detail: **{N} of 70 starlight released**
- Actions/settings: **New game**, **Continue**, **Menu**, **Settings**, **Gentle sound**, **Calm effects**

Use “starshard” for a board piece, “group” for connected matching pieces, “starlight” for round progress and “constellation” for its proposed sky visualization. “Jewel” may remain an internal code term; avoid mixing it into new player copy. VoiceOver retains descriptive kind names such as “Aqua diamond,” with position and group size; progress can read “{N} of 70 starlight.” These copy changes are not yet implemented.

## 3. Art direction: Candy Glass / Moonlight

**Palette and silhouettes are a contract, not decoration.** Rose circle **#FF5999**; aqua diamond **#47D9FF**; amber upward triangle **#FFC247**; violet hexagon **#B37DFF**; mint axis-aligned square **#59FFB8**. Keep shapes identifiable without color. Background moves from midnight **#090E2B** toward muted plum **#2E1A4A**. Near-white text and pale-cyan progress accents sit above subdued scenery.

**Material.** Candy Glass means luminous colored crystal, not gummy candy or flat neon. A generous body, broad bevels and a few purposeful facets should read at actual phone size. Use a consistent camera, light direction, scale and center pivot across all five types. Highlights should reveal volume without bleaching away the identifying color. Preserve spacing between pieces; sparkle never obscures a neighboring silhouette.

**Approved material reference.** The first aqua tilt video is the approved directional pilot: original 3D geometry rendered offline at several angles, then displayed as 2D sprite frames. Keep that genuine change of visible facet and reflection. It is not runtime 3D, physics-based gameplay glass or dynamic refraction of the live board. Approval establishes direction, not final production quality: the pilot still has overly white highlights at some angles, flatter positive-angle lighting and visible render grain at large size. Refine these while preserving its character.

**Art handoff.** Produce the five original shapes with transparent backgrounds, aligned neutral/tilt frames, consistent silhouette sizes and alpha padding. Preload and reuse textures. Protect atlas edges from filtering bleed and check dark-background fringes. Judge both neutral and moving crystals at roughly **34 pt visible size** on the existing narrow-phone layout, not only enlarged renders. Exact atlas sizes, frame counts and memory budget require profiling; do not multiply the pilot's nine 256 px frames across all pieces by default.

**The sky.** Sparse, low-contrast stars and restrained moonlight provide depth. The board is a quiet translucent stage, not a luminous cage. Constellation design and placement remain proposed; use a small original arrangement with steady progress, not a copied zodiac or branded emblem. No scenic effect may compete with the group under the player's finger.

## 4. Motion, sound and finish

**One turn has one readable sequence.** Touch responds; the selected group clears; surviving pieces settle; refill arrives; control returns. Keep the existing single-turn input lock and interruption safety. Visual drama must never create an extra move, score event or accidental double tap.

**Touch and clear.** Target a small tilt with a facet-light change, not continuous wobbling. Clearing should feel like chunky crystal breaking into a few substantial fragments and releasing soft sparks. Keep fragments local and short-lived, with a hard total cap; a large group must not produce a proportional screenful of debris. The desired feeling is a crisp release, not an explosive blast. A touch-down group preview and cancel behavior remain proposed; current input commits on touch end.

**Shooting-star refill — requested experiment, not implemented.** New shards should emerge from the upper-right ether and travel diagonally down-left into their assigned empty cells. Existing survivors must still fall straight down in their own columns. Resolve survivors first or separate their lanes clearly; use deterministic destination mapping and modest staggering so every arrival is understandable. Do not imply that existing pieces slide diagonally, alter adjacency or swap places. Test short bounded trails and a gentle settle; reject the treatment if crossing paths or delay makes the board harder to read. The exact trajectories and timing need a small in-game study before approval.

**Constellation release — planned presentation.** A restrained stream of light may connect the clear to sky progress, with one brief completion glow at the goal. Coalesce sparks for large groups. HUD progress remains immediate and authoritative; decorative travel must not hold input or simulate extra points.

**Calm effects / Reduce Motion.** Preserve all rules, outcomes and information. Omit tilt, flying fragments, long trails and moving sky effects; use settled states and restrained static emphasis. Respect the system setting. VoiceOver must identify groups and results without needing to see animation. No shake, flash, strobe or flashing low-move warning.

**Sound direction — proposed.** One soft glass note with a warm body per valid action; a light settling accent only if it adds clarity; a short, resolved completion phrase. Avoid brittle high-frequency shattering, reward-machine fanfares and one note per shard. Silence is a valid complete experience. Current Gentle sound is optional and off by default, using a system cue rather than bespoke audio; authored sound and device behavior remain unverified.

## 5. Scope, status and acceptance

**Existing baseline:** 7 × 7 rules, five color/shape kinds, 70/18 tuning, downward gravity and top refill, cleared-piece progress, inline outcomes, local save/resume and accessibility/settings paths. Default jewels use cached 2D glass textures. Source also contains a **DEBUG-only aqua pilot** with offline-rendered tilt frames and bounded fragment effects; this is experimental integration, not the finished five-piece material set.

**Approved direction, still to finish:** cohesive moonlit starshard world; the aqua pilot's pre-rendered 3D material direction; satisfying touch/clear effects. **Planned or experimental:** starshard/starlight copy pass, constellation visualization, diagonal shooting-star refill, full five-shape production assets, touch-down preview and authored sound. No claim of Apple simulator/device, audio, visual or performance validation is made by this document.

**Avoid outright:** timer pressure; power-ups; level maps; progression systems; accounts/backend; shop, currencies, ads, IAP or external SDKs; random reward language; consumptive mascot loops; overlapping jewel silhouettes; full-screen bloom; idle jewel movement; aggressive camera motion; extra modal celebration steps; copied IP. No paid assets or external publication are part of this handoff.

**Done means checked at phone scale**
1. All 49 cells and five silhouettes are immediately legible; text, safe areas, large text and at least 44 pt control targets are verified on Apple tooling
2. Valid, invalid and diagonal taps, rapid taps, final-move wins, free recovery, restart and interrupted/resumed turns produce exactly the correct settled board, move count and score
3. Neutral/tilted art keeps color identity, aligned pivots, clean alpha edges and stable apparent size; no atlas bleeding or distracting grain at device size
4. Clear fragments and refill trails are bounded, cannot obscure the next decision, and leave no transient nodes behind; frame pacing and memory are profiled on a supported device
5. Calm effects, Reduce Motion, VoiceOver labels/focus/results and sound off/on work in play, settings and resume. Decoration carries no exclusive information
6. A first-time player can explain: “Match three connected shards, release their light, illuminate the sky.” No new feature is needed to make that premise clear

**Working references:** VISUAL_HANDOFF.md supplies the earlier implementation/layout baseline; STARFALL_VISUAL_TARGET.png is a mood mockup, not a screenshot or production atlas. Its mascot and result overlay are not approved scope, and its idle progress/highlight are illustration errors. The approved aqua v1 pilot supplies the material/multi-angle reference. Where the older layered-material recommendation differs, this bible establishes the newer pre-rendered-3D direction while preserving 2D runtime and the small prototype scope.
