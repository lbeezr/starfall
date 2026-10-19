# Five playable landing places

**Status:** Integrated; development checks verified · **Owner:** current implementer · **Updated:** October 18, 2026

Integrate all five approved settings with a remembered Location choice in the Sky menu. Start at Observatory for existing and fresh installs; switching scenery preserves the current round. Each place has two independently tappable props and bounded ambient movement. One shared geometry owns the playable rim, cell rendering, native targets and prop registration.

## Acceptance before implementation

- All five places are available in Debug and Release; the menu identifies and remembers the choice across relaunch. Invalid stored values safely use Observatory. Changing location cannot restart or advance the round, consume gameplay RNG or change a game save contract.
- Each place has two distinct layered props: telescope/lantern, harp/dew catcher, kiln/kettle, shell fountain/pearl, orrery/sandglass. Native buttons give visible normal/quiet responses. Repeated taps replace responses; settings, location changes, replay and background cancel stale work. No prop intercepts a cell.
- A visible continuous playable rim uses the same projected boundary as native cells and SpriteKit. Empty/sparse/dense captures, grown/Dusk contrast, corners, near/far rows and real resized taps verify alignment. Stars retain aspect and full targets. No square cell backgrounds.
- Normal motion, rapid input, clear/growth, win/loss, replay, background/resume, settings dismissal, system Reduce Motion and largest text remain usable. Full actual VoiceOver is deferred to RC per the development cadence.
- Core, affected hosted/UI checks, Debug/Release simulator builds, bundled image/alpha checks, source membership and hygiene pass. Physical-device frame pacing/memory and human preference remain separate, unverified until actually checked.

## Delivery and assets

Clean backdrop plates and transparent two-prop atlases are generated with the built-in image tool from the [approved concepts](../landing-places-01/README.md). Exact prompts and generation source paths are recorded in `prompts.json`. Runtime copies belong in `App/Assets.xcassets`; image assets inherit App’s packaged-container documentation boundary. Atlases hold two separated alpha objects, registered independently without per-frame decoding.

The revised plates retain their authored floor materials. A shared, slightly inset playable footprint reserves space for grown stars, with a quiet inlaid perimeter drawn from the cell union. Host preview inspection rejected flat opaque and stretched-texture panel treatments; they are absent from the final code. Inspect native captures before accepting that treatment. Switching locations is explicit rather than random so the player can explore and keep a favorite; it adds no campaign or unlock system.

## Responsive companion plates

Each location now has a quiet `Wallpaper` image that fills spare screen area independently of the playable stage. The stage feathers into it in low-detail edge bands; no repeating landmark or gameplay floor is tiled. `wallpapers.json` records the built-in image generation sources. Compact landscape uses a companion `Terrace` material plate and moves native communication beside the measured stage; `terraces.json` records its edit prompts and sources. Some generated material plates have rectangular pixel dimensions; only the floor texture adapts to the square stage. Stars and props retain their own aspect ratio. These assets add no UI text, controls or floor grid.

The early thicker-rim terrace variants were rejected because their front wall intruded into the required floor. Final variants move that edge to the bottom 3%; the shared arena lies within normalized y=.06… .94. Framing alternatives remain a separate user design exploration.

## Verification and source correction

The initial implementation started at `f35eba8`, 121 commits behind main. The user recognized removed circles in a native capture. Those results describe an obsolete game baseline and do not accept this integration. The work was first reconciled onto `ac6aeb3`, then updated through `7ddc837`, preserving current rendering, gestures, recipes, dialogue, screen flow, open-spark feedback and v7 saves. Core source is unchanged from that main revision.

Final development checks pass: 149 core tests, 230 hosted methods, Debug/Release builds, all five native locations and ten props on phone/iPad, compact phone landscape, both iPad landscape directions, largest-text header/quiet play, actual system Reduce Motion, interruptions/restart and current win/full/replay/swap cases. Phone and tablet captures were inspected. [Source-bound results and limits](../../../evidence/landing-places-2026-10-18/README.md) retain preliminary failures and corrected fixtures separately. Actual VoiceOver remains deferred to RC; device performance/feel and human art approval remain separate. Decorative frame alternatives are still design exploration.

## Physical UI architecture

The October 18 follow-up merges origin/main `33ae6fb`, retaining its newer typed copy and gesture-only input. Five `Architecture` assets replace floating gameplay surfaces with a connected empty upper groove, floor and lower hollow; native content is registered into those spaces. Wide layouts extend the floor into the message wing; accessibility text uses a growing scrolling apron. Earlier `Terrace` and backdrop records above remain source-bound production history. [Exact new prompts and output sources](architecture.json), [template contract](../BOARD_TEMPLATE.md), and [current native verification](../../../evidence/environment-grooves-2026-10-18/README.md).

The final reconciliation includes origin/main `1ed6290` and its forgiving input. Native inspection corrected landscape floor coverage and Archive’s action/bevel registration; empty viewport input now returns no cells. Final development checks: 152 Core tests, 239 hosted methods, Debug/Release simulator builds, current gap/off-center/swap native input, all five locations and props, phone/tablet rotation, largest text, actual system Reduce Motion and First Light flow. Captures retain their actual tested snapshots; [results and limits](../../../evidence/environment-grooves-2026-10-18/README.md).
