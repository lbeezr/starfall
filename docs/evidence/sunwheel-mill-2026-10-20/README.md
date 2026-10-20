# Sunwheel Mill verification

**Result: Development verified, merged and installed on the original phone** · **Owner:** Current implementer · **Date:** October 20, 2026

The [current map integration](MAP_INTEGRATION.md) at `49d54fc` / `dev.6fa54c5e65` includes main `f4144ec` and Sunwheel's [damaged/restored map island pair](../../design/sunwheel-mill-07/map-island/README.md). It passes 199 Core, 386 hosted and ten selected native tests, with 53 selected original screenshots inspected, plus Release and clean-export equivalence. The fifteen gameplay paintings remain byte-identical. Merged in [PR #194](https://github.com/lbeezr/starfall/pull/194). The [canonical delivery receipt](delivery.json) verifies `dev.6fa54c5e65` installed on the original iPhone from main `ec1d5d14b3cc803ceeebaf45079339a93af7eec2`, with Core tests and signature checks passed and actual installed identity verified. Player data was preserved; the updater did not launch the game. Main CI was pending at installation; physical play and actual VoiceOver remain separate.

Sunwheel Mill is the seventh playable restoration, earned after a committed Frostfruit Orchard repair. Fifteen distinct paintings cover 0%, 25%, 50%, 75% and 100% in bespoke iPhone, iPad portrait and iPad landscape compositions. The original board-development checks below pass at `d057696`, with no failures or skips. All 67 selected native captures from that run were inspected without a blocking finding; those counts and sampled motion retain their original source.

The [production plan](../../design/sunwheel-mill-07/PRODUCTION_PLAN.md) owns acceptance. [Integrated verification](integrated-verification.json) records exact commands, selections, source snapshots, dirty paths and result hashes; [captures.json](captures.json) identifies the three retained native originals. The previous [candidate record](verification.json) remains historical.

## Tested source and scope

The tested runtime and all 74 test-source files match local commit **`d057696934621b4e9f34a3d57f620d28fe9eb262`**, computed runtime-input fingerprint **`dev.a15832d0fd`**. The actual Simulator bundle label is **`dev.local`**, version 0.1.0, build 1. Subsequent documentation edits do not affect this fingerprint. Every native batch records identical before/after runtime and test hashes. A [clean Git archive comparison](source-equivalence.json) establishes identical runtime inputs and all 74 test files; tests were not executed again inside that export.

This source includes accepted main `b811b85c8e5e7d19539cee379fe330f4a4194415`: living-light gameplay pieces, Lantern/Ribbon's authored 150,000/220,000-point new visits, retained historical rounds, archive v10 and its v3–v9 readers. Sunwheel uses the existing seed-42, eighteen-light challenge with thresholds 0/5/9/14/18. The world envelope remains v1; legacy access remains limited to the original five locations. Bell Choir and the other four later locations remain unavailable.

Native checks use Xcode **27.1 (27A9275)**, macOS **27.0.1 (26A434)**, arm64 and iOS Simulator **27.0 (24A434)**, scheme `Starfall`. Models are iPhone 17e, iPhone SE (3rd generation), and iPad Air 11-inch (M3). Configuration is Debug unless stated. Exact simulator identities and selected methods are in the linked JSON.

## Observed checks

| Check | Result | Evidence scope |
| --- | --- | --- |
| `swift test` | **199 passed**, zero failed/skipped | Core rules, deterministic replay and compatibility |
| Hosted `StarfallAppTests` | **361 passed**, zero failed/skipped | Full hosted selection, including all 105 restoration paintings |
| Sunwheel phone UI | **4 passed**, 14 captures | Five states, dense input, largest text/Reduce Motion, saved win and replay |
| Sunwheel tablet UI | **2 passed**, 20 captures | Both orientations, five states, dense 49-piece boards and native wins |
| Sunwheel compact UI | **1 passed**, 4 captures | Completion, all result actions, relaunch and replay |
| Journey/routing UI | **7 passed**, 29 captures | Earned access, historical locations, restoration entry and shared paths |
| Release simulator build | **Succeeded**, no errors or compiler warnings | Normal resource and target membership |
| Tooling checks | **15 passed** | Existing native-selection and platform helpers |
| Offline reviewer logic | **57 Sunwheel + 57 Frostfruit cases passed** | Script logic; not browser/native rendering |
| Design kit | **14/14 owner hashes match**, six layouts, 294 cells | Compiled current geometry and actual piece sizing |
| Source art | **15 distinct originals match packaged bytes and manifest** | Five states across three native aspect families |

The Release log contains one metadata-tool warning: extraction was skipped because there is no AppIntents framework dependency. There are no compiler warnings. Tooling command: `PYTHONPATH=scripts python3 -m unittest scripts/test_native_test_plan.py scripts/test_rc_platforms.py`. Hygiene, whitespace, local links, artwork provenance and source-equivalence results are recorded with the final publication boundary.

## Inspected native appearance

| iPhone, 75% | iPad portrait, restored result |
| --- | --- |
| <img src="dev-d057696__sunwheel-075__iphone-17e__default-text.png" width="270" alt="Native iPhone Sunwheel Mill at fourteen of eighteen light, with five golden vanes and the outlet still closed"> | <img src="dev-d057696__sunwheel-restored__ipad-air11__portrait.png" width="360" alt="Native iPad portrait Sunwheel completion with an open outlet, golden onward flow and all result actions"> |

<img src="dev-d057696__sunwheel-dense-075__ipad-air11__landscape.png" width="780" alt="Native iPad landscape Sunwheel board with forty-nine living-light pieces, the workshop terraces and closed outlet">

**Native Debug Simulator captures from `d057696`, default text and normal motion.** Original PNG bytes are retained without resizing, recompression or pixel changes. Display widths only affect presentation in this document. Hashes, export metadata and source binding are in [captures.json](captures.json).

Independent reviews cover [phone](integrated-phone-visual-review.json), [tablet](integrated-tablet-visual-review.json), and [compact/routing](integrated-compact-routing-visual-review.json). All original files were viewed and verified against their capture hashes. Distinct restoration clues remain visible in every family. The dense boards preserve readable living-light silhouettes; the current material from main is retained. Minor outer vane-tip cropping and the portrait score overlapping scenery do not hide the outlet or controls. Physical readability and contrast still need their own evidence.

The static reviewer and design-kit specimens use authored piece shells. They do not reproduce the native living-light fill, shader, aura or deformation. These native captures establish the integrated appearance.

## Restoration and motion

The [asset manifest](../../design/sunwheel-mill-07/production-assets.json) and [complete prompt record](../../design/sunwheel-mill-07/art-prompts.json) preserve generated originals, references, selections and rejected attempts. Each family keeps its camera, workshop, supports and paths registered. Light progresses through no vanes, one vane, three vanes and five vanes. At 75%, ordinary lamps are restored but the opaque outlet remains closed and onward/foreground channels remain dark. At 100%, the leaves open and golden light flows onward. No center-clearing mask or walking scenery characters are introduced.

[Sampled native motion](integrated-motion-review.json) records a 202.888-second normal-motion phone recording. Inspected samples show 14/18 with a closed outlet at 136 seconds; committed 18/18, +4 and golden transfer trails at 137 seconds; the whole-painting transition at 137.25 seconds; and the open outlet with a usable result at 137.5 seconds. Later samples remain settled. This is sampled frame evidence, not continuous playback or frame-time measurement. Dense rapid clearing finished before recording began; its assertions and stills are separate evidence. Saved-win interruption, relaunch and replay are established by native tests and their screenshots.

## Historical attempts and process limits

The initial `b7f4fd8` candidate passed its recorded checks before concurrent main added living-light materials and the first-pair Story changes. A successful intermediate `1cc4f9a` integration was superseded by `d057696`. Their source-bound results remain linked in the JSON; they do not substitute for the final accepted-source checks above.

The initial master-fit probe used repeated completed masters in all five state slots and a 21-piece board. Separate direct 49-piece inspection then covered phone and portrait, not landscape. This fell short of the kit's full-occupancy-before-derivation sequence. Final five-state and dense native checks now cover all three families, but do not retroactively make that earlier gate complete. Future locations should complete all three master gates before deriving intermediate states.

The probe's raw tablet PNG exceeded the 5 MB publication-export bound. A temporary local indexer admitted the unchanged original under a 20 MB local bound; no native assertion was weakened and no test was rerun for that export. The first Core invocation hit a sandbox compiler-cache denial before compiling; the authorized run passed. A tooling invocation with an incorrect Python import path failed before executing tests; the corrected command passed all fifteen. Original receipts are retained in the historical record.

Actual VoiceOver, full RC acceptance, minimum-iOS-17 rendering, measured contrast, physical play and measured animation performance were not established by this batch. They retain the explicit development/RC boundaries in [ENGINEERING](../../ENGINEERING.md) and are not inferred from builds, UI tests or screenshots.
