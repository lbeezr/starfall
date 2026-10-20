# Design documents

[Pokémon Puzzle League reference](POKEMON_PUZZLE_LEAGUE_REFERENCE.md) records the user's primary gameplay inspiration, verified source behavior and adaptation guidance for scoring, pressure, progression and future local versus/co-op.

[Game UI system](GAME_UI_SYSTEM.md) owns the scenic three-mode home, authored native component family and quiet viewport-edge HUD, adopted for development in the normal app. Exact coverage and canonical delivery status are recorded in the [native evidence](../evidence/observatory-ui-native-2026-10-19/README.md); the [capture index](../evidence/observatory-ui-native-2026-10-19/captures.json) identifies inspected appearances. The atlas remains concept guidance and the source kit keeps its own export evidence.

[UI production](UI_PRODUCTION.md) turns approved concepts into reusable native components through state/layout inventories, asset contracts, one working native slice and mixed-state review before family expansion. The [modular map contract](world-01/production/layered-2026-10-20/README.md) applies this workflow to six independent island families in the normal app. [Combined-source checks](../evidence/ui-adversarial-2026-10-20/current-main-validation.json) and [map captures](../evidence/ui-adversarial-2026-10-20/current-main-captures.json) cover living-light and authored Lantern/Ribbon integration; the [dialogue/Studio correction](../evidence/ui-adversarial-2026-10-20/dialogue-fit-validation.json) completes development adoption at `9472691` / `dev.d4ba8a7698`. Earlier checkpoints and rejected whole-map plates retain their scope in the [implementation history](../evidence/ui-adversarial-2026-10-20/IMPLEMENTATION.md).

[Level-design kit](level-design-kit/README.md) is the current starting point for restoration-board art: native dimensions and bleed guides, camera and star-scale references, the reusable brief, and the Hearthstone research translated into production checks.

Behavior proposals, production contracts and research supporting decisions.

[Quiet input response](QUIET_INPUT_RESPONSE.md) releases input when the static final board is already rendered.

[Hold-to-draw feedback](HOLD_DRAW_FEEDBACK.md) defines open-ray progress and a distinct armed state.

[Gesture edges](GESTURE_EDGES.md) specifies valid long flicks and unchanged tap/drawing boundaries.

[Follow-up input](FOLLOW_UP_INPUT.md) retains one recent tap or swap while its stars finish presentation; [immediate swipes](IMMEDIATE_SWIPES.md) owns movement versus held drawing.

[Starlight celebrations](STARLIGHT_CELEBRATIONS.md) investigates more prominent accumulation, dramatic clear/constellation feedback, and the separate design questions behind combos and recipes. User-approved mock and normal-target integration using existing constellation, recipe, relay and Dusk rules.

## Start here

[Lantern Landing](lantern-landing-01/README.md) is implemented, merged and delivered in optional First Light, with five restoration states and bespoke phone/tablet scenes. The [comparison viewer](lantern-landing-01/board.html) remains a concept; [native evidence and verified installation](../evidence/lantern-landing-2026-10-19/README.md) record `dev.5afe4a3c23`, delivered from main `ab868b5` in the original app. Native dense-board checks cover 40 stars; physical play and actual VoiceOver at RC remain separate acceptance.

[Ribbon Crossing](ribbon-crossing-02/README.md) is the implemented second restoration challenge. [Original development evidence](../evidence/ribbon-crossing-2026-10-19/README.md) covers all fifteen inspected states, phone/tablet interaction, normal/quiet completion and final hosted/Release passes and verified canonical installation. Its [production plan](ribbon-crossing-02/PRODUCTION_PLAN.md) and [composition viewer](ribbon-crossing-02/board.html) cover three five-state artwork families and the existing light-transfer/full-image completion. Character travel is reserved for future generated cutscenes. New Lantern/Ribbon visits now use distinct authored openings and 150,000/220,000 objectives; [verification](../evidence/story-first-pair-2026-10-20/README.md) is in progress. Historical rounds retain their original 18-light rules.

[Kite Harbor](kite-harbor-03/README.md) is the implemented third optional 18-light challenge, with [verified development evidence](../evidence/kite-harbor-2026-10-19/README.md); merge and canonical installation are verified. Its [production plan](kite-harbor-03/PRODUCTION_PLAN.md) and [composition reviewer](kite-harbor-03/board.html) preserve the authored sail/mooring restoration through three whole-image families. The final fleet is buoyant and ready for departure; travel clips are future work.

[Seed Moon](seed-moon-04/README.md) is the implemented fourth optional 18-light challenge, with verified development acceptance; merge and canonical installation are verified. Its [plan](seed-moon-04/PRODUCTION_PLAN.md) and [reviewer](seed-moon-04/board.html) retain the exact root/shoot/closed-bud/open-canopy beats. [Current evidence](../evidence/seed-moon-2026-10-19/README.md) records the source-art package, earlier Core/tooling, hosted/native flow, tablet rotation/clears and final phone dense input/motion. Compact, Release and focused overflow checks pass; merge and canonical installation are verified.

The rewritten [game bible](STARFALL_GAME_BIBLE.md) owns the approved Murk/map foundation and developed lore, cast and story. The [world atlas](WORLD_ATLAS.md) gives all twelve restoration locations their daily life, appearance and payoff. The [restoration contract](STARLIGHT_RESTORATION.md) owns progress/win behavior; [approved art and explorer](world-01/README.md) retain the images and sixty written states. Six locations are ready through [Frostfruit Orchard](frostfruit-orchard-06/README.md), and six remain unbuilt. The [local world journey](../OFFICIAL_LOCATIONS_AND_TUTORIAL_PLAN.md) provides the painted map, committed repairs and sequential access; the old selectable nightscapes are retired. The modular map renderer remains separate from progression rules.

[Celebration lettering](celebration-lettering/README.md) compares custom Pearl, Crystal and Comet treatments for central reward notices; concept only; the [complete Crystal Comet set](celebration-lettering/crystal-comet-01/README.md) develops the user-selected Crystal Burst lead with a 70/20/10 supporting blend.

[Harvest feedback](HARVEST_FEEDBACK.md) refines scoring light and central combo celebrations without changing the committed award.

[UX writing research](UX_WRITING_RESEARCH.md) audits copy against UX and game-dialogue sources and defines the vocabulary, six voices and acceptance checks behind the authorized rewrite. The [copy authoring guide](../../App/DialogueScripts/README.md) owns implemented wording and event policy.

[Calibration](CALIBRATION.md) holds the mechanic set steady and sequences measured balance, native play and bounded refinement.

[Star techniques](STAR_TECHNIQUES.md) owns exact square/cross recipes, swipe-and-hold exchanges, tap equivalents and deliberate relays.

[Dusk feeding](DUSK_FEEDING.md) owns gray-star rewards, the three-feed collapse and explicit saved-rule adoption.

[Responsive taps and concurrent play](INTERACTION_FEEDBACK.md) owns column reservations, contact feedback and ordinary tap/trace classification.

[Announced pacing adoption](PACING_ADOPTION.md) owns the user-selected production cadence, save boundary and phone delivery acceptance.

[Next pacing design](PACING_NEXT.md) analyzes the current source split, usable input time and a bounded timing comparison after opening/tracing integration. Proposed only.

[Screen-flow polish](SCREEN_FLOW_POLISH.md) proposes safe staged Entry, opaque launch, continuous handoffs and explanatory results; its [implementation plan](../SCREEN_FLOW_PLAN.md) sequences the work. Draft only; the existing adopted flow remains the current implementation.


[Notification plan](NOTIFICATIONS.md) records the accepted optional weekly reminder policy; implementation is deferred.

Use the [design template](../templates/DESIGN.md). Start with [shower phases](SHOWER_PHASES.md) for the active rhythm comparison, [visual reference](VISUAL_REFERENCE.md) for imagery, [star cast](star-cast/README.md) for runtime art, and [audio](audio/README.md) for sound. Older original-puzzle documents are context, not current scope; consult [the roadmap](../ROADMAP.md).

For current scene work, start with the [level-design kit](level-design-kit/README.md) and registered restoration compositions. The retired [five layered nightscapes](environments/night-production-09/README.md) and their [native verification](../evidence/nightscapes-2026-10-18/README.md) retain historical reference value.

The historical [five celestial homes](environments/celestial-worlds-04/README.md) preceded the approved nightscape redesign: new astronomical locations and cast-compatible palettes using the accepted [living-worlds template](environments/living-worlds-03/README.md). Both follow the [Hearthstone board study](environments/hearthstone-study/README.md); these platform concepts were superseded before publication.

The [branding studies](branding/README.md) retain the editable wordmarks, sanctuary covers and falling-icon comparisons outside the app target.

[Diagonal constellation trial](CONSTELLATION_TRIAL.md) defines the isolated five-star connectivity comparison and its adoption gates.

[Constellation tracing](CONSTELLATION_TRACE.md) supersedes whole-component taps with deliberately selected stars and bounded input/feedback.

[Cadence consumer contract](PACING_CORE_CONTRACT.md) defines versioned Core timing, exact interval/warning indexing, replay and test-only comparison boundaries.

[Store cadence contract](PACING_STORE_CONTRACT.md) defines immutable next-shower cues, hosted-only fixture reuse and Debug measurement semantics.

[User-only pacing playtest](PACING_PLAYTEST.md) defines the initial matched-seed A/B session; candidate handoff and human observations remain pending.

[Welcome, entry and sky endings](SKY_FLOW.md) owns the selected overlapping reveal and offline resume/replay behavior.

[Gravity design](GRAVITY_MECHANICS.md), [implementation plan](GRAVITY_MECHANICS_PLAN.md) and [mechanic research](CELESTIAL_MECHANICS_RESEARCH.md) describe magnetic pairs and occupied captive orbits, now adopted into new skies. The historical trial and current integration evidence retain separate source boundaries.

[Reliability polish](RELIABILITY_POLISH.md) scopes touch ownership, build identity and layout/native acceptance in normal Starfall.

- [Character chat and complete trails](CHARACTER_CHAT_AND_TRAIL.md): reusable bottom dialogue, six portraits and authored scripts.

[Late-calm magnetic opportunities](GRAVITY_OPPORTUNITIES.md) owns generation-3 supply tuning, retained replay and its bounded adoption criteria.

[Universal critical mass](CRITICAL_MASS.md) replaces new-sky Dusk arrivals with aging, purple warning and bounded implosion; retained rounds keep their saved mechanics.

[Touch intent](TOUCH_INTENT.md) records HCI research and the forgiving swap/constellation connection contract.
