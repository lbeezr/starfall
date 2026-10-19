# Level art brief

Copy this brief into the location's production folder and replace the prompts below. Keep the completed brief concise; link the [design kit](../level-design-kit/README.md), source art and evidence rather than duplicating their rules. These links assume a sibling folder under `docs/design/`; adjust them if the brief lives elsewhere. An accepted brief is art direction, not native acceptance.

**Location / atlas number:**
**Status / date / owner:**
**Scope and next action:** Name the requested location, deliverables and current uncertainty. State any rule or runtime change explicitly; artwork alone does not introduce one.

## What this place is for

In two or three sentences, describe what the stars do here, what Murk's passage interrupted, and the useful or beautiful thing restored at completion. Name the final visible change. Make it recognizable in a still image without a caption or new character animation.

## Build the whole place

| Decision | Describe the specific choice |
| --- | --- |
| Main silhouette and mechanism | The dominant structure and the physical change that makes the location distinct |
| Supporting clusters | A few purposeful structures, tools, plants or resting places, with clear support and contact |
| Connections and depth | How paths, terrain or channels join the clusters; what continues beyond the crop; the close foreground feature |
| Materials | Shape, thickness, edges, joints and local light, as well as color |
| Camera and scale | Apply [camera construction](../level-design-kit/CAMERA.md), noting any accepted existing-family deviation; useful top/side faces; main structure and finish cue compared with actual small/grown star width in [scale-reference.svg](../level-design-kit/scale-reference.svg) |
| Readable play surface | How continuous sky/water/material stays quiet behind stars without a cleared rectangle or middle mask |
| Reference roles | Primary Starfall composition references, atlas identity and any attributed research; identify each input's purpose |

Aim for Lantern Landing / Ribbon Crossing's substantial connected places. A lone miniature object with more empty sky does not satisfy that direction. Detail should explain the place rather than become uniform decoration.

## Fit the three native compositions

Use [phone](../level-design-kit/phone.svg), [tablet portrait](../level-design-kit/ipad-portrait.svg), [tablet landscape](../level-design-kit/ipad-landscape.svg) and [native-layouts.json](../level-design-kit/native-layouts.json) for their stated configurations. Teal suggests scenic opportunity; red prioritizes star contrast; violet protects native text/actions and story visibility; hatching marks crop/insets. Amber's **0.15-cell** soft-bleed budget is preliminary and must pass native inspection.

| Format | Main scene / supporting clusters | Fixed light recipient and finish cue | Crop, UI and scale risks to verify |
| --- | --- | --- | --- |
| Phone | | | |
| iPad portrait | | | |
| iPad landscape | | | |

Record actual generated pixel dimensions for every selected painting. Identify the source coordinate system for any focal/light bounds. Plan for compact and largest-text scrolling as well as default layouts; native canvas and crop can change. Preserve the star/hit mapping and character aspect ratio. Solve conflicts with authored terrain placement, perspective and local lighting, without globally shrinking the world or stars.

## Restoration is cumulative

Keep architecture, camera and background registered within each format. Describe concrete additions and retained details; avoid making all five states the same scene with different brightness.

| Painting | Existing 18-light threshold | Visible state and retained progress |
| --- | --- | --- |
| 0% | 0 | What remains recognizable while drained, broken or dormant? |
| 25% | 5 | First small but readable return of function |
| 50% | 9 | New connection or larger recovery, retaining 25% |
| 75% | 14 | Nearly working; one clearly visible unresolved condition |
| 100% | 18 | Specific final resolution, retaining the earlier restoration |

Name what differentiates 75% from 100% beyond color, where it survives the HUD/result view, and what a restored/relaunched game should show. Any requested motion needs its own bounded behavior and interruption evidence; a still cannot establish animation. Future travel clips are separate from these paintings.

## Delivery and acceptance record

- **Selected artwork:** Five whole paintings per format; record asset names, source paths, prompts, reference roles, rejected attempts, dimensions and SHA-256. Keep packaged bytes faithful to the selected outputs.
- **Master review:** Record approval of the connected-place composition and native fit before deriving the full state set. Do not strip away accepted richness to satisfy a speculative rectangle.
- **Native appearance and input:** Name source/build, device, orientation, text size, sparse/dense fixture, real tap, each restoration state and terminal UI inspected. Include compact/scrolling and representative rotation checks.
- **Motion and interruption:** Record ordinary falling/crossfade behavior separately from Reduce Motion, settings, background/restore and replay checks. Existing outcomes must remain independent of decorative animation.
- **Limits and next action:** State failed checks and unverified physical contrast, comfort or actual VoiceOver. Link the source-bound evidence and any concrete follow-up; do not treat an art preview or passing build as gameplay acceptance.
