# Recover full development CI

**Result:** In progress · **Owner:** current implementer · **Date:** October 19, 2026

Repair simulator discovery, remaining UI regressions and the partial screenshot captures in separate verified batches. Acceptance requires a complete development run: tooling checks, core tests, Debug/Release builds, source-counted UI/hosted matrices with zero failures/skips, and valid compact evidence. Native screenshots require direct inspection; a passing assertion alone does not accept rendering. Physical delivery and full RC VoiceOver are outside this development task.

**Next action:** Verify discovery on the updated runner, reproduce the UI cases with explicit orientation, and inspect fresh captures before claiming closure.

## Batch 1: simulator host

[Run 39274515592](https://github.com/lbeezr/starfall/actions/runs/39274515592), attempt 1, source `73ad2beddb4c247fe9190f356c518f433731ef31`, job `118136124483`, passed all five Python suites and 177 core tests, then `simctl list devices available --json` timed out after 30.021 seconds. The runner was ARM64 macOS 15 with Xcode 26.3. No native build/test ran.

[Apple's Xcode 26.4 notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-26_4-release-notes) identify a repaired `simdiskimaged` loop that could hang simulator commands (172343027), and require macOS 26.2+. [GitHub's macOS 26 image](https://github.com/actions/runner-images/blob/main/images/macos/macos-26-arm64-Readme.md) includes Xcode 26.6. Change the existing job to standard `macos-26`; retain the 30-second discovery bound, one runner, matrix, public-main triggers and cost guard. [Standard runners remain free for public repositories](https://docs.github.com/en/actions/reference/runners/github-hosted-runners#standard-github-hosted-runners-for-public-repositories).

This is an evidence-backed environment correction, not proof that Apple's reported mechanism caused this timeout: no service crash sample was captured. The remote discovery receipt and full run must verify the outcome. Local static/tooling checks cannot emulate GitHub's VM.

## Batch 2: room for the complete serial matrix

[Run 39201250877](https://github.com/lbeezr/starfall/actions/runs/39201250877), source `515f7f8`, job `117894490089`, reached only 35 UI cases before cancellation at 05:23 UTC. Native UI began at 04:58:38; the completed cases consumed 1,445.977 seconds. Its 29 passing cases alone consumed 1,231.546 seconds (42.47 seconds/case); six cases failed. This is observed partial-run throughput, not a successful-suite median, and does not prove which cancellation mechanism fired.

The current source-counted plan selects 120 UI and 316 hosted cases. Extrapolating only those passing UI durations gives about 85 minutes of UI work, before setup, Debug/Release builds, hosted tests and export. A 35-minute whole-job cap is incompatible with that workload. Raise the single-job bound to 150 minutes to accommodate the existing coverage and variation; keep the 90/240-second UI test bounds, hosted/operation bounds, serial execution, zero-retry policy and all count/skip gates. Revisit the estimate using the first complete passing run, not failed-test elapsed time. No new runner or parallel job is added.

Verification: all five existing Python suites pass (55 checks); the workflow parses with Ruby's YAML parser, hygiene and diff checks pass. These checks use main `451219d` plus the workflow/script README/evidence changes. No runtime input changes. Complete remote timing remains pending.

## UI and capture investigation

The compact SE simulator used by the maintenance reproduction was in landscape at the fresh launch, while earlier XCTest attachments had portrait dimensions and cropped content. The fresh simulator screenshot renders its visible landscape viewport. Investigate orientation/setup and scrolling at the native test boundary before changing game rendering. Preserve existing outcome assertions, historical Dusk fixtures, normal-motion checks and all selected tests.
