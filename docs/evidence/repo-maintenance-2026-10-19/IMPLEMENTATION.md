# Repository maintenance implementation

**Result:** Partially verified — batches in progress · **Owner:** current implementer · **Date:** October 19, 2026, Eastern time

The [accepted plan](../../REPO_MAINTENANCE_PLAN.md) is being implemented in separate batches. Documentation now distinguishes current survival and v8 saves from historical aging/gravity/V2 research. CI diagnosis and the retained-Dusk correction are merged; scoped instructions and repo skills have completed bounded validation. Remote CI is not yet healthy.

## Batch 1 — current documentation

Source: `548660b1f78e9d34775eb0ee601e91f146a898ac` plus the listed documentation changes. No app, core, test, resource or build configuration inputs changed.

Reconciled root/App READMEs, the roadmap and adoption register against `FallingSky.freshSurvival`, `SkySaveArchive` and stored preference defaults. Fresh survival uses V1 cadence and disables aging/Dusk supply; retained Dusk remains supported. Current archives write v8, preserve validated v3–v7 readers and reject invalid-current fallback. Labeled the V2 adoption document and old lab directions as historical. Repaired the split adoption-table formatting. Murk/twelve-location design remains separate from implemented gameplay.

Acceptance: current summaries agree with those code boundaries; hygiene and `git diff --check` passed; 541 local Markdown file targets and changed-document whitespace passed. Historical evidence payloads and their results remain unchanged. This is documentation reconciliation, not native behavior acceptance; runtime/visual/animation/VoiceOver/device checks are not applicable to this batch.

## Batch 2 — CI diagnosis and one regression

[The diagnosis](CI_DIAGNOSIS.md) classifies all available logs in the original cohort and records six local reproductions. The retained-Dusk restore regression now uses the existing isolated fixture: 177 core tests and 9 selected native tests pass, with no runtime change. Other UI failures, inventory startup and partial/empty screenshot output remain explicit open findings; this batch does not claim healthy remote CI.

## Batch 3 — scoped guidance and three skills

[Guidance evidence](GUIDANCE.md) maps every original safeguard to root/local owners. Root guidance is 785 words (from 1,798); total instruction text is 1,993 words, with detailed boundary guidance loaded as needed. A fixed two-variant check-selection comparison preserved save/native safeguards while omitting unrelated app checks for a Python-only change. This is decision evidence, not a cost or speed benchmark.

The three skills pass the skill-creator validator and actual Codex `skills/list` discovery from five working directories. Independent forward tasks cover all three workflows and six trigger/counterexample prompts. Existing commands and evidence owners are reused; no runtime/configuration/dependency/delivery change is introduced.

## Remaining work

- Resolve the remaining CI/native findings recorded in the diagnosis; Xcode 27.1/iOS 27.0 differs from remote Xcode 26.3.
- Pilot one proven maintenance simplification and report measured benefit or uncertainty.
