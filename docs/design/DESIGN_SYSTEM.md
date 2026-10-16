# Starfall design system

Accountable owner: presentation/design-system lane (`experience`). Updated 2026-10-16. The implementation is in `App/StarfallTheme.swift`; menu, gameplay, Settings, HUD and atmosphere consume it. This is a small native SwiftUI system for the existing puzzle, not a new feature platform.

## Ownership and change rules

- **Design system:** owns semantic color roles, type hierarchy, spacing, radii, layout constraints, action states, passive panels, status text, title treatment and progress presentation. Change these centrally and inspect every consumer.
- **Screen composition:** `StarfallApp.swift` arranges the menu, navigation, board, status, results and Settings. It supplies actions and accessibility identifiers. It does not invent another palette or button hierarchy.
- **HUD:** `StarlightHUD` consumes the same system. It reads the committed score and moves, formats the existing labels, and gives a fraction to `StarfallProgressStyle`. It owns no score, timing, outcome, local palette or independent design authority.
- **Renderer:** SpriteKit owns jewel material construction, atlas frames, shading, artwork geometry, hit mapping and bounded visual effects. The approved five-color/five-silhouette contract remains in the game bible and material factory. Do not duplicate jewel drawing in SwiftUI or migrate one-off facet/shading constants into the interface theme.
- **Rules, saving and feedback:** remain in their existing core/store/feedback boundaries. Presentation components receive values; they do not award starlight, spend moves, save state, generate groups or start celebrations that block play.

Future HUD, menu, result and Settings changes use existing semantic roles and primitives first. Add a new shared token only for demonstrated reuse or a specific cross-component contract. Keep one-off illustration geometry inside its owning component. There is no theme registry, runtime theming framework or dependency added by this system.

## Visual hierarchy

The board is the dominant object. Midnight/plum atmosphere sits behind opaque, quiet panels; near-white text and pale-cyan actions remain readable above it. Serif titles provide the storybook character. Native system text carries instructions, statistics and controls. There is one prominent action at a time: Play/Continue on the menu, or New game after an outcome. New game during play is secondary; navigation is quiet.

Panels have a common continuous corner, inset and restrained edge. They contain related information rather than decorating every line. The board keeps its own larger corner and no additional luminous border. The small constellation is the same progress fraction as the rail, not another goal, milestone or currency.

## Color roles

The underlying palette is private. Consumers use `StarfallTheme.Colors` according to purpose, even when two roles currently share a value.

| Role | Value | Contract |
| --- | --- | --- |
| `skyTop` / `skyBottom` | `#090E2B` / `#2E1A4A` | Static dark atmosphere; Settings uses the solid top color |
| `surface` / `surfacePressed` | `#1D2140` / `#303652` | Opaque containment and pressed secondary/quiet actions |
| `textPrimary` | `#F4F1FF` | Titles, statistics and essential information |
| `textSecondary` | `#C5C7DD` | Supporting copy and ordinary status |
| `textDisabled` | `#A4ADC7` | Disabled action labels; never whole-control fading |
| `actionPrimary` / `actionPrimaryPressed` | `#B0EDFF` / `#90D3E9` | Primary fill, quiet/secondary action text, immediate pressed emphasis |
| `onActionPrimary` | `#090E2B` | Dark label on a bright primary action |
| `actionDisabled` | `#303652` | Solid disabled primary/secondary surface |
| `outline` / `progressTrack` | `#66779B` | Panel/control edge and unfilled progress |
| `focus` / `progressFill` / `positiveStatus` | `#B0EDFF` | Separate roles for focus, the existing score fraction and a completed sky |
| `ambientStar` / `ambientGlow` | `#F4F1FF` / pale cyan at 7% | Noninteractive, nonsemantic decoration only |

Solid-token sRGB contrast calculations give primary text/surface **14.04:1**, secondary text/surface **9.37:1**, disabled text/disabled surface **5.28:1**, and primary-action label/pressed fill **11.43:1**. The rail track/surface is **3.48:1**, and fill/track is **3.51:1**. These are supporting color calculations, not a claim that a rendered screen or native accessibility audit has passed.

Outcomes always have explicit words and score details. A loss does not depend on a red tint, flashing warning or special color distinction. Jewel identity continues to use both shape and color.

## Type, rhythm and sizing

| Role | Implementation | Use |
| --- | --- | --- |
| Display | 52-point serif base, `ScaledMetric` relative to large title | Menu brand title |
| Title | Native `.title2`, medium serif | In-game title and outcome heading |
| Heading | Native `.headline` | Statistics, rule heading and saved-round heading |
| Body | Native `.body` | Instructions and Settings labels/information |
| Supporting | Native `.subheadline` | Menu subtitle and supplementary rules |
| Status | Native `.callout` | Settled messages, result detail and rotor help |
| Action | Native `.headline` | Shared action labels |

Reading text follows Dynamic Type without a cap, shrinking strategy or line limit. Settings statements size naturally within a vertical ScrollView; they have no forced ideal height or replacement accessibility label. The 48-point decorative brand mark and 24-point accessible-board glyphs represent shapes, not reading text; scaling the latter would merge neighboring silhouettes.

- Spacing scale: 2, 4, 8, 12, 16, 20 and 24 points. Use 20 for page/panel insets, 16 for game sections, 12 for related groups and 8 for tightly related lines. The 2-point board gap is a specific grid constraint.
- Continuous radii: 16 for controls, 20 for panels, 24 for the board.
- Stacked reading width: 480 points on the menu; 560 for gameplay and Settings. Larger text scrolls. The HUD stacks its statistics rather than squeezing the board or shrinking labels.
- Standard actions have a 52-point minimum height; quiet actions, toolbar Done, Toggle rows and progress exploration have a 44-point minimum. Labels may grow beyond those minima.
- The accessible board uses 6-point padding and 2-point gaps. At a 335-point board its cells are approximately 44.43 points wide. This is **not a universal 44-point guarantee** for narrower windows; layouts with boards below 332 points need separate inspection. Rotor navigation remains available without precise cell targeting.

Landscape gameplay uses two columns when the available safe-area window is at least 900 points wide and 500 points tall, wider than it is tall, and uses a non-accessibility text size. This follows the available window rather than a device name or physical orientation, so narrower multitasking windows keep the stacked flow. The shared layout tokens reserve a 300-point information column and cap the square board at 600 points, with the existing 24-point section gap and 20-point page insets. Board size also fits the available height below navigation; at the eligibility boundary it is at least 400 points. The board is on the left; the existing HUD, status, result and New game action are on the right. Navigation remains above both columns.

Both arrangements retain one vertical ScrollView. `AnyLayout` changes placement while the board retains its view identity and the same SpriteKit scene; only the stateless HUD changes column. The board marker, rendered scene and accessible cells share one square frame. Sidebar text keeps its natural height, and overflow remains scrollable rather than compressing controls or shrinking text. Portrait windows and accessibility text sizes keep the familiar HUD-before-board stack. No layout transition adds bespoke animation or changes the round.

## Primitive and component contracts

`StarfallButtonStyle` keeps native Button semantics and a full shaped hit region. It has three roles rather than separate per-screen button implementations:

| State | Primary | Secondary | Quiet |
| --- | --- | --- | --- |
| Ready | Cyan fill, dark label | Opaque surface, cyan label, outline | Clear surface, cyan label |
| Pressed | Solid darker cyan | Solid raised surface | Solid raised surface |
| Disabled | Solid disabled surface, muted label | Solid disabled surface, muted label | Clear surface, muted label |
| Focused | Shared 2-point accent outline | Shared 2-point accent outline | Shared 2-point accent outline |

The style does not disable native VoiceOver or keyboard focus effects, create extra focus stops, animate scale, or dim an entire control. Only primary menu/terminal actions expand to the content width. Native toolbar Done retains platform placement with shared type, tint and target sizing.

Settings opens directly in one large native sheet at every text size, with Done and native swipe dismissal. This gives controls and information a consistent reading surface without an expansion step; larger content still scrolls. It retains actual SwiftUI Toggles: a native switch at ordinary sizes and the native button-toggle style at accessibility sizes so the label has a full row. Their on/off or selected state and focus semantics come from the platform, with the shared action tint. Do not replace them with an unlabeled icon or manually synthesized state. The ScrollView contains independently measured text; it does not disguise body text as a single accessibility label or suppress clipping audits.

`starfallPanel` supplies passive inset, opaque fill and outline. Increase Contrast doubles the edge width. It never clips its content, intercepts taps, merges accessibility elements or supplies a reading label.

`StarfallStatusText` supplies shared supporting/positive type and color. The screen supplies truthful copy and identifiers. `StarfallTitle` supplies display/navigation title roles. `StarfallProgressStyle` clamps only its rendered fraction to 0–1, leaving the HUD's raw score truthful; its constellation is hidden from accessibility because the labeled progress element already exposes the value.

## Motion, accessibility and gameplay invariants

- Shared buttons, HUD, progress and sky add no bespoke motion. Button state and progress transactions suppress inherited implicit animation. Native control/focus behavior remains platform-managed.
- Calm effects and system Reduce Motion retain identical score, moves, actions and information. The renderer/store continue to own settled alternatives, interrupted-turn cleanup and the one-turn input lock. The design system must not add a second delay.
- Static atmosphere never receives input or accessibility focus. There are no blinking low-move warnings, shake, moving backdrop, modal celebration or timer pressure.
- While Settings is open, the underlying menu or game is hidden from accessibility navigation. Dismissal restores it. Apply this boundary to the underlying content, not to the root presenting the sheet.
- Existing `game.score`, `game.moves`, `game.progress`, `game.message`, outcome, navigation, Settings and restart identifiers/labels remain stable. The existing score accessibility phrase is preserved for compatibility.
- VoiceOver keeps all 49 cells and the Matching groups rotor, with shape/color names, position, group size and move cost. Rotor choices disappear while busy or terminal. The DEBUG structural fixture is not proof of actual spoken/focus behavior.
- The round remains 7×7, five jewel types, orthogonal groups of 3+, 70 cleared jewels in 18 valid moves. Groups of one or two spend no move. Recovery is free and bounded. A final-move win takes precedence. Presentation never changes those rules.
- No ads, purchases, tracking, progression, account/network features, external SDKs or paid assets are introduced.

## Validation boundary

The adaptive landscape revision passed four native UI cases on an iPad mini Simulator running iOS 27; automated large-text accessibility audits also passed. The actual initial and post-play landscape screenshots were opened and visually reviewed: the complete square board fits, the sidebar gives HUD, status and New game clear separation, and navigation remains legible above both columns without observed clipping or overlap. The composition matches the shared layout tokens and existing component hierarchy. Four compact iPhone SE (3rd generation) native UI cases also passed, and its full-screen portrait capture was visually reviewed. The Release simulator build passed. These results do not establish human VoiceOver speech/focus behavior, physical-device performance or interaction feel. The earlier results below describe the preceding presentation revision; record the new source-bound runs and captures in `docs/VALIDATION.md`.

Source review and solid-color calculations were completed for this migration. The follow-up native run (`/tmp/starfall-ci-followup-native.xcresult`) passed 37 tests: 35 hosted tests and the two UI tests `testRealBoardTapAndNavigation` and `testLargestTextSettingsDirectAuditAndDismissal`, with zero failures or skips. Settings passed `textClipped`, `sufficientElementDescription` and `hitRegion` audits in its initial large presentation at normal text size, without a sheet-expansion step, and at the footer-fully-visible reading position at maximum Dynamic Type. All three audit types remained unsuppressed. The tests also exercised sound-toggle changes and persistence, Done dismissal, and exclusion/restoration of underlying gameplay in the accessibility hierarchy.

The same follow-up validation passed 27 core tests and a Release simulator build. Menu and gameplay have separate scoped largest-text audit coverage; this focused follow-up does not revalidate every UI flow. Record the broader run and retained evidence in `docs/VALIDATION.md`.

The medium-height sheet is now retired from the supported product flow. Its captured `textClipped` report remains unresolved historical evidence despite visibly readable text; neither the presentation change nor an expanded-sheet pass diagnoses that report or proves it false. Removing the expansion step is a product simplification with one directly audited presentation, not an audit exclusion. Keep the original evidence under `docs/evidence/swarm-2026-10-16/known-settings-medium-issue.txt` and its screenshot. Revealing the full footer establishes one tested reading position, not coverage of every scroll position.

Actual VoiceOver rotor speech/focus, keyboard focus, minimum-phone layouts, Increase Contrast and device performance require their own evidence. The DEBUG accessible-board fixture establishes native control structure and input only. Record source-bound results and these limits in `docs/VALIDATION.md`; do not interpret a passing automated suite as full accessibility or release acceptance.
