# Detect replaced phone apps and reject stale delivery

**Result:** Verified for the canonical delivery service · **Owner:** current implementer · **Date:** 2026-10-18

A manual installation from an old feature checkout replaced a newer main build. The updater then trusted its own installed-source receipt and incorrectly reported “up to date.” Build/tests on the feature branch did not prove that shipped work was included.

Acceptance: query the physical phone before every no-op decision; only trust the receipt when its installation URL and bundle version match the actual app. Missing, legacy or mismatched receipts require a verified current-main install. Reject a fetched main that does not descend from the last checked/installed main. Re-fetch immediately before installing and defer when main advanced during validation. Verify the post-install inventory against the installation result before writing a receipt. Preserve lock, local tests, signature, CI, retry and no-launch/no-reset behavior.

**Limit:** This guards the canonical updater and detects/reconciles external replacements. It cannot revoke the Mac user's ability to call Apple's installer with valid signing credentials. No OS-level sandbox, signing restrictions or credential changes are part of this fix. No app/runtime/save-format changes are planned.

**Next action:** Keep delivery on the guarded service and publish the scoped fix against current main. A privileged direct installer remains outside this process boundary; do not claim it is impossible to bypass.

## Executed checks

| Criterion | Result |
| --- | --- |
| External replacement cannot be reported current | Regression checks cover changed container URL, missing app, legacy receipt and version mismatch; each forces a verified main install and reuses the signed cache. |
| Refuse stale/changed source | Real Git forward/reverse/divergent/missing-object ancestry checks pass. A mocked non-descendant main cannot build/install/rewrite its receipt. Main advancing during build and runtime source changing during validation also prevent installation. |
| Preserve delivery gates | CI failure before/during validation, local core/signature failure, locked-device retry, configuration/reload lock and post-install inventory mismatch checks pass. No launch, reset, uninstall or save-transfer commands are introduced. |
| Automated tests | `python3 scripts/test_device_update.py`: 21 pass. `python3 scripts/test_native_test_plan.py`: 3 pass. `swift test --jobs 1`: 120 pass on reconciled current main. Hygiene and `git diff --check` pass. |
| Active physical-device check | Guarded service enabled; actual app URL/version match its new receipt. A second run returns “Up to date.” Existing v3/v4/v5 save bytes are unchanged. [Activation receipt](activation.json). |
| Game/native UI | No App/Core/config/project/package changes relative to main `8598404`; hosted/UI/simulator rebuild, visuals, animation and actual VoiceOver were not rerun for this tooling-only patch. |

**Source:** Guard implementation `5ee35af`, reconciled with main `8598404` at `5d0c946`. Subsequent changes are evidence/documentation only. The active service SHA-256 in the activation receipt matches the tested script. Initial tests against `b80edd8` passed 115 core cases; after main advanced, the merged source passed all 120. No feature-branch app was built or installed.

**Environment:** macOS with Xcode 27.1/Swift 6.4; Python 3.9 standard library; connected iPhone 16 Pro Max, iOS 26.6.2. Raw logs remain in ignored `artifacts/device-delivery-guards/`; recurring service logs/receipts remain in Application Support. Previous service and receipts were backed up under its `backups/delivery-guards-20261018` directory before enabling the tested replacement.

## Failure mechanism and practical limit

The old service returned early on matching source/fingerprint without querying the phone. The reported external install left that receipt untouched, so the early return concealed the regression. Both the exact-source and docs-only fast paths now require a matching OS installation. The installed URL is verified again against the installer result before updating the receipt. Cached repairs retain tests, signature verification, main ancestry and the post-validation head/CI checks.

The stale checkout's commit was rejected against the current production ancestry in the updater's real repository. We did not reinstall a bad build on the phone to reproduce the problem: tests model the mismatched physical installation, and the live upgrade safely exercised legacy-receipt repair using only verified current main (`8598404`, `dev.c64a08904f`). The patch leaves the existing two-minute check cadence and development CI policy intact. Offline/unknown device inventory, failed CI or failed validation can defer repair; those states are reported rather than “up to date.”

Repository instructions prohibit raw feature-checkout installs and require current-main/save reconciliation. These instructions complement the executable checks; they are not a security sandbox. Removing all privileged direct-install capability would require separately scoped Mac/account/signing permissions. Local Markdown links were checked; a rendered Markdown preview was not inspected.
