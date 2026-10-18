# Complete build identity and recheck delivery status

**Result:** Verified for development integration · **Owner:** current implementer · **Date:** October 17, 2026

Package manifests/resolution now affect the versioned runtime fingerprint; nested Markdown documentation and Xcode user state do not. The updater repeats its exact-source CI check after signature validation, immediately before installation. A failure that completes during a build holds delivery, retains the current app and caches the verified candidate for retry. Pending/unavailable CI retains the accepted development policy; it does not count as native/UI acceptance.

**Next action:** Merge and reload the installed service after its active update releases the lock. Continue the [layout/native batch](../../design/RELIABILITY_POLISH.md). No app, rule, save or bundle-identity change; the identity recipe intentionally causes one rebuild.

## Verification

Source: main `ca68199` plus this PR's scripts, tests and documentation. Python 3 on macOS; Xcode 27.1 arm64 simulator build. `python3 scripts/test_device_update.py`: all 13 checks passed, including add/change/remove of Package.swift, optional resolution files, runtime code/resources/config/project/scheme, documentation/user-state exclusion, CI failure during build with cached retry, existing failed-install/core/disconnection/locking cases. No phone/network touched by those tests.

`swift test`: 91 passed (`artifacts/reliability/identity-core.log`). Generic Debug simulator Starfall build passed (`identity-build.log`), hygiene and diff checks passed. Hosted/UI tests are unchanged and were verified in the preceding touch PR; no runtime Swift/UI source changed in this batch. No new device or visual acceptance is claimed. Raw Python output: `identity-tests.log` under ignored `artifacts/reliability/`.

The prior fingerprint omitted root Package.swift and included App/README.md. Regression probes now exercise semantic input changes rather than a duplicate hash implementation. The preinstall race is tested by changing CI from pending to failed during local validation, checking that no install/receipt occurs, then permitting a retry and asserting exactly one build. This is a development updater for one paired phone; broader tester distribution and RC still require their own exact-source acceptance gates.
