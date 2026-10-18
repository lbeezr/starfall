# Keep screenshot references current

**Status:** Accepted · **Owner:** Current implementer · **Updated:** October 17, 2026

Start visual work from [the visual reference](design/VISUAL_REFERENCE.md), then check its source against the files being changed. A recent capture date does not establish current-build parity. Dated evidence records describe their tested source, not the current product.

## Choose references by purpose

| Category | Location and use | Retention |
| --- | --- | --- |
| Selected references | The small capture index in [the visual reference](design/VISUAL_REFERENCE.md#capture-index); start here for product appearance | Replace or mark **Needs refresh** whenever the depicted UI/art changes |
| Historical evidence | Dated `docs/evidence/` reports; consult for a specific bug, decision or comparison | Keep unique evidence while it explains a decision or unresolved risk; retire redundant frames in small batches |
| Disposable output | Ignored `artifacts/` or temporary storage; routine test attachments, recordings and intermediate exports | Remove after extracting useful evidence, before the next run reuses that output directory; retain an active investigation's output until summarized |

A capture index entry uses one of these statuses:

- **Current:** An inspected capture matches the relevant implementation files. Record the captured source, report and the revision against which parity was checked. Unrelated commits do not automatically invalidate it.
- **Needs refresh:** Parity is unverified or the depicted implementation changed. State the missing capture/check and keep this status until it is performed.
- **Historical:** Deliberately retained for its recorded source. Never use it to infer the current product's appearance.

Cover welcome, entry, active play, settings and outcomes in the index, including explicit gaps. The implementer changing a surface owns its entry: update it in the same change, even when a native capture cannot be made. A recent timestamp, successful build or renamed file cannot establish **Current** status. Index status is about appearance; animation, actual VoiceOver and physical-device acceptance remain separate.

## Name new captures for the build they depict

Use lowercase words, hyphens within a field and double underscores between fields:

```text
<source>__<screen-or-state>__<device>__<variant>.<png|jpg>
v0.3.0-b42__active-play__iphone-se3__default-text.png
dev-f35eba8__entry__iphone-17e__largest-text.png
dev-f35eba8-wip-a1b2c3d__settings__iphone-se3__reduce-motion.png
```

These are naming examples, not claims that those releases or captures exist.

- **Versioned build:** `v<marketing-version>-b<build-number>` uses the actual installed app's version and build, not a planned release. Record configuration and exact source in the linked report; a versioned filename does not imply release approval.
- **Development:** `dev-<commit>` uses an unambiguous Git abbreviation. If captured inputs differ from that commit, append `-wip-<snapshot-id>` and record the dirty paths and source hashes under that snapshot ID in the report. Do not label a modified build as a clean commit.
- **Screen/state:** Use concrete names such as `welcome`, `entry`, `active-play`, `settings`, `first-light-win` or `full-sky`. Add a sequence field before the extension when multiple frames otherwise share a name.
- **Device/variant:** Identify the simulator/device model and the condition being compared, such as `default-text`, `largest-text`, `reduce-motion` or `calm-effects`. Record OS, Simulator versus physical device, text size and motion settings in the report. Use an additional variant field when needed to avoid collisions.

Never name a capture `latest`, `final` or `current`; the index owns selection and status. Never overwrite a different build's evidence with the same filename. New captures follow this convention; do not rename historical payloads, change manifests or invent missing release metadata merely for consistency. Packaged artwork and generated XCTest attachment names remain under their existing boundaries; give an exported frame its canonical name when selecting it for durable documentation.

## Cleanup with each visual change

1. Keep raw captures, recordings and test exports in ignored `artifacts/` or temporary storage. Retain only the frames needed to explain a decision, regression or acceptance result under `docs/evidence/`, with a source/build and capture context.
2. Before completing a UI or artwork change, review the visual reference and the screenshots for the surface it replaces. Promote inspected replacement captures with the build naming convention, or mark the index entry **Needs refresh** and name the missing capture; superseded comparisons are **Historical**. Never select a replacement solely by filename or date.
3. Retire a small batch of superseded or duplicate screenshots in the same change. Check incoming Markdown/HTML links and manifests; keep unique failure, accessibility, device and unresolved-comparison evidence until its owner resolves the need. Age alone is not a deletion criterion.
4. Remove obsolete image links/embeds, preserve the original findings and test limits, and add a retirement notice to affected reports. Record paths, SHA-256 and a committed recovery revision below before removing tracked files. Never rewrite Git history or alter sealed artwork, packaged assets or historical manifest contents for cleanup.

**Completion check:** No broken image references; active guidance leads with the selected implementation or an explicit refresh gap; new retained captures identify their build and context; retired files are recoverable. Run `python3 scripts/ci-hygiene.py` and `git diff --check`. This is part of each relevant change, with no background deletion job.

## Retired screenshots

### October 17, 2026 — initial accumulation prototypes

Removed **13 screenshots (7,686,881 bytes)** from the two October 16 accumulation/automatic-shower prototype reports. Their forecast-heavy layouts and early jewel rendering have been superseded by compact HUD, Crystal Glow and Observatory work. Reports, attachment manifests, hashes and test results remain source-bound. This does not remove historical bytes from Git storage.

**Recovery revision:** `60bb9d66ec95d9921377f3316d8049423bff088c`. From the repository root, substitute an exact path from the table:

```sh
git show 60bb9d66ec95d9921377f3316d8049423bff088c:docs/evidence/starfalls-prototype-2026-10-16/starfalls-empty-preview.png > /tmp/starfall-historical-preview.png
```

Recover into temporary storage for historical investigation; do not promote recovered frames as current UI. Compare the recovered file's SHA-256 with the record below. Original attachment manifests may still name the retired files; they document the original export rather than working-tree availability.

| Retired repository path | Bytes | SHA-256 |
| --- | ---: | --- |
| `docs/evidence/starfalls-prototype-2026-10-16/browser-preview.png` | 72,488 | `05d05995dae1c3f0bb791b084f9354828fa7ea1976853db89d144c867faa5e03` |
| `docs/evidence/starfalls-prototype-2026-10-16/starfalls-after-clear.png` | 813,668 | `9adf868ba04d58e723ec37b811c5b13d1e6c70c4f4c07a2f9c64080c8f723a66` |
| `docs/evidence/starfalls-prototype-2026-10-16/starfalls-calm-after-dismissal.png` | 843,937 | `dd33365b996ee9981616ece87044b55b304861650748cbb07963b421d8c95e93` |
| `docs/evidence/starfalls-prototype-2026-10-16/starfalls-empty-preview.png` | 727,690 | `5af0edc76baebab453adfe28e6864fb0aeff1bab12c50794a35a924c2151f07a` |
| `docs/evidence/starfalls-prototype-2026-10-16/starfalls-grown-and-matchable.png` | 821,307 | `f7e6ad024bb913d49f3036d3cb5a2a1dfbc78e3ebd5097143e3be3aecd3732c9` |
| `docs/evidence/automatic-starfalls-2026-10-16/automatic-after-clear-paused.png` | 803,620 | `f274d1e4bd41a5d6e6a02451800ea866422b19f852d9afe8549451a7c4055a53` |
| `docs/evidence/automatic-starfalls-2026-10-16/automatic-calm-after-dismissal.png` | 824,418 | `164d6c26f8ec1ad425b292ff7a7d150757ab7362a4d43dfcfac911b4fffee45e` |
| `docs/evidence/automatic-starfalls-2026-10-16/automatic-empty-preview.png` | 722,198 | `f11fcf029daa1d8b2f772c88906c7fef372262710fce3ffb086a0495c9c7efe8` |
| `docs/evidence/automatic-starfalls-2026-10-16/automatic-matchable.png` | 818,204 | `edaa5d87d391b149fc277fa35de0a5356f0060e1a0853e4739135fb3b269a91a` |
| `docs/evidence/automatic-starfalls-2026-10-16/automatic-overflow.png` | 1,159,691 | `3aba1d2c18094f180a91908f39f42dda363d25cfb81b7ce19a7f7739a471c09e` |
| `docs/evidence/automatic-starfalls-2026-10-16/browser-manual-play.png` | 31,639 | `848d6ddf2064ad6c5806d7f5b6784c5fbe178a6a0875a004a9274a56f44331ef` |
| `docs/evidence/automatic-starfalls-2026-10-16/browser-ready.png` | 24,192 | `e77a879a7809622fc83d6ac1e081ae57f73afbfd204ce2358ea0efde9611baeb` |
| `docs/evidence/automatic-starfalls-2026-10-16/browser-reduce-motion.png` | 23,829 | `34d70924954eea7ed95d7038766c650a4f3c6e425a5b6e7c1707d8aa8b74b93a` |

### October 17, 2026 — superseded cast and routine prototype frames

Removed **21 screenshots (12,603,663 bytes)** after auditing all 190 tracked evidence images (117,488,461 bytes) at `794a0d1d46c4eb00b8c975b521fc63894f50104d`. No exact SHA-256 duplicates were found; selection used report findings, source relationships, incoming references and the engineering/experiment registers rather than age alone. This batch removes routine frames and superseded per-character exports, preserving unique failure, accessibility and comparison evidence.

| Reports examined and changed | Retirement boundary / retained evidence |
| --- | --- |
| [star-cast-2026-10-17](evidence/star-cast-2026-10-17/README.md) | 3 retired. Crystal Glow supersedes these body/material and ordinary-play exports. The largest-text capture remains as layout evidence; original source/test/capture manifests remain intact. |
| [star-cast-luminous-2026-10-17](evidence/star-cast-luminous-2026-10-17/README.md) | 2 retired. Crystal Glow supersedes the material and crowded-board exports. The largest-text failure capture remains because ENGINEERING.md still cites this unresolved layout evidence. |
| [star-cast-motion-2026-10-17](evidence/star-cast-motion-2026-10-17/README.md) | 6 retired. Crystal Glow supersedes these individual body sheets. The whole-cast review remains because it is a documented source for Crystal Glow concept work; flight/landing and paused-turn samples remain as motion-comparison evidence. |
| [compact-ui-2026-10-16](evidence/compact-ui-2026-10-16/README.md) | 1 retired. The compact HUD and Observatory supersede this routine paused-board frame. The largest-text capture remains as source-bound accessibility/layout evidence. |
| [dark-starfalls-2026-10-16](evidence/dark-starfalls-2026-10-16/README.md) | 6 retired. Later compact-HUD, Crystal Glow and Observatory checks supersede these routine prototype-play/handoff frames. Dark-star before/after, native/browser VoiceOver and system Reduce Motion captures remain as distinct interaction/accessibility evidence. |
| [starfall-balance-2026-10-16](evidence/starfall-balance-2026-10-16/README.md) | 3 retired. Later balance/persistence checks and compact-HUD/Observatory layouts supersede these routine board/handoff frames. The labeled Gentle/Frequent settings capture and native VoiceOver settings capture remain as distinct control/accessibility evidence. |

**Recovery revision:** `794a0d1d46c4eb00b8c975b521fc63894f50104d`. Recover any path below with `git show 794a0d1d46c4eb00b8c975b521fc63894f50104d:<path> > /tmp/<filename>` and compare its SHA-256. Original manifests remain historical export records; their retired filenames are not broken working-tree links.

| Retired repository path | Bytes | SHA-256 |
| --- | ---: | --- |
| `docs/evidence/star-cast-2026-10-17/material-review.png` | 802,838 | `5d9d76a8ba8e0b91a195ab11397daf70210c25196db4b53bb49a8334adcc8125` |
| `docs/evidence/star-cast-2026-10-17/landing.png` | 324,158 | `04144797458aa4ea0d7fd47ea004340a132f6cf5369c4e434711a985174f7a7a` |
| `docs/evidence/star-cast-2026-10-17/mixed-cast.png` | 638,500 | `364acc70cb1abe37415a7484c83b2ccbd5030ebb65cbaaca0466c48229cc0dfb` |
| `docs/evidence/star-cast-luminous-2026-10-17/material-review.png` | 943,772 | `f1d16a5b291f7a90fa4ff56ff3e0d6bdcb1a4418b207382263549addda6f6a16` |
| `docs/evidence/star-cast-luminous-2026-10-17/crowded-board.png` | 1,076,164 | `bc483f3a504acaf48271413458e227c2fa9a3f3fe97fdb4bbf4b4a5cef5166cc` |
| `docs/evidence/star-cast-motion-2026-10-17/Spark.png` | 288,560 | `5a60390921b3c0a7cced2fac571f79f1a902cff17ad220ac561481925ec66623` |
| `docs/evidence/star-cast-motion-2026-10-17/Sunny.png` | 365,939 | `8cf5754255c5110bcff32918fb83280fcc8a9a38a04bcaa7b5339462340dd061` |
| `docs/evidence/star-cast-motion-2026-10-17/Pip.png` | 411,486 | `3b38c3462256b0bdb01196aab48f6619d088f577927a09e8960c081254cafcf7` |
| `docs/evidence/star-cast-motion-2026-10-17/Twinkle.png` | 361,417 | `f82295b577eedbd73fdadf1c496b9c995f73126542b01eb2f6eb217c764dfd91` |
| `docs/evidence/star-cast-motion-2026-10-17/Nova.png` | 278,296 | `1c2a5994202f8be13f3eaef3a7c94b4d1aea15024ec17e4eeaa8905b809724ea` |
| `docs/evidence/star-cast-motion-2026-10-17/Dusk.png` | 289,176 | `e56a351f66e576d25deca17f222a0b9f874e3a9ff7a4b22be8bb0ea5d97af283` |
| `docs/evidence/compact-ui-2026-10-16/paused.png` | 674,890 | `df3dcea6b37dd7063dde3453d9297cd076fd5f8055ec32cb3a42bcf2f7ae1d65` |
| `docs/evidence/dark-starfalls-2026-10-16/automatic-after-clear-paused.png` | 829,335 | `e45e8bfbf09100c4545b5f0fd21c95b51cf5dd73733f66ec3270242bb3aa364c` |
| `docs/evidence/dark-starfalls-2026-10-16/automatic-calm-after-dismissal.png` | 853,782 | `3f56ed780abee7f2e1776e8789b0f4a05b43c1ddc2b2468a192a583013a32151` |
| `docs/evidence/dark-starfalls-2026-10-16/automatic-empty-preview.png` | 743,317 | `1c23751f1b59858e56a82434e24eab2b979bfcd5288ef149434f4a34626b0539` |
| `docs/evidence/dark-starfalls-2026-10-16/automatic-matchable.png` | 842,056 | `57b4417f00b9da0f3bb600476cc474bdf50591d4b3383ed0553d6bd0ae665063` |
| `docs/evidence/dark-starfalls-2026-10-16/automatic-overflow.png` | 1,205,107 | `e5569360203404348c0c9176d3183a8025efe7e79c76b003a012efae02cb2204` |
| `docs/evidence/dark-starfalls-2026-10-16/browser-ready.png` | 27,435 | `b66f2bedf26f5c619b70676f89e62aa652c983ee976c6e6ad4421a0fa5aa3c15` |
| `docs/evidence/starfall-balance-2026-10-16/balance-frequent-dark-star-shower-three.png` | 795,422 | `6b5e0b13d2f15fbdd5d63949c315262ba1aaccc4192ff53dfc12e7e4fc947e3f` |
| `docs/evidence/starfall-balance-2026-10-16/balance-brisk-no-dark-stars.png` | 814,539 | `2a8c93df30d8920d23233847514f780684823159e016465f1d71f24994c1a418` |
| `docs/evidence/starfall-balance-2026-10-16/browser-ready.png` | 37,474 | `91fcabd169d921c8a75895861f8462538df537be227f62130b69b0d35b1aa12a` |

**Scope and limits:** Four representative frames were inspected directly: luminous largest text (retained failure), luminous crowded board, dark-star browser handoff and compact paused play. Reports/manifests and references were reviewed for all 21 selections; not every image was visually reinspected. Current selected captures, recent Opal/gravity/chat evidence, unique accessibility/Reduce Motion records, motion samples, unresolved experiment comparisons and the cast sheet cited as an artwork source remain. Packaged/source artwork and sealed payloads are outside this retirement batch. Remaining images are not thereby certified current or necessary indefinitely.

**Batch verification:** All 21 deleted files recover byte-for-byte from the published recovery revision. Scanned 1,262 repository Markdown/HTML relative targets with no references to the retired images; all 33 changed-document targets resolve. Only these seven documentation files and 21 selected image paths changed; historical manifests and retained evidence are unchanged. Hygiene and diff checks passed. The working tree now contains 169 tracked evidence images totaling 104,884,798 bytes. No app source/resources/configuration changed; core/build/native interaction/animation/actual VoiceOver/device checks are inapplicable and were not run. Rendered Markdown was not checked. Next cleanup should review a named superseded surface against replacement evidence; unresolved comparison and accessibility records remain protected.

## Cleanup verification — October 17, 2026

**Result:** Verified for repository cleanup; current gameplay appearance remains unverified. Tested source: the recovery revision above plus this documentation/image-retirement working-tree change. No app source, resource or build-setting changes.

- All 13 deleted files recovered byte-for-byte with `git show`, matching the recorded sizes and SHA-256 values.
- All 67 relative links/image targets in changed Markdown resolved; code examples excluded. A repository Markdown/HTML reference scan found no links or embeds targeting retired paths. Historical manifest filenames intentionally remain.
- `python3 scripts/ci-hygiene.py` and `git diff --check` passed. The two promoted Observatory frames were inspected directly; rendered Markdown was not checked.
- App/core/build, interaction, animation, actual VoiceOver and device checks: not run, inapplicable to documentation and historical-image removal. No new native capture was made.

**Next action:** The next implementer changing active play should capture the integrated board, update the visual reference, and review the superseded compact-HUD screenshots for the next retirement batch. Keep unique unresolved layout/failure evidence until replacement evidence addresses it.

### Practice adoption checks — October 17, 2026

Naming, source provenance, reference status and disposal rules are now linked from `AGENTS.md`, the writing guide and report template. The capture index covers all five required surfaces and explicitly marks unverified parity **Needs refresh**. Existing evidence was not renamed. All 47 relative documentation/image targets in the five adoption files resolved (code examples excluded); hygiene and diff checks passed. This documentation-only update adds no automatic source-change detector. No native or rendered-document validation was performed; the app is unchanged.

### Main integration checks — October 17, 2026

Applied only this documentation/retirement batch to GitHub main `60bb9d66ec95d9921377f3316d8049423bff088c`, preserving newer character-chat, launch-screen and pacing guidance. Replaced the local-only recovery revision with that published main revision after verifying all 13 image hashes. All 98 changed-document relative targets resolve, all 13 retired images recover exactly, hygiene and diff checks pass. App source/resources/build configuration are unchanged; native tests/builds are inapplicable.
