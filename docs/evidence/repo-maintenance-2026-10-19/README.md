# Repository maintenance baseline

**Result:** Partially verified — read-only audit, no native reproduction · **Owner:** current implementer · **Date:** October 19, 2026, Eastern time

The [upgrade plan](../../REPO_MAINTENANCE_PLAN.md) is grounded in current repository guidance and a retained GitHub Actions sample. The latest 20 runs returned by the API have 11 failure and nine cancelled conclusions, with no success. These are run conclusions, not 20 diagnosed defects. Root causes and full remote acceptance remain open.

**Next action:** reconcile current documentation, then investigate inventory failures and current remote UI assertions as separate workstreams. Preserve the existing native checks and source-bound local acceptance.

## Verification context

Repository inspected at clean `548660b1f78e9d34775eb0ee601e91f146a898ac`. The planning output changes only Markdown plus `ci-sample.json`. Read root/folder guidance, current planning/engineering/adoption records, selected recent evidence, CI scripts and targeted core references; no complete dead-code or session-history audit.

Read-only GitHub query: `GET /repos/lbeezr/starfall/actions/runs?per_page=20`. All returned runs were main-branch Starfall simulator pushes. [Retained fields](ci-sample.json) include exact sources, attempts and links, preserving this sample as the live listing changes. The sample spans creation times October 18, 18:50:52 through October 19, 00:47:34 Eastern. One run reports attempt 2; this is not a census of every attempt. No workflow was dispatched, rerun or changed.

| Inspected remote run | Observed evidence | Limit |
| --- | --- | --- |
| [39201250877](https://github.com/lbeezr/starfall/actions/runs/39201250877), `515f7f8c5e`, job `117894490089` | Cancelled; log includes six failed UI methods; artifact upload skipped. Xcode 26.3 path appears in build commands. | No full matrix result. Cancellation cause and assertion root causes not established. |
| [39198577421](https://github.com/lbeezr/starfall/actions/runs/39198577421), `0bcc8529a2`, job `117887188198` | 172 core tests pass; simulator inventory ends after 30.018 seconds, exit 124. | Inventory failure does not establish an app defect. |
| [39196135300](https://github.com/lbeezr/starfall/actions/runs/39196135300), `7322bcafb3`, job `117879462623` | 172 core tests pass; simulator inventory ends after 30.177 seconds, exit 124. | Same stage failed; underlying cause remains unverified. |

The six observed failed methods in the newest cancelled run are `testCurrentOrbitFollowUpGuideReadsToEndWithoutMovingActionsOrBoard`, `testBalanceControlsPreserveBoardPersistAndChangeArrivals`, `testCompactHUDMenuSuspendsWithoutChangingPauseChoice`, `testCompactPlayfieldKeepsControlsVisible`, `testDarkStarInfluenceRestoreAndAdjacentClear`, and `testOpeningCascadeAllowsNativeClearBeforeLastWave`. The balance case cannot find the `Gentle · 6s` button; the others report failed assertions. These observations do not invalidate or broaden the source-bound [local compact acceptance](../compact-native-acceptance-2026-10-19/README.md).

## Planning checks

| Check | Result |
| --- | --- |
| Repository inventory and targeted code/doc reads | Completed; observations and limits in the plan. |
| Recent CI metadata and three job logs | Inspected through the connected GitHub read tools; compact metadata retained. |
| `python3 scripts/ci-hygiene.py` | Passed: tracked-file hygiene and core UI-import guard. This guard does not validate new untracked document contents. |
| `git diff --check` and local Markdown target checks | Passed: tracked diff whitespace; all 84 local Markdown targets across the plan, this report and the two edited indexes exist. Separate whitespace/conflict-marker checks passed for all three new files. |
| Retained CI sample | Parsed successfully; 20 unique run IDs, with the recorded nine cancelled / 11 failure totals. |
| Runtime/core/build/native/UI/VoiceOver/device execution | Not run; not applicable to this documentation-only change. Remote log inspection is not a local test run. |
| Rendered document review | Not run; source/link review only. |

No measured savings, instruction A/B results, installed repo skills, removals or implementation-completion claims follow from this baseline.
