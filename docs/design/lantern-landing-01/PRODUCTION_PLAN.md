# Ship Lantern Landing in First Light

**Status:** Implemented; development checks passed; publication and delivery pending · **Owner:** Codex · **Updated:** 2026-10-19

The approved overhead Lantern Landing board is implemented in the normal app's optional First Light challenge. Every committed clear restores the location; reaching the existing 18-starlight goal opens its lantern and completes the level. The user authorized implementation and phone delivery on October 19, then explicitly chose bespoke, consistent scenes for phone portrait, iPad portrait and iPad landscape. Wider views reveal other docks in the same zone. The user rejected the middle fade/cut line in the first native pass: the replacement renders continuous whole artwork.

**Next action:** Publish and merge the verified work to `lbeezr/starfall`, then deliver current main through `scripts/device-update.py` and record its installation receipt. The user explicitly authorized these steps; publication, merge and physical delivery remain pending. [Acceptance evidence](../../evidence/lantern-landing-2026-10-19/README.md) records source `8fb2e78`, runtime `dev.5afe4a3c23`, 177 passing Core tests and a passing Release simulator build.

<img src="../../evidence/lantern-landing-2026-10-19/dev-caa0c5f__lantern-100__iphone-17e__default-text.png" width="230" alt="Native Lantern Landing restored on iPhone, with the opened lantern above the final stars and readable result actions">

**Native static reference:** `caa0c5f`, runtime `dev.4239835f1c`, iPhone 17e / iOS 27.0 Simulator, default text. The artwork is unchanged in the later verified source; this still does not establish the subsequent motion and accessibility fixes. See the linked acceptance record for those checks.

## Scope and success

Includes one First Light location, the existing cast and seven-column board, three viewport compositions with five restoration states each, and the existing entry/replay/result flow. Survival remains the default. No campaign, unlocks, new rules, save schema, SDKs or monetization.

- [x] First Light still uses seed 42, steady showers, no dark stars and the fixed 18-light goal; final-clear overshoot remains truthful.
- [x] Scores 0/5/9/14/18 reach the five scene milestones. Restoring a save reproduces progress; replay returns to darkness.
- [x] Phone portrait, iPad portrait and iPad landscape each use a bespoke composition of the same Lantern Landing. All retain the same lantern, materials, light language and restoration beats; wider views reveal connected docks rather than stretching the phone scene.
- [x] Each state renders as one continuous image across the viewport. There is no center replacement, clearing patch, feather mask, independently positioned source region or visible middle cut line. Restoration may crossfade whole images; it may not blend spatial regions into a replacement sky.
- [x] Whole-image scaling preserves proportions. Any crop is at the viewport edge and leaves the identifying lantern and useful dock connections legible. Rotation selects the matching composition at the same committed progress without restarting the level or replaying an earned milestone.
- [x] The authored scenery frames actual stars in the sampled 21-star native boards. Native cells and HUD retain their mapping across ordinary/largest text, tablet rotations and compact-phone landscape. All fifteen native scene states were inspected without a visible artwork seam.
- [ ] Full-capacity native scenery clearance: the browser checks 49 stars, but the native visual sample is sparse. Inspect a full native board before claiming this broader coverage.
- [x] Normal motion shows restoration and lantern opening. Calm effects, Reduce Motion, backgrounding and settings settle to the same committed scene without stale work or blocked controls.
- [x] Entry previews do not replace an existing saved round before Begin. Win/loss, restart, rapid input and settings dismissal remain usable.
- [x] Core and hosted/native checks, Debug and Release builds, hygiene and visual/animation review are recorded against tested source.
- [ ] Current main is integrated and the canonical updater verifies installation of the corresponding development build on the original phone app.

## Work in small batches

| Step | Deliverable | Owner | Done when |
| --- | --- | --- | --- |
| 1 | Derived restoration and presentation context | Core/context agents | Boundary, replay, save and pending-entry tests pass |
| 2 | Three consistent whole-artwork compositions, each with five restoration states | Art owner | Source/provenance recorded; each composition reviewed with actual board/HUD geometry |
| 3 | Whole-image renderer, viewport selection and HUD | Native renderer owner | No spatial seams; proportion, rotation, layout and normal/quiet transitions verified |
| 4 | Integration and device delivery | Root | Development evidence retained; publication/merge and verified updater receipt still pending |

## Composition continuity

The accepted phone image establishes a brass mast and petal lantern at the upper left, a rosewood dock with amber star fittings, a rope gangway continuing toward the upper right, a near wooden rail, violet clouds and uninterrupted navy sky. These are shared identity anchors, not three unrelated level themes.

| View | Authored composition direction |
| --- | --- |
| Phone portrait | Preserve the approved overhead relationship: main lantern dock above the open field, connected route receding behind it, near rail below. |
| iPad portrait | Pull back within the same zone to reveal a neighboring mooring and more of the connected gangway. Keep architecture outside the actual portrait board and the lantern readable around the header; its lateral margins are narrower than the landscape view's. |
| iPad landscape | Reveal connected docks on either side of the open sky, keeping the familiar lantern identifiable toward an outer upper margin. Let ropes, planks and clouds connect the view continuously across its width. |

The tablet descriptions are implemented and checked in native captures. Within each composition, restoration changes the condition and light of the place while the camera and principal outlines remain stable. The quiet play area must be authored into the image, not made by erasing or masking its center. Native stars, controls, text and grid guides are never baked into the artwork.

## Risk and verification

Native review covers all five states in three compositions, real tablet clears in both orientations, a compact iPhone SE (3rd generation) landscape win and the corrected largest-text header. A normal-motion 14→18 recording shows the finishing packets reaching the lantern before the ceremony handoff. The full 49-star native artwork view remains unverified. One main-dock star fitting in each tablet composition is lit at 25%, dark at 50% and lit again at 75%; the overall restoration remains clear, but individual fittings are not strictly cumulative. Preserve this limitation when evaluating further art polish.

Restoration is computed from committed Core score; decoration never changes rules, persistence, input or scheduling. Finite animation is local presentation state and interruption settles it immediately. Existing generation guards and presentation ownership remain in force.

Historical concept baseline: `548660b1f78e9d34775eb0ee601e91f146a898ac`. The [native acceptance record](../../evidence/lantern-landing-2026-10-19/README.md) owns tested sources, captures, lifecycle/motion checks and delivery status; [production-assets.json](production-assets.json) owns artwork hashes. Actual VoiceOver acceptance remains deferred to RC under the development-build cadence. Physical-device play is unverified, and an eventual installation receipt will not establish gameplay or VoiceOver acceptance.
