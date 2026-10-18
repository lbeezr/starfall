# Current-game observations can now drive a bounded next change

**Result:** Partially verified · **Owner:** current implementer · **Date:** 2026-10-17

The falling-sky protocol now has a blank local recorder and descriptive summary, covering Opal, storm decisions, input problems and actual replay choices. It replaces no game rules and supplies no participant results. Use the [moderator worksheet](../../../tools/playtest-results/FALLING_SKY_SESSION.md) for the first three uncoached people, then select one cue, payoff, opportunity-frequency or input investigation from what was observed.

**Important limit:** This improves the development feedback loop; it does not establish a more enjoyable game. The offline form's visual and download interaction review is unverified: browser security rejected local `file:` navigation. No workaround or permission change was attempted. The CLI and generated script/contract checks below cover narrower behavior.

## Evidence and acceptance

Tested repository base `d45ed29675f6e52751d0a09e98b46617f95ff209` (current-main branch at task reconciliation). Only the tool, moderator/protocol/roadmap docs and this report differ. Runtime App, Core, resources, build settings and save contracts are unchanged. Exact input hashes are in [source.json](source.json).

| Check | Result and scope |
| --- | --- |
| Python observation suites | `python3 -m unittest discover -s tools/playtest-results`: 26 passed, including 11 new falling-sky checks and the unchanged 15 classical checks. Raw output `/tmp/starfall-feedback-tests.log`. |
| Missing-data handling | Blank slots create no people or assessed failures; offered/unassessed choices, replay time and stated-only interest retain separate counts. |
| Evidence separation | Human/synthetic, repeat people, first-time/familiar, natural/prepared/paused, source/build/settings cohorts and prediction help are checked separately. A matched prediction after a strategy hint cannot inflate the unassisted category. |
| Input validation/CLI | Strict fields/types, anonymous IDs, dates/source SHA, contradictory exposure/prediction/replay, duplicate sessions/JSON keys, blank round trip and refusal to overwrite passed using fictional temporary inputs. |
| Offline form | Contract/defaults generated from the Python owner; no external resources, network calls or persistent storage in the template. Generated script passed Node syntax check with the bundled Node runtime. This is not a browser execution or accessibility audit. |
| Repository hygiene | `python3 scripts/ci-hygiene.py` and `git diff --check` passed. |
| Game rules/saves/native/animation/actual VoiceOver/device | Not applicable to this batch: no product source changes. No current-game validation or human enjoyment is claimed from these tool checks. |
| Participant results | None collected. All retained test inputs are fictional and created only in temporary directories. No claimed replay improvement or preference rate. |

## Corrected course and retired trial

This task initially assessed stale checkout `f35eba8` and built a duplicate white/tracing candidate. Its fixture established 3+3 versus 4+0 immediate scoring; a 40-seed candidate sample exposed 42 connectors in 22 rounds and retained 12 shared-choice states under its fixed policy. These measurements apply only to that temporary candidate, not current production Opal/storm/gravity rules or human preference.

The early five-check native run passed on a shared simulator. A later 19-check run returned 14 passes and five failures; its recording visibly switched to another mechanics build. That run cannot accept this candidate or diagnose a production First Light defect. A task-owned simulator could not boot because of host process limits. A retained-source test also incorrectly treated a helper's legacy save as a fresh round. No passing fixture, Release build or mixed recording justified promotion.

Inspection of **Explore and refine game mechanics** and refreshed main established that production already integrated the intended connector and stronger follow-up examples. All duplicate rule/export/native fragments and edits from this task were removed; temporary exports and raw failed diagnostics remain under `/tmp`, outside the repository. No app was added to the phone and no production round was reset. The final batch contains only current-game observation tooling and docs. This record preserves the failure and source boundary without retaining another mechanic route.

## Next decision

Collect uncoached observations on the actual installed current app. Keep lost opportunities, misunderstood consequences and blocked input distinct. Three people are a pilot for choosing one next investigation, not statistical preference evidence. Full human, physical-device and RC accessibility acceptance remain open. Existing mechanics and input-responsiveness tasks own their runtime work; this batch introduces no competing implementation.
