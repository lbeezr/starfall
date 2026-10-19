# Ship Lantern Landing in First Light

**Status:** Accepted direction; viewport artwork and renderer revision underway · **Owner:** Codex · **Updated:** 2026-10-19

Bring the approved overhead Lantern Landing board into the normal app's optional First Light challenge. Every committed clear restores the location; reaching the existing 18-starlight goal opens its lantern and completes the level. The user authorized implementation and phone delivery on October 19, then explicitly chose bespoke, consistent scenes for phone portrait, iPad portrait and iPad landscape. Wider views reveal other docks in the same zone. The user rejected the middle fade/cut line in the first native pass: the replacement must render continuous whole artwork.

**Next action:** Author the two tablet compositions and their restoration states, replace split-region rendering, and verify each viewport on Apple tooling. New artwork, revised native rendering and delivery are not yet accepted as complete. Integrate verified work in small batches, then deliver current main through `scripts/device-update.py`.

<img src="background-100-v2.png" width="230" alt="Restored Lantern Landing, with the dock above a dark open sky playfield and a near wooden rail below">

*Approved phone composition, not native implementation evidence. Its mast, lantern, connected dock and continuous sky establish the identity shared by the two forthcoming tablet compositions.*

## Scope and success

Includes one First Light location, the existing cast and seven-column board, three viewport compositions with five restoration states each, and the existing entry/replay/result flow. Survival remains the default. No campaign, unlocks, new rules, save schema, SDKs or monetization.

- [ ] First Light still uses seed 42, steady showers, no dark stars and the fixed 18-light goal; final-clear overshoot remains truthful.
- [ ] Scores 0/5/9/14/18 reach the five scene milestones. Restoring a save reproduces progress; replay returns to darkness.
- [ ] Phone portrait, iPad portrait and iPad landscape each use a bespoke composition of the same Lantern Landing. All retain the same lantern, materials, light language and restoration beats; wider views reveal connected docks rather than stretching the phone scene.
- [ ] Each state renders as one continuous image across the viewport. There is no center replacement, clearing patch, feather mask, independently positioned source region or visible middle cut line. Restoration may crossfade whole images; it may not blend spatial regions into a replacement sky.
- [ ] Whole-image scaling preserves proportions. Any crop is at the viewport edge and leaves the identifying lantern and useful dock connections legible. Rotation selects the matching composition at the same committed progress without restarting the level or replaying an earned milestone.
- [ ] The authored scenery frames actual stars; sparse and dense boards remain readable. The playable field, native hit cells and HUD retain their shared mapping. Check ordinary and largest text, safe areas, tablet rotations and resized layouts without hiding an artwork seam beneath controls.
- [ ] Normal motion shows restoration and lantern opening. Calm effects, Reduce Motion, backgrounding and settings settle to the same committed scene without stale work or blocked controls.
- [ ] Entry previews do not replace an existing saved round before Begin. Win/loss, restart, rapid input and settings dismissal remain usable.
- [ ] Core and hosted/native checks, Debug and Release builds, hygiene and visual/animation review are recorded against tested source.
- [ ] Current main is integrated and the canonical updater verifies installation of the corresponding development build on the original phone app.

## Work in small batches

| Step | Deliverable | Owner | Done when |
| --- | --- | --- | --- |
| 1 | Derived restoration and presentation context | Core/context agents | Boundary, replay, save and pending-entry tests pass |
| 2 | Three consistent whole-artwork compositions, each with five restoration states | Art owner | Source/provenance recorded; each composition reviewed with actual board/HUD geometry |
| 3 | Whole-image renderer, viewport selection and HUD | Native renderer owner | No spatial seams; proportion, rotation, layout and normal/quiet transitions verified |
| 4 | Acceptance, integration and device delivery | Root | Evidence retained, main merged, verified updater receipt |

## Composition continuity

The accepted phone image establishes a brass mast and petal lantern at the upper left, a rosewood dock with amber star fittings, a rope gangway continuing toward the upper right, a near wooden rail, violet clouds and uninterrupted navy sky. These are shared identity anchors, not three unrelated level themes.

| View | Authored composition direction |
| --- | --- |
| Phone portrait | Preserve the approved overhead relationship: main lantern dock above the open field, connected route receding behind it, near rail below. |
| iPad portrait | Pull back within the same zone to reveal a neighboring mooring and more of the connected gangway. Keep architecture outside the actual portrait board and header; its lateral margins are narrower than the landscape view's. |
| iPad landscape | Reveal connected docks on either side of the open sky, keeping the familiar lantern identifiable toward an outer upper margin. Let ropes, planks and clouds connect the view continuously across its width. |

The tablet descriptions guide authoring; they do not claim the generated assets have passed review. Within each composition, restoration changes the condition and light of the place while the camera and principal outlines remain stable. The quiet play area must be authored into the image, not made by erasing or masking its center. Native stars, controls, text and grid guides are never baked into the artwork.

## Risk and verification

The main uncertainty is composing continuous artwork around existing native controls across three aspect ratios. The rejected split-region pass is not an acceptable fallback. Resolve clearance in the authored composition and native HUD arrangement, while keeping the board coordinate owner unchanged. Inspect real native screenshots with empty, partial and dense boards; examine normal-motion state transitions for visible jumps in the dock or lantern. Earlier checks of the split-region renderer do not establish acceptance of its replacement.

Restoration is computed from committed Core score; decoration never changes rules, persistence, input or scheduling. Finite animation is local presentation state and interruption settles it immediately. Existing generation guards and presentation ownership remain in force.

Historical concept baseline: `548660b1f78e9d34775eb0ee601e91f146a898ac`. Record the revised renderer's actual tested source, dirty paths, asset hashes, configuration and simulator in `docs/evidence/lantern-landing-2026-10-19/README.md` when the evidence is ready. Lifecycle, normal-motion and viewport acceptance for this revision remain pending. Actual VoiceOver acceptance is deferred to an RC under the development-build cadence; this delivery requires lightweight accessibility checks. Physical installation verification does not claim physical-device gameplay or VoiceOver testing.
