# Observatory interface direction

2026-10-17 · Active production refinement. Observatory first; Cloudsea deferred.

## Intent and acceptance

The interface belongs to a little celestial observatory: astronomical instruments, warm brass, ink-blue glass, drawn constellations and familiar star faces. The painted terrace and actual cast remain dominant. Detail comes from consistent craft, materials, hierarchy and behavior rather than adding more containers.

Acceptance: no hard artwork seam at the iPhone's top/bottom; registered art retains its aspect ratio; real native taps still agree with the renderer; one 44-point menu control; no nested padded panels; a continuously readable shower cue without flashing; paused/onboarding/outcome guidance stays below the terrace and clear of the lantern. Ordinary active play remains quiet. Menu hides underlying controls, freezes deadlines, preserves pause choice and supports Done/swipe dismissal. Largest text reflows/scrolls with no font shrinking. Sound/haptics default on only when no preference exists; explicit saved off remains off. No rule, save schema, RNG, progression or shower-generation changes.

## Visual grammar

| Layer | Material / voice | Responsibility |
| --- | --- | --- |
| World | Painted clouds, ink cosmos, lavender stone | Full screen, behind all chrome; never clipped to safe areas |
| Instruments | Restrained ink-blue translucent medallions, fine cool edge | Score and menu; contrast remains sufficient over changing art |
| Time | Fine comet trail, pearl head, pale cyan tail | Time toward the existing automatic shower; no promise of specific colors or landing locations |
| Guide | Deep ink card, warm brass hairline, actual Sunny portrait | Welcome, pause, important rule help and outcomes |
| Reading | Native navigation, grouped rows, short dedicated pages | Preferences, balance and instructions; no wall of rules in the main menu |

The board stays an opaque painted stone landing place. Glass is appropriate for floating instruments/menus, not for making stars look suspended above an unrelated transparent rectangle. A future iOS 26 Liquid Glass variant can use the same roles with iOS 17 fallback; the current authored ink material is deliberate. Do not add refraction, blur or bright borders to every surface.

## Primitive inventory

Implementation owners: `StarfallTheme` for roles, `FallingSkyHUD` for gameplay components, `FallingSkyMenu` for settings composition, `ObservatoryGeometry` for artwork/input registration, `StarCast` for all portrait/star imagery.

| Primitive | Variants and behavior |
| --- | --- |
| Ink containment (guide/reading surfaces) | The selected HUD removes counter/button capsules; deep ink containment remains for guidance and reading |
| Icon control | 24-point drawn constellation inside minimum 44-point native button; pressed surface; disabled text role; spoken action and hint |
| Starlight counter | Warm sparkle + rounded semibold monospaced score; challenge uses current/target; no decorative label shouting over the sky |
| Comet trail (`SkyShowerTrail`) | Flowing / arriving / paused; one authoritative deadline supplied by store; cool tail and small pearl; explicit spoken state without a routine visible caption; no pulse or flicker |
| Guide card (`SkyGuideCard`) | Welcome / paused / outcome; Sunny portrait reused from bounded cast cache; serif heading and natural wrapping supporting copy; actions below |
| Menu row | Icon plus clear word; native disclosure/toggle/button semantics; 44-point minimum native targets; no icon-only preference rows |
| Reading page | Separate How to Play and Sky Balance; logical sections, short paragraphs, unlimited Dynamic Type |

SVG is not required: custom SwiftUI vector paths remain crisp at every scale and can use the theme's material roles. Reuse native symbols for familiar actions (pause, sound, replay, help); author distinctive game symbols only when their meaning benefits. Cast portraits must come from StarCast rather than a separately drawn mascot that drifts from the board.

## Type and layout

Use a rounded headline for numeric score, serif headline for the guide's voice, subheadline for guide copy, rounded caption for the trail's state, and native body text for settings. These are Dynamic Type styles, not fixed tiny labels. Essential reading never uses scale-to-fit or truncation. Full text sizes and existing contrast roles live in StarfallTheme.

A normal phone uses one transparent instrument row (counter left, narrow comet trail center, constellation menu right), terrace at its existing projected coordinates and contextual guide near the bottom safe edge. The artwork ignores safe areas; interactive chrome respects them. On iPad the world extends sideways, while board/props remain registered to the center painting. The current character-chat surface uses a dedicated conversation portrait and a compact bubble; accessibility text sizes move the chat below the terrace. Inspect compact-phone placement against the nearest star row. A right-side clearance protects the lantern from the normal guide card. Largest text uses the existing scrollable canvas, stacks actions and omits only the decorative portrait. It must retain access to both scenery props.

The art registration fills the viewport vertically. On tall phones it crops a few horizontal pixels instead of revealing letterbox strips. All rendered stars, native cell polygons and props consume the same mapping. Changing this requires native corner and prop tests, not just screenshots.

## Message policy and voice

The [shared character chat](CHARACTER_CHAT_AND_TRAIL.md) presents store-owned committed guidance while paused: opening rules, corrective help, growth, clears, dark-star outcomes and First Light. Active play shows brief useful information and keeps ordinary automatic arrivals quiet. One current message or player-paced script can be dismissed and reopened. Stable speaker IDs select a dedicated portrait and name; [local JSON scripts and the Debug studio](../../App/DialogueScripts/README.md) let future scenarios use this surface. Welcome/entry/endings use the same bubble for explanations. Gameplay HUD/guide views leave the hierarchy under settings; one explicit accessibility representation attributes name and message together. Terminal outcomes retain the committed result and restart choices; transient text is not saved. The store requests VoiceOver feedback for explicit inputs and terminal outcomes; automatic nonterminal showers remain quiet so exploration speech stays readable. The terrace group stays unlabelled, stars own their spoken identity, and the score hint carries terrace context. [Gameplay evidence](../evidence/voiceover-gameplay-2026-10-17/README.md) records the scoped native checks. [Production guide evidence](../evidence/paused-guide-adoption-2026-10-17/README.md) records adoption. [Accessible layout evidence](../evidence/accessible-terrace-layout-2026-10-17/README.md) places the guide below the terrace at accessibility sizes, preserving native scrolling and full text; ordinary sizes keep the original composition.

During flowing play, the comet trail supplies anticipation without an always-open dialogue box. A future contextual arrival/dark-star guide should be event-driven, bounded, dismissible and retained long enough to read; it must never interrupt a clear or pause the rules. Do not start a new dialogue engine, repeat copy every four seconds, or introduce tutorial progression in this pass.

## References and decisions

[Apple's game-interface guidance](https://developer.apple.com/videos/play/wwdc2024/10085/) supports adapting controls to touch, safe areas and the actual available space. [Hearthstone's mobile announcement](https://hearthstone.blizzard.com/en-gb/news/18648149) explicitly describes a mobile-specific interface. Our interpretation: preserve the mood of a physical board while composing controls specifically for a small phone. These references inform composition, not an attempt to copy another game's art.

## Roadmap and decision point

1. Implement the Observatory component family and capture normal/maximum-text iPhone and iPad states. Check real board taps after full-bleed registration changes, guide/lantern separation, settings navigation and interruption.
2. Compare the new physical iPhone build with the user's current build. Judge edge coverage, icon recognition, trail meaning, reading comfort and whether the companion adds warmth without noise. Tune this family before producing more environments.
3. Extend the verified roles into outcomes and other supported screens. Add a genuinely useful custom icon only after the meaning is established. Keep historical puzzle documentation separate from the falling-sky layout.
4. Cloudsea may reuse the verified contracts with its own accent/material/companion context after Observatory acceptance. No environment picker, unlocks or new progression.

Implementation, build, interaction, actual VoiceOver, visual and physical acceptance are separate evidence categories. See the source-bound adoption evidence; a passing build alone does not accept this design.

## Quiet HUD comparison — user feedback, October 17

The user rejected the noisy top fifth of the screen. A second row of routine status copy is excessive even when the buttons are smaller. Compare these options before adding more decoration:

| Option | Always visible | Tradeoff |
| --- | --- | --- |
| A · transparent single row (recommended) | Small score left, fine unlabeled comet trail center, menu right | Preserves useful timing/score with one 44-point control row |
| B · almost invisible | Only a menu control; score when paused | Maximum scenery, but less immediate reward/goal feedback |
| C · floating corners | Score/menu corners; arrival cue in the world | More immersive, but the original ambiguous/flickering cue demonstrates discoverability risk |

Reference inspection: Monument Valley's first developer App Store screenshot has a small circular corner control and almost entirely open scenery. Candy Crush's second/third developer screenshots group goals, moves and progress into a shallow top strip. The first three Royal Match screenshots are promotional rescue compositions, not evidence for its actual live menu. Alto's official press screenshots show a world-first composition but omit HUD, so do not infer live controls from them. Sources: [Monument Valley](https://apps.apple.com/us/app/monument-valley/id728293409), [Candy Crush](https://apps.apple.com/us/app/candy-crush-saga/id553834731), [Royal Match](https://apps.apple.com/us/app/royal-match/id1482155847), [Alto press kit](https://www.builtbysnowman.com/press/sheet.php?p=altos_adventure). Raw reference downloads and URLs remain under ignored artifacts, not shipped assets.

A single-row refinement can remove the routine label and capsule boxes, hide the system status bar while playing, and retain safe-area placement for actual controls. Do not place buttons behind the camera/Dynamic Island to gain height. Accessibility names and 44-point targets remain even when the visible glyph is smaller. The accessibility-size layout may use additional space as needed; compactness must not depend on shrinking reading text.

The user requested visual mocks of all three options, then selected A because it supports the star-trail progress bar. A three-column generated comparison was delivered inline, based on the native populated Observatory capture; it is a design mock, not device acceptance. A is the selected design direction: one transparent row, small score, fine comet trail and constellation menu. B and C are closed comparisons, with no runtime flags or alternate layouts retained. Native/physical acceptance of the implementation is recorded separately; selection of a mock does not establish device approval.

[Selected HUD comparison sheet](interface/hud-options-2026-10-17.jpg): A selected by the user. Generated design comparison based on a native capture; star art and scene were supplied as references. This is not a screenshot of the final running HUD.

## Star-trail refinement · device feedback

The user found A's initial trail too plain and difficult to see on iPhone. Bounded pass: retain the single row and existing deadline, enlarge its visual footprint slightly, use the actual Spark cast material as the head, layered cool/warm light with a dark contrast halo, and at most eight deterministic dust glints. No emitter nodes, texture production, external assets, rule changes or new timer ownership. Quiet modes retain a readable static head/tail with no decorative particle movement. Menu/background/terminal state must hide/freeze it; no persistent particle/task accumulation. Acceptance: native active screenshot and normal-motion capture show a clear head and luminous tail over the nebula; native approaching status/pause/settings behavior remains; core tests, Debug/Release build and focused native checks pass. Device preference remains separate from simulator checks.

Guide typography distinguishes secondary character names from primary outcomes. [The name-heading polish](../evidence/guide-typography-2026-10-17/README.md) bounds Sunny at the first accessibility size while preserving full-size instructions, actions and outcome titles. The bound is local to the title, not the card or playfield.

[Character chat delivery evidence](../evidence/character-chat-2026-10-17/README.md) supersedes the paused-only presentation: shared bottom bubble, six portraits, local scripts, explicit single-message accessibility representation and no HUD behind settings. Earlier captures above remain source-bound.
