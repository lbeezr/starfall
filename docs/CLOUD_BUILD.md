# Starfall cloud simulator validation

This workflow validates the public `lbeezr/starfall` repository on relevant source/workflow pushes to `main`. It also supports explicit manual runs. It has not been validated on an Apple runner until an actual successful run is linked and its artifacts are reviewed.

## Trigger and budget boundaries

- Automatic runs require **all** of: a `push` event, `refs/heads/main`, exact repository `lbeezr/starfall`, and GitHub's repository-private flag explicitly `false`. Forks and private-repository pushes skip the job. Only app/core/tests/config/project/package/CI-script/workflow changes trigger pushes; documentation-only pushes do not.
- Manual runs require the same exact repository and a checked `budget_confirmed` input, whose default is **false**. They may run on a selected branch and may run if the intended repository becomes private, but only after the operator verifies allowance or approves the cost. The checkbox acknowledges that check; it does not enforce billing limits.
- No account, repository-visibility, billing, budget, plan, runner subscription, or security-setting change is performed by this workflow. No pull-request or scheduled events are configured.

GitHub states that standard GitHub-hosted runners are free for public repositories. This workflow uses the standard `macos-15` ARM64 runner, **not** a paid larger runner. Artifact storage and any other applicable costs still need attention; do not infer an unlimited spending authorization. For any approved paid work, track cumulative charges including storage against the separately agreed total limit, stop before exceeding it, and seek renewed approval if needed. Approval of an initial validation task does not authorize ongoing paid runs.

As checked on 2026-10-16, GitHub lists standard macOS at **US$0.062 per billed minute** after included usage for private repositories, rounding partial job minutes upward. Fifteen billed minutes would be US$0.93 of compute at that rate, before storage, applicable taxes, or other charges. A timeout is not a guaranteed dollar cap. If visibility changes to private, automatic pushes skip; check remaining allowance and approval before a manual run. Do not change visibility to obtain free compute without explicit approval.

## Running and reviewing

1. For the approved public repository, push an intended source change to `main`; the job-level guard checks repository identity, visibility, and event/ref before allocating a runner.
2. For a manual run, review the owner's applicable billing and artifact-storage allowance first. Open **Actions → Starfall simulator → Run workflow**, select the intended branch, and check `budget_confirmed` only after that review. The unchecked default skips the job.
3. Inspect the run conclusion and download its evidence artifact within one day. Record the run URL and `source_commit` alongside any conclusions. Diagnose failures before additional attempts and remain within the total authorized budget.

The workflow uses one standard runner and one installed iPhone simulator, with a 15-minute job timeout. It has no matrix, paid larger runner, caching, runtime downloads, device farm, Apple credentials, App Store submission, or signing-service dependency. A new run cancels an older run of this workflow across branches; already consumed usage can still count. Token permissions are read-only repository contents and checkout does not persist credentials.

Sources: [runner specifications](https://docs.github.com/en/actions/reference/runners/github-hosted-runners), [current runner pricing](https://docs.github.com/en/billing/reference/actions-runner-pricing), [Actions billing](https://docs.github.com/en/billing/concepts/product-billing/github-actions), [manual dispatch](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/manually-run-a-workflow).

## What the workflow does

- Selects the highest-version installed stable Xcode; refuses known beta/preview candidates. It records the exact Xcode, Swift, architecture, source commit, simulator runtime/device, and workflow run URL. The runner image is maintained by GitHub and may change; `macos-15` does not pin an Xcode image.
- Runs `swift test` at the repository root. These are **host-side Swift core unit tests**, not iOS UI tests.
- Builds `Starfall.xcodeproj`, shared scheme `Starfall`, Debug, for an already installed iOS 17+ iPhone simulator. Simulator ad-hoc signing is permitted; no Apple developer account or provisioning profile is provided.
- Installs `Starfall.app` with bundle identifier `com.starfall.prototype` and launches it with `--demo`. That mode uses seed 42, opens the game board, and suppresses save writes. After the initial capture, it relaunches with `--demo --demo-clear`: the app invokes its real first legal `Game.tap` before board presentation, yielding a deterministic post-clear settled board without an animation.
- Checks that each launched process remains alive after approximately five seconds. Captures `initial-board.png` and `post-clear-settled-board.png` from the actual simulator display via `simctl io screenshot` and hashes the PNGs. The second screen’s HUD identifies its cleared/settled demo state.
- Runs exactly one native XCUI test on the same simulator with parallel testing disabled and a 120-second maximum test execution allowance. The flow launches seed 42 without a pre-applied clear, physically taps the SpriteKit board, checks score/moves and post-animation input readiness, navigates Menu/Continue, checks the sound toggle and its retained value, and restarts. It retains named XCTest screenshots `real-touch-post-clear.png` and `real-touch-restarted.png`.
- For success, requires exactly one passing UI test and zero failures in the result summary. After a failed test it attempts to preserve any of the same two named screenshots already attached, labels them partial evidence, and preserves the original failed test exit status; a missing later-stage screenshot is expected in that case. Exports attachments using the installed `xcresulttool`; missing/ambiguous named PNGs, unsupported export/summary formats, or images over 5 MB fail visibly. The `.xcresult` bundle and all unselected attachments stay only on ephemeral runner storage.
- Uploads only screenshots, provenance, logs, compact UI result/attachment JSON, and smoke results, with one-day retention. It does not upload the app, DerivedData, simulator disks, or video. The simulator is shut down on normal exit or script failure; the job runner is disposable.

## Evidence and limits

A successful `native-build.log` is evidence that the native source compiled for the logged simulator SDK. `core-tests.log` reports the actual unit tests and results. `smoke-result.txt` is created only after both liveness checks and screenshot commands succeed. The two images show separately launched initial and settled states, not consecutive frames of an observed animation. A PNG is a source-bound capture from the installed native app's simulator run, but the capture command alone does **not** prove that the screen is correct: manually inspect it for the board, layout, error dialogs, and blank rendering.

The initial two-image launch smoke check does not tap controls. The separate XCUI test exercises one real clear and waits for input to be re-enabled, but it does not measure clear/fall animation timing or capture intermediate frames. Neither check validates rapid taps, VoiceOver, audible sound, haptics, disk save/reload, broader lifecycle behavior, performance, or pixel-perfect determinism. The seed is deterministic; OS rendering and animation timing may vary. It is not a physical iPhone test or proof of App Store readiness. Use a real device and additional interaction tests before making those claims.

On failure, inspect the exact failed step and logs. Do not repeatedly dispatch blindly; diagnose first and obtain any additional spending authority needed. If an installed compatible runtime is missing, the script stops instead of downloading one. Artifacts may be absent or partial after checkout failure, cancellation, timeout, or upload failure. GitHub's step logs remain the authoritative fallback for build/test diagnostics.

## Maintenance

Actions are pinned to immutable commits verified from their official release pages on 2026-10-16:

- [actions/checkout v7.0.1](https://github.com/actions/checkout/releases/tag/v7.0.1): `3d3c42e5aac5ba805825da76410c181273ba90b1`
- [actions/upload-artifact v7.0.2](https://github.com/actions/upload-artifact/releases/tag/v7.0.2): `cf430e030ddbb5b0abf93d22962f4752f3646cd9`

Review new official release notes and commit provenance before updating pins. Keep the exact public-repository/main push guard, source-path restrictions, and manual budget gate. Broadening automatic runs to private repositories, forks, other branches, pull requests, schedules, or paid runners requires separate authorization. The script can be syntax-checked without Apple tooling using `bash -n scripts/ci-simulator.sh`; this does not validate Xcode or simulator commands. The actual cloud run remains required.

### Native UI evidence tooling

Apple documents `xcresulttool get test-results summary` and `export attachments` in its [Xcode 16.3 release notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-16_3-release-notes) and directs users to the installed command help. The script records `xcresulttool help export attachments` for the selected Xcode. The native UI test and export path must be verified by a fresh successful run; earlier two-image smoke results do not establish UI-test success.
