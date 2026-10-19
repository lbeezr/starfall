# Repository maintenance implementation

**Result:** Partially verified — batches in progress · **Owner:** current implementer · **Date:** October 19, 2026, Eastern time

The [accepted plan](../../REPO_MAINTENANCE_PLAN.md) is being implemented in separate batches. Documentation now distinguishes current survival and v8 saves from historical aging/gravity/V2 research. Native CI diagnosis, instruction evaluation and skill validation follow independently; remote CI is not yet healthy.

## Batch 1 — current documentation

Source: `548660b1f78e9d34775eb0ee601e91f146a898ac` plus the listed documentation changes. No app, core, test, resource or build configuration inputs changed.

Reconciled root/App READMEs, the roadmap and adoption register against `FallingSky.freshSurvival`, `SkySaveArchive` and stored preference defaults. Fresh survival uses V1 cadence and disables aging/Dusk supply; retained Dusk remains supported. Current archives write v8, preserve validated v3–v7 readers and reject invalid-current fallback. Labeled the V2 adoption document and old lab directions as historical. Repaired the split adoption-table formatting. Murk/twelve-location design remains separate from implemented gameplay.

Acceptance: current summaries agree with those code boundaries; hygiene and `git diff --check` passed; 541 local Markdown file targets and changed-document whitespace passed. Historical evidence payloads and their results remain unchanged. This is documentation reconciliation, not native behavior acceptance; runtime/visual/animation/VoiceOver/device checks are not applicable to this batch.

## Batch 2 — CI diagnosis and one regression

[The diagnosis](CI_DIAGNOSIS.md) classifies all available logs in the original cohort and records six local reproductions. The retained-Dusk restore regression now uses the existing isolated fixture: 177 core tests and 9 selected native tests pass, with no runtime change. Other UI failures, inventory startup and partial/empty screenshot output remain explicit open findings; this batch does not claim healthy remote CI.

## Remaining work

- Resolve the remaining CI/native findings recorded in the diagnosis; Xcode 27.1/iOS 27.0 differs from remote Xcode 26.3.
- Evaluate scoped instructions and validate discovery; preserve each relocated invariant.
- Add and forward-test the three repo skills using existing commands and source-bound artifacts.
- Pilot one proven maintenance simplification and report measured benefit or uncertainty.
