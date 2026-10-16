# Starfall cloud simulator validation

This repository contains a **manual-only** GitHub Actions workflow. Preparing or pushing these files does not run it. It has not been validated on an Apple runner until an actual successful run is linked and its artifacts are reviewed.

## Before the first run

1. Put this source in the intended private repository and make the workflow available on the default branch. Confirm the commit you want to validate.
2. Review the repository owner's GitHub Actions billing page, remaining included allowance, artifact storage allowance, and applicable budget controls. Do not assume private macOS minutes are free. Obtain approval for any potential charge before dispatching. No account, billing, budget, or plan change is part of this workflow.
3. Only after that check, open **Actions → Starfall simulator (manual) → Run workflow**, select the intended branch, and check `budget_confirmed`. The unchecked default skips the job. This checkbox is an operator acknowledgement, not an enforcement mechanism for GitHub billing.
4. Inspect the run conclusion and download its evidence artifact within one day. Record the run URL and `source_commit` alongside any conclusions.

The workflow uses one standard `macos-15` ARM64 runner and one installed iPhone simulator, with a 15-minute job timeout. It has no automatic triggers, matrix, paid larger runner, caching, runtime downloads, device farm, Apple credentials, App Store submission, or signing-service dependency. A newly dispatched run cancels an older run of this workflow across branches; already consumed minutes can still count. Token permissions are read-only repository contents and checkout does not persist credentials.

As checked on 2026-10-16, GitHub lists standard macOS at **US$0.062 per billed minute** after included usage, rounding partial job minutes upward. Fifteen billed minutes would be US$0.93 of compute at that rate, before any storage, applicable taxes, or other charges. A timeout is not a guaranteed dollar cap; verify current pricing and account controls before each approved run. Standard private runners use the account's included allowance first. Do not change repository visibility to obtain free compute without explicit approval.

Sources: [runner specifications](https://docs.github.com/en/actions/reference/runners/github-hosted-runners), [current runner pricing](https://docs.github.com/en/billing/reference/actions-runner-pricing), [Actions billing](https://docs.github.com/en/billing/concepts/product-billing/github-actions), [manual dispatch](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/manually-run-a-workflow).

## What the workflow does

- Selects the highest-version installed stable Xcode; refuses known beta/preview candidates. It records the exact Xcode, Swift, architecture, source commit, simulator runtime/device, and workflow run URL. The runner image is maintained by GitHub and may change; `macos-15` does not pin an Xcode image.
- Runs `swift test` at the repository root. These are **host-side Swift core unit tests**, not iOS UI tests.
- Builds `Starfall.xcodeproj`, shared scheme `Starfall`, Debug, for an already installed iOS 17+ iPhone simulator. Simulator ad-hoc signing is permitted; no Apple developer account or provisioning profile is provided.
- Installs `Starfall.app` with bundle identifier `com.starfall.prototype` and launches it with `--demo`. That mode uses seed 42, opens the game board, and suppresses save writes. After the initial capture, it relaunches with `--demo --demo-clear`: the app invokes its real first legal `Game.tap` before board presentation, yielding a deterministic post-clear settled board without an animation.
- Checks that each launched process remains alive after approximately five seconds. Captures `initial-board.png` and `post-clear-settled-board.png` from the actual simulator display via `simctl io screenshot` and hashes the PNGs. The second screen’s HUD identifies its cleared/settled demo state.
- Uploads only screenshots, provenance, logs, and the smoke result, with one-day retention. It does not upload the app, DerivedData, simulator disks, or video. The simulator is shut down on normal exit or script failure; the job runner is disposable.

## Evidence and limits

A successful `native-build.log` is evidence that the native source compiled for the logged simulator SDK. `core-tests.log` reports the actual unit tests and results. `smoke-result.txt` is created only after both liveness checks and screenshot commands succeed. The two images show separately launched initial and settled states, not consecutive frames of an observed animation. A PNG is a source-bound capture from the installed native app's simulator run, but the capture command alone does **not** prove that the screen is correct: manually inspect it for the board, layout, error dialogs, and blank rendering.

This smoke check does not tap controls or test clear/fall animation timing, gameplay interaction, audio, haptics, accessibility, save/reload, lifecycle behavior, performance, or pixel-perfect determinism. The seed is deterministic; OS rendering and animation timing may vary. It is not a physical iPhone test or proof of App Store readiness. Use a real device and additional interaction tests before making those claims.

On failure, inspect the exact failed step and logs. Do not repeatedly dispatch blindly; diagnose first and obtain any additional spending authority needed. If an installed compatible runtime is missing, the script stops instead of downloading one. Artifacts may be absent or partial after checkout failure, cancellation, timeout, or upload failure. GitHub's step logs remain the authoritative fallback for build/test diagnostics.

## Maintenance

Actions are pinned to immutable commits verified from their official release pages on 2026-10-16:

- [actions/checkout v7.0.1](https://github.com/actions/checkout/releases/tag/v7.0.1): `3d3c42e5aac5ba805825da76410c181273ba90b1`
- [actions/upload-artifact v7.0.2](https://github.com/actions/upload-artifact/releases/tag/v7.0.2): `cf430e030ddbb5b0abf93d22962f4752f3646cd9`

Review new official release notes and commit provenance before updating pins. Keep `workflow_dispatch` as the only event unless automatic runs and their potential cost are separately authorized. The script can be syntax-checked without Apple tooling using `bash -n scripts/ci-simulator.sh`; this does not validate Xcode or simulator commands. The actual cloud run remains required.
