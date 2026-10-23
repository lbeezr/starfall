# Declare the Core test host's supported minimum

**Result:** Compiler cause reproduced and corrected locally; full remote CI pending · **Owner:** Current implementer · **Date:** October 23, 2026

[Run 40020191057, attempt 1](https://github.com/lbeezr/starfall/actions/runs/40020191057) failed at main `3e88bd9e` in job `120642427731`, before native builds or tests. `FullBoardChoices.swift` uses `Task.isCancelled` to cancel bounded advice searches. The package declared iOS 17 but omitted the macOS host platform, allowing CI's older deployment default to reject Swift concurrency. The fix belongs in `Package.swift`; removing cancellation or suppressing availability errors would leave that contract wrong.

The package now explicitly declares **macOS 12** for host builds/tests and retains **iOS 17**. Its sole library and test target, app target, rules, RNG, save schema and search behavior are unchanged. This adds no Mac app or product. No workflow trigger, test exclusion, timeout, assertion or remote retry is changed.

## Reproduce and verify

Activation main `c6c726f5` contains only documentation/guidance changes after the failed source; `Package.swift`, Core, Core tests and the CI script match that source. Clean correction `229258698abf7b4dd5477af77a06a9eee16e8fab` is the final compiled checkpoint. Later differences are documentation/evidence only. [Verification metadata](verification.json) binds exact commands, input hashes, sources and counts.

CI used Xcode 26.6 / Swift 6.3.3 on ARM64 macOS 26. Local verification uses Xcode 27.1 (`27A9275`) / Swift 6.4 on macOS 27.0.1; the older CI toolchain is not installed here. Default local Core tests already passed before the fix, so that alone did not reproduce the remote failure.

All Core source typechecked explicitly at macOS 10.13 reproduces twelve `Task` / `isCancelled` availability diagnostics. Typechecking at 10.15 succeeds, but an explicit 10.15 package build is rejected by the current SDK's supported 12.0–27.0.x target range. This additional boundary led to the final macOS 12 declaration. The complete Core suite is therefore run with `--triple arm64-apple-macosx12.0`, rather than relying only on the newer toolchain's default target.

Final acceptance at that minimum: **336 Core tests, six hosted checks and one real native UI case pass with zero failures/skips**. The hosted checks cover visible-pattern scope, read-only snapshots, cancellation and retained/current definitions; the UI case compares alternatives, preserves the round and returns to ordinary play. The test executable's Mach-O minimum is 12.0. Debug build-for-testing passes in 2.4s and Release in 5.5s after the manifest revision; the first builds took 35.7s/34.9s. The 27 existing updater behavior tests pass. Hygiene, whitespace and unchanged source-counted membership are checked before publication. The inventory is 226 UI / 554 hosted, not a full-matrix pass. These selections do not establish full remote health, physical play, actual VoiceOver or minimum-iOS acceptance. No screenshot or animation claim is needed for this manifest correction.

**Next action:** Verify the new automatic main run clears the host compilation gate, then assess its complete development result before calling remote CI healthy. The canonical phone updater retains its own exact-source CI, Core, signing and installation checks; this fix does not bypass them. Raw logs and result bundles remain in `/private/tmp/starfall-ci-host-platform-20261023`.
