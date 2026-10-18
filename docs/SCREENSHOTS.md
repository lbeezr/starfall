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
