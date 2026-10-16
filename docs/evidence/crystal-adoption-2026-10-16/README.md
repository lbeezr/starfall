# Crystal adoption evidence — 2026-10-16

This record separates completed automated/native visual checks from remaining
manual acceptance. Production source is
`127c05760e8ad11dec899a7c94eb2ed55c79c21e`, based on adaptive merge
`a9b7cea2bbfe37cb3542072d63c6403bed9702bd`. The production source has not changed
for the terminal-test diagnostic described below. The narrow terminal-query test repair was subsequently committed as
`41f6461`; it is not included in the original full Debug result.

## Completed checks and acceptance limits

| Check | Current evidence |
| --- | --- |
| Deterministic core | 27 tests passed, zero failures. Retained log: `/tmp/starfall-crystal-core.log`. |
| Portable catalog | Catalog preflight passed and all 11 validator tests passed. Renderer observed the completed run before source freeze; root also observed 11 passes after integration. Neither run's stdout was retained as a local file; no log receipt is invented here. |
| Full Debug native run | 59 tests: 58 passed, 1 failed, 0 skipped. The log separates **47/47 hosted passes** and **11/12 UI passes**. The overall run failed. Original machine summary is copied as [debug-summary.json](debug-summary.json). |
| Terminal diagnostic without source changes | Interrupted after another chat's concurrent native UI session was discovered. No completed rerun or pass is credited. |
| Focused terminal run with fresh post-launch query | **1 test passed, 0 failures, 0 skips**, in 148.213 seconds of test-case execution. All three terminal fixtures and restarts completed with the original assertions retained. Separate summary: [terminal-summary.json](terminal-summary.json). |
| Release arm64 simulator build | Passed. `/tmp/starfall-crystal-release-build.log` ends with `BUILD SUCCEEDED`; product is `/tmp/starfall-crystal-release-derived/Build/Products/Release-iphonesimulator/Starfall.app`. This is not a physical-device distribution build. |
| First Release hosted invocation | Build/setup failed before any test executed: the hosted `@testable import Starfall` could not use a module built without `-enable-testing`. This is separate from the successful ordinary Release app build. |
| Eight focused Release hosted cases with testability enabled | **8 passed, 0 failures, 0 skips**, in 0.772 seconds of test-case execution. [release-summary.json](release-summary.json) records the completed run. The test command supplies `ENABLE_TESTABILITY=YES` while retaining Release optimization and no `DEBUG`. |
| Ordinary Release without launch flags | Phone launch succeeded as PID 40852; its native screenshot shows the saved-game menu and Continue. Product hashes and launch capture: [release-product.json](release-product.json), [release-launch.json](release-launch.json). Manual phone/iPad gameplay input remains unperformed because the Mac was locked. |
| iPad adaptive play with default v2 artwork | **1 UI test passed, 0 failures, 0 skips**, in 100.260 seconds, Debug. Real taps changed 0/18 to 3/17 and then 7/16 after rotation; Settings, menu/continue and restart completed. [ipad-summary.json](ipad-summary.json), [attachments](ipad-attachments.json), [PNG hashes](ipad-screenshot-sha256.json). |

The full Debug result reports an arm64 iPhone SE (3rd generation) simulator,
device ID `0F8006D3-274E-431E-B67C-F2CA26381CD4`, iOS 27.0 build `24A434`.
Its retained originals are `/tmp/starfall-crystal-debug-full.xcresult` and
`/tmp/starfall-crystal-debug-full.log`; exported attachments remain in
`/tmp/starfall-crystal-debug-images/`. The copied JSON is the original failed
summary, not a replacement result. Hosted passes include default five-kind
texture identity, geometry, bounded cache reuse, real missing/malformed member
fallback, clear/refill cleanup, cancellation, and calm/reduced-motion presentation.
Passing UI cases include default all-five physical taps, calm terminal resume,
rapid/cancelled input, accessible controls, Settings, and adaptive layout.

The original Release hosted setup failure is retained at
`/tmp/starfall-crystal-release-acceptance.xcresult` and
`/tmp/starfall-crystal-release-acceptance.log`. The log reports the incompatible
non-testable module and contains zero test-case starts. The subsequent test-only
invocation uses `/tmp/starfall-crystal-release-testable.xcresult` and
`/tmp/starfall-crystal-release-testable.log`; no project or source build setting
was changed. It retains Release optimization and does not add `DEBUG`; testability
only permits the hosted internal-access assertions. The ordinary, non-testable
Release app in `/tmp/starfall-crystal-release-derived/` remains the product for
any additional flag-free manual phone/iPad play. The phone launch was observed
without app arguments; no manual taps are credited.

## Terminal relaunch failure and diagnostic status

`StarfallUITests/StarfallInteractionTests/testTerminalOutcomesPersistAndRestart`
failed at line 310 of the original source: `menu.play` did not exist according to
XCTest after argument-free relaunch of the last-move win (73 cleared, 0 moves).
The earlier 70/2 win relaunch passed. The failed case did not complete its
remaining assertions or the later loss fixture; those portions are not credited.

The failure hierarchy
`/tmp/starfall-crystal-debug-images/3DA39032-D8C4-4C52-A873-B3B3A2CF4464.txt`
reports a terminal game in the new process, PID 17718. However, actual video
frames at 58 and 66 seconds visibly show the expected menu, Continue, and
73 starlight released. The source video is
`/tmp/starfall-crystal-debug-images/88A12213-0523-4CD1-8CFF-136D6460875F.mp4`;
the inspected frame exports are `/tmp/starfall-terminal-video-58.png` and
`/tmp/starfall-terminal-video-66.png`, extracted by root with
`AVAssetImageGenerator`. An element diagnostic,
`/tmp/starfall-crystal-debug-images/44D0E421-CFC2-42CF-B8DC-A8FFBEBF3575.txt`,
retains Continue attributes while its query chain returns game controls.
This contradicts the earlier inference that the app actually entered gameplay;
the evidence establishes a screen/snapshot inconsistency, not a proven
production navigation defect.

The minimal harness candidate obtains a new `app.buttons["menu.play"]` handle
immediately after cold launch, then preserves the same 10-second existence
check, Continue-label check, physical tap, restored score/moves/outcome checks,
and restart assertions. It adds no retry, alternate accepted screen, or longer
timeout. A stale retained element is a plausible cause; an app/session snapshot
problem is not excluded. The subsequent focused pass supports the harness change
but does not prove that the retained handle caused the original inconsistency.
The original full run remains failed; the focused pass does not turn it into a
single successful 59-test run.

The interrupted unchanged diagnostic has local paths
`/tmp/starfall-crystal-terminal-reproduction.xcresult` and
`/tmp/starfall-crystal-terminal-reproduction.log`. The completed focused run is
retained separately at `/tmp/starfall-crystal-terminal-fresh-query.xcresult` and
`/tmp/starfall-crystal-terminal-fresh-query.log`. Its one test passed in 148.213
seconds on the same compact simulator, with no failures or skips. It completed
the 70/2 win, 73/0 last-move win, and 64/0 loss fixtures, argument-free restoration
of each, and all three restarts to 0/18. Production source remained unchanged;
the test-source identity is the separate harness revision recorded below.

[terminal-summary.json](terminal-summary.json) is copied unchanged from
`/tmp/starfall-crystal-terminal-summary.json`.
[terminal-attachments.json](terminal-attachments.json) is copied unchanged from
`/tmp/starfall-crystal-terminal-accepted-images/manifest.json`. The three original
PNG files remain in that local attachment directory; the table records hashes
calculated from their actual bytes, without duplicating the rasters in Git or
claiming additional visual acceptance.

| Attachment name | Exported filename | SHA-256 |
| --- | --- | --- |
| `terminal-won-restored` | `F134B137-C562-4A10-85EA-73CB64B25573.png` | `85c2aed1bc63108cf6bd8402f9f1c3c6ab3278f24b0bd4b367fb042258c93212` |
| `terminal-last-move-won-restored` | `D244A308-100F-49CF-8D38-9792FFABC3B1.png` | `b9b4bb322b0e039bac13658d4379c7fbc203658542bbd5ac74884e98becdfdac` |
| `terminal-lost-restored` | `B163B670-C678-4921-8E5B-9F2E879DDF56.png` | `b95e1daa2a3b38fdef0dc89607bc0a73c2352e0d0dc898b2dc6c2f6aa7e4ed4a` |

## Resource identity and renderer contract

The five runtime imagesets were copied byte-for-byte from the sealed
[v2 package](../../../Artwork/Crystals/v2/README.md). All ten files (five PNGs and
five `Contents.json` files) were independently compared with their package
sources and [manifest](../../../Artwork/Crystals/v2/manifest.json). The package
is newly authored Blender geometry/material/lighting/animation, not recovered
original source or an alpha-identical v1 refinement. Its immutable
`runtime_adopted: false` field records the earlier artifact handoff and has not
been rewritten to describe this later runtime commit.

[source-sha256.json](source-sha256.json) is an exact copy of
`/tmp/starfall-crystal-source-hashes-final.json`. Its `files` map identifies the
original committed adoption files, including all five atlas SHA-256 values.
Its separate `terminalHarnessRevision` records the later test-only candidate:
original UI source hash
`e0ca64625beeef8c30abc52833effc4c6a9e98fee72b7e2409a1aa152e534a9b`, candidate
`6c40719d8e4c22f07e13bb5628b530e07dcad8b665ac4086dba5afc2564e7b4d`.
These identities must not be treated as the same tested UI source.

The catalog validator pins each v2 family atlas separately. The original
`CrystalPilot` Aqua remains distinct, with SHA-256
`a7e0d3c5154a3cb3c474307c876f6d87255fe9a38bc1c78f45081abb58490c2f`.
Explicit Debug `--crystal-pilot` selects that legacy comparison with procedural
art for the other kinds; normal Debug and Release require no artwork flag.
Missing or malformed family members select the complete procedural fallback.

Each atlas contains nine 256 × 256 full canvases, neutral frame 4, and authored
pivot `(128,128)`. The shared loader resolves the complete family once, caches
success and failure, and retains at most 45 frame textures plus 20 quadrant
fragments. The 13,107,200-byte RGBA8 base-level bound excludes UIKit caches,
driver copies, and other overhead; it is not a measured GPU-memory result.

| Kind | Neutral alpha span, pixels | Nine-frame union span, pixels |
| --- | --- | --- |
| Rose | 184 × 184 | 184 × 184 |
| Aqua | 188 × 188 | 188 × 188 |
| Amber | 164 × 143 | 165 × 143 |
| Violet | 174 × 196 | 174 × 196 |
| Mint | 144 × 144 | 146 × 144 |

Those measurements were checked against every PNG frame and the sealed
[geometry report](../../../Artwork/Crystals/v2/review/current/report.json),
and the corresponding hosted assertions passed. Canvas scaling still normalizes
the longest neutral span to twice the requested radius without trimming or
recentering; amber retains its 19.5-pixel neutral bounds-center offset. Clear
fragments remain capped at 48 and refill trails at seven. These bounds are
source/test contracts, not frame-pacing or performance measurements.

Native stills and passing structural accessibility checks do not establish
actual VoiceOver speech/focus/rotor operation, system Reduce Motion operation,
physical-device appearance, or GPU performance. The failed full run is retained
alongside the separate terminal and Release passes. Ordinary-Release manual
phone/iPad gameplay remains unperformed; native Debug phone/iPad interaction
and the focused Release renderer checks are the acceptance evidence for this
artwork adoption.

## Native visual review

Root and the shared design-system owner reviewed the normal compact-phone and
three terminal captures. Five silhouettes remain distinguishable with clear
gutters; outcome text and truthful 73/70 final-move score are readable. Terminal
New game can lie below the viewport; the passing native test supplies actual
scroll/restart interaction evidence.

The iPad initial and post-rotation/play captures show the complete 7×7 board,
all five v2 shapes, clear cell spacing, readable shared HUD/sidebar and New game.
These full-screen attachments avoid the older landscape app-screenshot cropping
issue. They are settled stills, not frame-pacing evidence. A separate pre-existing
maximum-text scrolled status-bar overlap is queued as a small shared-viewport
fix; it is not hidden by this artwork acceptance.
