# <Outcome investigated or delivered>

**Result:** <Verified / Partially verified / Blocked> · **Owner:** <name/current implementer> · **Date:** <date>

<State what changed or was learned, what the evidence supports, and the most important limit.>

**Next action:** <owner, concrete action, completion condition; or none and why>

## Outcomes against acceptance

| Criterion | Observed result | Evidence / limitation |
| --- | --- | --- |
| <linked plan/design criterion> | <pass / fail / not run / not applicable> | <source and reason> |

## Verification context

**Source:** <commit and working-tree differences affecting the result>

**Environment:** <toolchain; configuration; simulator/device and OS when relevant>

<For retained screenshots, follow [screenshot practice](../SCREENSHOTS.md): record actual captured version/build or commit, dirty-input snapshot ID and hashes when applicable, device/OS, text size and motion settings. Use the canonical build/screen/device/variant filename. Update affected visual-reference index entries with status and any remaining capture gap.>

| Check | Command or reproducible procedure | Result | Evidence |
| --- | --- | --- | --- |
| <core / build / interaction / visual / animation / actual VoiceOver / device> | <exact command or procedure> | <result or explicit gap> | <durable summary or artifact link> |

<Include relevant rule/save, interruption, accessibility, and visual/animation coverage. Group related checks; explicitly mark missing and inapplicable areas. A screenshot cannot verify motion; a build cannot verify play.>

## Findings and remaining risks

<Separate observations from inference. For bugs: reproduction, violated invariant/root cause, responsible boundary fixed, related paths actually examined, original and sibling regression results, residual risk. For experiments: comparison, counterevidence, adopt/revise/remove recommendation and register link. Omit branches that do not apply.>

<Assign follow-ups with a trigger and verification; link ENGINEERING.md or ROADMAP.md when updated. Keep failures and blockers visible.>

<For visual work, embed the relevant inspected capture beside its finding, with alt text and a source/environment caption; link the complete evidence record. Do not substitute a contact sheet for animation evidence. Optional reference: link raw output under ignored artifacts. Caption captures with source and context. Collapse long logs or supporting methodology, not conclusions.>
