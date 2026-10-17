# One Starfall app, updated from main

**Result:** Verified one-app delivery; broader CI pending · **Owner:** current implementer · **Date:** 2026-10-17

The user requests one installed app now, with the approved constellation swipe and repeatable updates from GitHub main. Regular `com.starfall.prototype` retains the chosen 0-starlight round; the lab's 26-starlight sky is backed up, not imported. Both downloaded saves decode with the adopted core and re-encode with every JSON field unchanged. Those preflight checks kept both apps in place; the verified delivery and retirement are recorded below.

**Next action:** continue gameplay polish with automatic development updates. Follow the linked remote run to its outcome; full RC acceptance remains separate.

## Outcomes against acceptance

| Criterion | Result and scope |
| --- | --- |
| Selected-set rules and saves | 63 core tests pass, including old-save continuation, ordinary tap/trace separation, selected IDs, preview/replay and invalid walks. Actual original/lab preference save payloads both validate; original remains selected. |
| Native gesture and store boundaries | Final clean-source invocation passes 24 hosted store tests and 4 UI tests, zero failures/skips: chosen five from six, insufficient/outside release, ordinary/rapid taps, saved relaunch and largest-text drawing/build metadata. Hosted checks cover stale input across pause, settings, restart, fixture, motion and shower boundaries. |
| Supporting normal play | Earlier working-tree run completes 16 UI cases and 24 hosted cases. Fifteen UI cases pass, including automatic rain, background/relaunch/overflow, balance, menu, First Light win/loss, large text, paused guidance, Reduce Motion and one inherited focused VoiceOver check. One old help-copy assertion fails; it is corrected to check both actual-star count and light value, then passes in the final invocation. The earlier command remained resolving packages after its case summaries and was stopped; it is not a passing command. |
| Build and membership | Release Simulator and signed Debug iPhone builds pass. The Debug fixture is absent from Release; no extra app identity or Game Center work is added. Built signed bundle/Info.plist verifies `com.starfall.prototype` and `dev.bc187c831e`. |
| Delivery decisions | Six isolated updater tests pass: runtime versus docs identity, exact-source/latest CI status, disconnect, pending CI, failed install/cached retry, and unchanged/docs-only skip with actual installed-source provenance retained. Two matrix tests preserve all non-VoiceOver cases and restore five named actual sessions for RC. |
| Actual delivery | Configured device discovery succeeds. A real first poll safely waits for main CI on the pre-adoption commit. Signed build is cached and verified; installation/one-app inventory/service activation remain pending. |
| Accessibility and motion | Full actual VoiceOver: deferred to RC. Native largest-text/ordinary Reduce Motion checks are narrower evidence. No new physical haptic/animation quality acceptance; the user-approved lab first pass remains source-bound. |

## Verification context

**Source:** Clean local `821e95c` is the final native-test tree; the GitHub branch is verified tree-identical. App/core/config runtime is `dev.bc187c831e`. Core final checks and Release/device builds preceded later test/script/documentation commits, which did not change those runtime inputs. Base GitHub main is `9a0a93e`; unrelated local Game Center/connector work is excluded. The earlier broad native run is supporting working-tree evidence, not exact final-tree acceptance.

**Environment:** Xcode 27.1 (27A9275), macOS 27.0.1 arm64. Debug UI/hosted tests: iPhone 17e, iOS 27.0 (24A434), simulator `A84C81F5-AE41-496A-97AE-E17C63E18D29`. Signed build targets the configured connected iPhone 16 Pro Max / iOS 26.6.2. No physical playthrough or phone screenshot is claimed by building.

Reproduce from the clean source:

```sh
python3 scripts/ci-hygiene.py
python3 scripts/test_device_update.py
python3 scripts/test_native_test_plan.py
bash -n scripts/ci-simulator.sh
git diff --check
swift test
xcodebuild -project Starfall.xcodeproj -scheme Starfall -configuration Debug \
  -destination 'platform=iOS Simulator,id=A84C81F5-AE41-496A-97AE-E17C63E18D29' \
  -derivedDataPath /tmp/starfall-oneapp-dd ARCHS=arm64 ONLY_ACTIVE_ARCH=YES \
  CODE_SIGNING_ALLOWED=NO STARFALL_BUILD_ID=dev.integration -parallel-testing-enabled NO \
  -only-testing:StarfallAppTests/FallingSkyStoreTests \
  -only-testing:StarfallUITests/ConstellationTraceNativeTests \
  -only-testing:StarfallUITests/FallingSkyInteractionTests/testFirstShowerIsPlayableAndManualInputStaysPaused test
```

Final native xcresult reports **28/28 passed, 0 skipped**. Raw output: `/tmp/starfall-oneapp-{core-final,native,native-final,release,device}.log`; final xcresult and inspected attachments are under `/tmp/starfall-oneapp-dd/Logs/Test/` and `/tmp/starfall-oneapp-attachments/`. Retained preference backups are local under `~/Library/Application Support/Starfall Device Updates/backups/`, never committed. Setup/status/disable are in [scripts](../../../scripts/README.md#one-app-iphone-updates); [policy](../../DEVELOPMENT_BUILDS.md) owns delivery and RC cadence.

The final selected-five, largest-text menu and ordinary-clear screenshots were inspected. They show readable controls, five points with the sixth star retained, and usable menu dismissal; stills do not establish trail/burst motion or haptic feel. Runtime visuals remain the approved first-pass design; [historical lab captures](../constellation-trace-2026-10-17/README.md) keep their original source attribution.


## Actual one-app delivery

The local LaunchAgent installed **`dev.bc187c831e` from GitHub main `ba348d758b2b2e5dcc63bf0f4fccf75bc357a7fc`** on the connected iPhone. Its recorded validation is local core tests passed, signature verified and `mainCIAtInstall: pending`. Core tests also pass **63/63** from a fresh `git archive` of that exact main commit, without relying on a developer checkout. The signed cache has the identical runtime fingerprint and verified bundle/Info.plist; no uncommitted app code was used.

The original all-CI gate waited roughly twenty minutes. The user prioritizes development iteration, so the tested host follow-up uses local core tests and signed-build verification while broader CI runs in parallel, holding known failures. This is an explicit delivery-policy change, not a passing remote test claim. [Main CI run 39067366898](https://github.com/lbeezr/starfall/actions/runs/39067366898) was still running at installation. Release/VoiceOver acceptance is not waived.

After installation, a fresh preferences download matched the pre-delivery committed round and every checked game preference; score remained **0**. The lab was backed up again, then uninstalled. A real phone inventory now contains exactly one `com.starfall.*` app: **Starfall / `com.starfall.prototype`**. No save import, reset, original-app uninstall or automatic game launch occurred. The active mechanics simulator also received regular Starfall with the same runtime build ID and its old candidate was removed; other named QA simulators were not changed.

The LaunchAgent is registered in the logged-in user's GUI session, checks every 120 seconds and exited its successful install run with code 0 and no service stderr. Its installed scripts were compared byte-for-byte with the tested local host follow-up. `installed.json` retains actual source/build/validation; documentation-only checks use `checkedSource` without rewriting installed provenance. Status/config/logs and the original/lab preference backups remain under `~/Library/Application Support/Starfall Device Updates/`.

Host follow-up checks: **9 updater tests and 3 matrix tests pass**, including failed local-core blocking, pending-CI local validation, failed-CI holds, configuration/device/signing ownership and reconfiguration locking, plus Bash 3.2 empty/populated matrix arguments. Bash syntax, hygiene and diff checks pass. The running host helper is this tested follow-up; its publication follows the initial adoption PR. No additional app runtime changes are part of it.

Local physical receipts: `/tmp/starfall-oneapp-final-inventory.json`, `/tmp/starfall-lab-retirement.json`, before/after preferences under `/tmp/starfall-original-*-delivery.plist`, and Application Support `installation.json` / `installed.json`. No phone UI/speech/physical haptic playthrough is claimed; the installation and saved-state checks are the physical-device evidence here.
