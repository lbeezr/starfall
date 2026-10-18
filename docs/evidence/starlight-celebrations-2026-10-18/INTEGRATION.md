# Starlight celebrations on current main

**Result:** Partially verified development integration · **Owner:** current implementer · **Date:** October 18, 2026

Port only the celebration change onto main `3b42b42`, preserving its v6 saves, Opal, five-feed Dusk, exact recipes, causal relays, dialogue and independent-column input. The earlier published prototype snapshot is not the merge base or a device-delivery source. Core and simulator builds pass. The earlier integration passed all 214 hosted tests; final runtime checks encountered simulator stalls, detailed below. Physical preference and full actual VoiceOver remain separate acceptance.

**Next action:** PR #82 is merged as `1952312`. Recover simulator/XCTest execution, then complete the outstanding native and visual/physical acceptance before release. No phone installation is requested; future delivery must use the canonical updater on merged main.

## What changed and stayed authoritative

- Store-owned receipts replace old decorative tails. Only a committed positive award produces collection light, a numeric counter response and a finite callout. Automatic showers, exchanges and zero-reward clears never invent points or a celebration.
- Actual rewarding Opals are included; drained stars are excluded from collection origins even though they remain part of the traced shape. The Opal/Dusk fixture has eight matching value but only seven reward: the receipt displays seven. It does not recompute or modify score.
- Normal constellations, exact square/cross recipes and existing causal relays receive distinct presentation categories. Relay names come from `SkyTechniqueRelay`, not speed or a new multiplier. Recipe preview/release share one drawing order.
- A single overlay uses board, score and full-header anchors. If danger/input chrome consumes the sky space, ordinary-size text uses a local award rather than covering that chrome. Accessibility sizes omit the decorative heading and put the full-size award below the terrace. Existing native buttons, column reservations, trace hold tickets, scenes and dialogue speech keep their owners.
- Current main's trace recognizer and scripts remain unchanged. The ready cue adds the exact unbanked reward to its existing star-count message. The earlier duplicate trace release burst and positive scene popup are replaced by this shared presentation; zero-reward scene feedback remains.
- Two original local synthesized WAVs use the existing one-voice, interruptible audio owner. Ordinary four-tuck rotation, mute, Silent Mode, output interruption and saved preferences remain intact. No new target, lab route, SDK or dependency.

## Source and checks

Base `3b42b42`; tested final source `cbfc913` (clean runtime sources). The adjacent `integration-source.json` captures runtime/test hashes. Only this report and manifest changed afterward. Historical [prototype evidence](README.md) and `source.json` remain unchanged except a supersession link. No Core, Config, device updater, current input recognizer, existing large store-test file or retired lab tooling was changed.

Xcode 27.1 (27A9275), Swift 6.4, arm64; iPhone 17e / Physics Review `1199FBAF-FCA7-4F0D-BD49-8282154CC9EE`, iOS 27.0 (24A434). Debug simulator tests use ad-hoc signing, one worker and no automatic failure-diagnostic collection. No simulator reset, erase or phone operation.

| Check | Result / boundary |
| --- | --- |
| Core | 149 pass, `swift test --jobs 1`; production rules/save sources unchanged. |
| All hosted app tests | 214 pass, zero skips (`hosted-final.log`), before the ready-reward cue and upstream empty-sky reconciliation. Final rerun compiled/signed the latest tests but stalled at app startup before executing tests; interrupted after about three minutes (`hosted-merged.log`). Includes current migrations, dialogue, responsive input, materials, full/quiet scene motion, recipe and relay checks plus six receipt regressions and distinct audio routing/resource checks. |
| Debug/Release builds | Final Debug build-for-testing and Release build pass with explicit arm64 and deliberate app/test source membership (`build-merged.log`, `release-merged.log`). |
| Native gameplay | Earlier integration: First Light win/full/replay passed (188.018s); Reduce Motion entry/replay passed (73.987s). Welcome/background exceeded its allowance while opening iOS Settings, then the runner stalled and was interrupted. Recipe/relay, selected-five/short cancellation, largest-text and settings/background selectors did not execute. These remain unverified on final source. |
| Visual/animation | New effect timing/readability requires source-bound inspection; no claim from the concept. Existing full-motion scene checks pass. Capture index is **Needs refresh** for this changed surface. |
| Actual VoiceOver / device feel | Actual VoiceOver deferred to RC; not run on this development build. No physical audio/haptic/enjoyment acceptance or device installation. |
| Hygiene | `python3 scripts/ci-hygiene.py` and `git diff --check origin/main` pass. |

The initial hosted run passed the existing 208 checks; two assertions in the new trace receipt test used obsolete eight-point/all-five-contributors expectations. The current Dusk rules make one matched cell gray: the exact seven-point/four-contributor assertions now pass. No core rule, assertion strength, retry policy or production reward was changed to obtain that result.

Raw commands, logs and result bundles are in ignored `artifacts/celebrations-main/`. Representative native command:

```sh
xcodebuild -project Starfall.xcodeproj -scheme Starfall -configuration Debug \
  -destination 'platform=iOS Simulator,id=1199FBAF-FCA7-4F0D-BD49-8282154CC9EE' \
  -derivedDataPath artifacts/celebrations-main/HostedData -jobs 1 \
  ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES \
  DEVELOPMENT_TEAM= CODE_SIGN_STYLE=Manual -parallel-testing-enabled NO \
  -collect-test-diagnostics never -only-testing:StarfallAppTests test
```

Release uses generic arm64 iOS Simulator, no signing, and separate DerivedData. The native run selected seven flow/technique cases with bounded test allowances; only the two completed flow cases above provide native evidence. No retry, assertion weakening, simulator reset or global service restart was used. No full VoiceOver session is added to this routine integration.

## Remaining checks

Inspect normal-motion constellation/recipe release and counter collection, especially dense boards and danger chrome, then judge haptic/audio weight during repeated physical play. Carry unresolved appearance and preference forward explicitly; a merged development feature is not release acceptance. Keep screenshot names/source snapshots aligned with [screenshot practice](../../SCREENSHOTS.md).

## Retry after waking the Mac — October 18, 2026

**Result: Blocked at simulator/test infrastructure.** Tested merged main `1952312eec8db0ed8bd630f4d001af4c8585c6c5` with a clean working tree and unchanged runtime sources. The user requested another attempt after waking the Mac. The same Xcode/iOS toolchain above was used.

- XcodeBuildMCP `test_sim`, selecting all `StarfallAppTests`, built/prepared products and launched the host on Physics Review. No test assertions executed. A sampled host stack waited in `XCTestDriver._prepareTestConfigurationAndIDESession` and `XCTFuture`; the bounded attempt was canceled. The tool reported zero passes and one system cancellation, not an app assertion failure.
- A data-preserving shutdown of that simulator stalled. Its own `launchd_sim` process was terminated, but the simulator remained Shutting Down; its pending shutdown/boot commands were stopped. No simulator erase, shared CoreSimulator service restart or other session termination was performed.
- A second environment check used the already-booted iPhone 17e `4103C352-DFC2-493E-A224-DE4CE3D50889`, iOS 27.0. Native selectors covered recipe/relay, five-star trace/short cancellation, settings/background, largest-text recipe actions and welcome/background. Build/signing completed, but the sampled xcodebuild stack waited in simulator app installation. No selected test started; the run was canceled after roughly two minutes. These checks remain unverified.

Raw logs, process samples and result bundles are retained under ignored `artifacts/celebrations-retry/`. The native command is in `native-17e.log`; hosted tool output is in `hosted-mcp.log`. Hygiene and diff checks pass. No source, save contract, test assertions or player data were changed. No new screenshots, animation, actual VoiceOver or physical-device evidence resulted; the capture index remains Needs refresh.

The waits at session setup, simulator shutdown and installation indicate an infrastructure problem; they do not establish an application defect or prove its absence. Next recovery: restart the Mac mini when other active sessions can be stopped, then rerun the same checks. Existing native/hosted passes above retain their original source limits.
