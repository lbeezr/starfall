# Make Starfall easier to maintain and verify

**Status:** Accepted — implementation in progress · **Owner:** current implementer · **Updated:** October 19, 2026, Eastern time

Preserve Starfall’s existing safeguards while making current decisions easier to find, repeatable work easier to execute, and CI results more useful. Start with current-document reconciliation and a small instruction experiment; give remote CI diagnosis the first tooling priority. Add three repo skills only as their workflows prove useful.

**Important limit:** The latest 20 GitHub Actions runs sampled contain 11 failures and nine cancellations, with no completed pass. The newest cancelled run includes UI failures before cancellation. This is a planning audit, not a native reproduction or a finding that all failures share one cause. [Source-bound baseline](evidence/repo-maintenance-2026-10-19/README.md).

**Next action:** Implement batch 1 below, then diagnose the recorded CI failures without weakening coverage. Instruction/skill improvements can proceed independently of blocked Apple tooling. Current gameplay, save compatibility and canonical phone delivery remain authoritative.

## Scope and success

**Includes:** repository navigation, scoped `AGENTS.md` guidance, three proposed repo skills, instruction evaluation, maintenance triage and improvements to existing verification tools.

**Excludes:** gameplay changes, new app identities, schema migration, dependency/framework adoption, automatic deletion campaigns, new scheduled jobs and changes to personal Codex/plugin configuration. Future Murk/world design remains distinct from implemented gameplay.

- [x] Current entry points agree on fresh survival, retained saves, pacing, delivery and open RC acceptance.
- [ ] Every relocated instruction has an identified owner; root-started tasks find the applicable local guidance.
- [ ] Representative tasks preserve safety and correctness while reducing unnecessary reading or commands. Report observed results rather than promising a percentage.
- [ ] Each added skill has a narrow trigger, explicit output, positive/negative examples and a demonstrated repository use.
- [ ] Remote failure categories have exact source/run evidence; a full development matrix completes successfully before remote CI is called healthy.
- [ ] Any removal has consumer/compatibility evidence and the relevant unchanged-behavior checks. Historical mechanics are not removed because their names sound obsolete.

## Why this is the right adaptation

The [OpenAI maintenance article](https://developers.openai.com/blog/maintaining-software-with-the-gpt-6-family) recommends evidence-backed cleanup, small reviewable changes, measured CI improvements and controlled instruction comparisons. Its large-repository results are examples, not savings forecasts for Starfall. Our equivalent evidence is Git history, adoption decisions, save fixtures, Xcode membership, native results and delivery receipts; there is no reason to introduce production analytics or a feature-flag service.

The related [skills and prompts article](https://developers.openai.com/blog/rethinking-skills-and-prompts-for-gpt-6-astra) supports concise triggers and loading relevant instructions on demand. For this repo, that means preserving consequential invariants while moving detailed procedures to their existing owners. It does not justify dropping required tests, accessibility acceptance or installation safeguards.

## What the audit established

Baseline: clean checkout `548660b1f78e9d34775eb0ee601e91f146a898ac`. This review covered root/folder guidance, current registers, selected evidence, the primary CI workflow and its main helpers, and targeted runtime references. It was not a whole-program dead-code audit.

| Observation | Consequence for this plan |
| --- | --- |
| One tracked `AGENTS.md`, approximately 1,798 words; no tracked `SKILL.md` files | Reorganize existing knowledge before adding more instructions. Installed personal/plugin skills are a separate layer. |
| `ENGINEERING.md` has 470 lines / approximately 12,197 words and an existing active-risk index; 147 evidence folders predate this audit | Preserve the active index and source-bound history. Route readers to relevant sections instead of requiring a full archive read. |
| App and roadmap prose still describe automatic aging, while later passages retire it; an experiment row retains V2 pacing/delivery-pending language | Reconcile current summaries with `freshSurvival`, aging migration and adopted evidence. Preserve historical records with explicit status. |
| Largest app Swift file is `FallingSkyStore.swift`, 927 lines; largest Swift test file is 1,034 lines | No size-triggered app split is justified by this audit. Extract only when a change demonstrates coupled responsibilities. |
| CI already has path filters, one runner, cancellation, Debug/Release builds, source-counted matrices, stage timeouts and compact export | Extend existing owners. Do not propose another runner framework, blanket retries or a second test inventory. |
| Recent remote failures include inventory timeout and UI assertions; the latest run did not finish | Establish reliable completion and diagnosis before claiming speed or cost improvements. |

## Work in small batches

The user authorized implementation on October 19. The current implementer owns each batch and records separate verified commits; [batch evidence](evidence/repo-maintenance-2026-10-19/IMPLEMENTATION.md) tracks results and limits.

| Order | Deliverable | Done when |
| --- | --- | --- |
| 1 — current truth | Reconcile `App/README.md`, the current portions of `ROADMAP.md` and `EXPERIMENTS.md`; improve links from `docs/README.md` | Fresh/restored survival and historical Dusk are unambiguous; current cadence and open acceptance match code/evidence. Historical results and approved future story design remain intact. |
| 2 — CI diagnosis | Classify the sampled failures; reproduce the newest UI assertions on comparable tooling and investigate inventory timeout separately | Each issue has source, environment, failure mechanism or an explicit unknown, smallest regression and owner. Integrate independent verified fixes promptly; remote health remains open until the full matrix passes. |
| 3 — scoped guidance | Evaluate one instruction change, then shorten root guidance and introduce only useful nested files | The before/after comparison passes; an instruction relocation map shows no lost invariant; fresh sessions discover scope correctly. |
| 4 — reusable workflows | Introduce `starfall-verify`, `starfall-ci-triage`, then `starfall-maintenance` | Each passes its trigger examples and one real task. Skills reuse existing scripts and documents and do not create extra approval gates. |
| 5 — one cleanup pilot | Audit one bounded area of historical tooling or duplicated current documentation; implement at most one proven cleanup first | Consumer searches and history support removal; compatibility remains intact; the relevant checks pass. Unknown candidates stay documented. |
| 6 — measured tuning | Compare representative tasks and completed CI runs; optimize one measured source of waste | Quality/coverage is preserved and a measured benefit exceeds maintenance cost. Remove or revise guidance that does not help. |

Batch 3 can proceed while batch 2 waits for comparable Apple tooling; batch 4 follows the relevant proven procedure. The first cleanup pilot does not wait for unrelated RC physical-play acceptance, but must satisfy its own required checks.

## Give instructions one owner

Keep the root `AGENTS.md` as a short contract and navigation map. An initial editing target is roughly 700–900 words, subject to preserving meaning; word count is not the acceptance test. Retain product boundaries, deterministic ownership, save compatibility, one-app delivery, evidence honesty, integration hygiene and the minimum verification rule at the root.

Proposed local files carry only details specific to their boundary:

| Location | Local responsibility |
| --- | --- |
| `Sources/StarfallCore/AGENTS.md` | Rules/RNG, committed outcomes, replay, encoded compatibility and pure-core checks; links to package test ownership. |
| `App/AGENTS.md` | Main-actor state, clock/cancellation ownership, scene/presentation boundaries, common geometry/materials and native acceptance; links to AppTests and UITests. |
| `scripts/AGENTS.md` | Local versus disposable-runner commands, bounded process ownership, CI cost/triggers and canonical updater safeguards. |
| `docs/AGENTS.md` | Current versus historical authority, writing/templates, evidence provenance and screenshot selection. |

Add test-, tool- or artwork-specific files only if recurring mistakes justify them. Their existing READMEs and authoritative contracts remain useful; a file per folder would add maintenance without demonstrated benefit. Do not copy full policies into skills or move protected evidence/asset payloads just to make the tree look uniform.

Root guidance must explicitly route edits to applicable nested guidance. Codex’s documented startup discovery follows the path to the working directory, so a root-launched session must not be assumed to preload every child file. Verify root and subdirectory behavior in fresh sessions. Use ordinary nested `AGENTS.md`, avoiding accidental masking through `AGENTS.override.md`. [Official instruction discovery](https://learn.chatgpt.com/docs/agent-configuration/agents-md).

Keep a compact change-type verification table in `ENGINEERING.md` as the procedural owner:

| Change | Required evidence |
| --- | --- |
| Documentation/instructions only | Hygiene, whitespace/local-link checks; instruction-discovery or task evaluation when guidance changes. No unrelated app run. |
| Swift behavior | Hygiene, `swift test`, affected hosted/UI cases and simulator build; rule/save replay or migration coverage when touched. |
| UI/geometry/motion | Above, plus relevant native taps, interruptions, inspected layouts and full-motion evidence; lightweight development accessibility. |
| Routing/resources/build/Debug fixtures | Above as applicable, plus Release and target/resource membership. |
| Tooling | Affected Python/shell behavioral checks; real native scenario when Apple behavior changes. Preserve service packaging/lock/install tests for updater changes. |
| RC/delivery | Existing `DEVELOPMENT_BUILDS.md` gates; actual VoiceOver/minimum-OS/physical acceptance remain separate from the canonical delivery receipt. |

Clarify that generic “source changes” means the affected boundary; Python-only tooling edits need meaningful tooling checks, not an unrelated gameplay tour. This is a proposed clarification to evaluate, not permission to bypass today’s instructions.

## Add three repo skills, with narrow triggers

Use `.agents/skills/<name>/SKILL.md`, short `name`/`description` metadata and instruction-first workflows. This is the documented repository discovery location. [Official skills guidance](https://learn.chatgpt.com/docs/build-skills).

| Skill | Suggested trigger description | Inputs and reviewable output |
| --- | --- | --- |
| `starfall-verify` | “Validate a Starfall change or prepare development/RC evidence.” | Changed paths, source and intended stage → selected existing checks and a concise result record separating core/build/interaction/visual/VoiceOver/device evidence. Reuse native plan/export helpers. |
| `starfall-ci-triage` | “Diagnose a failed, cancelled or unexpectedly slow Starfall CI run.” | Run IDs and exact source → classified failures, relevant logs, bounded reproduction and proposed/fixed cause when authorized. Preserve assertions, counts and primary failures. |
| `starfall-maintenance` | “Audit a bounded Starfall area for stale experiments, unused code or duplicated ownership.” | Area and audit/fix scope → ranked candidates with callers, saved/resource contracts, evidence, uncertainty and smallest next change. Reuse the experiment/engineering registers. |

For each skill, keep its main file to purpose, required inputs, decision boundaries and expected output. Link the relevant script/docs rather than embedding a second implementation. Add scripts only for demonstrated deterministic work. Supply short folder READMEs according to the existing folder protocol; avoid copying the skill body into them.

Test both invocation and non-invocation: verification should match “validate this gesture fix,” but not “explain the game”; CI triage should match “investigate run X,” but not a copy edit; maintenance should match “audit the retired lab exporter,” but not a new feature. Test overlapping prompts so only the needed workflow loads. Installed iOS/SwiftUI/art skills supply specialist expertise when relevant; repo skills supply Starfall’s contracts and evidence routes.

Defer a delivery skill until the three starters show value. If later useful, it must wrap the canonical updater and require delivery intent; a generic verification task must never install an app. Likewise, defer a generic “repo manager,” prompt optimizer, mandatory multi-agent tree or scheduled sweeping bot. These are unnecessary for the initial rollout.

## Evaluate guidance instead of assuming shorter is better

Use the maintenance article’s controlled comparison: take one real task prompt and one repository snapshot, fix the model/effort and available tools, and change only one instruction. Compare correctness, behavior, tool calls, runtime and available token/cost data. Treat unavailable measurements as unknown. Keep outputs isolated from the active working tree and production app. [Comparison approach](https://developers.openai.com/blog/maintaining-software-with-the-gpt-6-family).

Start with the verification wording ambiguity above. Select a relevant prior Starfall session when implementation begins; this audit has not inspected session histories or established that an instruction caused unnecessary work. Then compare three small task classes: a current-doc correction, a bounded tooling fix and a rule/save compatibility review. Guidance removal must not lose applicable checks or compatibility protections. A shorter response alone is not a win.

Record source/tree, exact prompt, instruction diff, tool/plugin versions, model/effort, outcomes and limitations in one evidence folder. Use a fixed small number of comparisons, not repeated runs until a favorable result. If the changed instruction harms behavior, revert it. If the result is ambiguous, retain the rule and narrow the question. Revisit model-specific workarounds after a model change or a relevant failure, rather than on every task.

GPT-6.1 Sol Medium is a reasonable configuration to evaluate for bounded maintenance; escalate effort or compare Astra for difficult compatibility/dependency audits. This is a trial recommendation, not a change to the user’s configured model or an extrapolation of the article’s API costs to this account. [Article’s model comparison](https://developers.openai.com/blog/maintaining-software-with-the-gpt-6-family).

## Restore trustworthy CI before optimizing minutes

The [retained sample](evidence/repo-maintenance-2026-10-19/ci-sample.json) includes 20 runs, each with source, attempt, conclusion and URL. Three job logs were inspected. Two stop at the 30-second inventory boundary after core tests pass. The latest cancelled run records six failed UI methods before stopping; its artifact-upload step was skipped. Cancellation does not erase those assertions or prove their cause.

First collect comparable Xcode/OS/simulator conditions and diagnose inventory startup separately from missing controls, scroll readiness and gameplay assertions. Investigate budget exhaustion versus superseding-run cancellation from run metadata/logs; do not label all cancellations as flaky tests. Carry forward the existing compact-native fixes, but verify their remote behavior instead of reopening already resolved local issues by assumption.

Then measure job/phase duration, cancellation waste, test duration and failure rate across a stated window. Separate successful completion time from failed/cancelled elapsed time; the current sample has no successful-run median. Rank optimizations by observed runner minutes affected and implementation risk. Candidates to test include eliminating duplicate build work, shared launch/setup cost and preserving compact diagnostics earlier. No cache, parallel native execution, timeout increase or workflow split is accepted without measured cause and unchanged coverage.

Reuse `ci-simulator.sh`, `simulator-command.py`, `simulator-lifecycle.sh`, `native_test_plan.py` and `export_native_evidence.py`. Keep existing main-only/path-filter/cost policies unless separately justified. Do not launch paid/manual CI from this planning task. Tooling changes to `device-update.py` remain separate from gameplay and must retain exact-source main/signature/installed-identity checks.

## Make removal decisions from evidence

Start the pilot in `tools/mechanics`, where historical exporters, source patches and comparison records already have documented owners. Classify each candidate as current runtime, retained compatibility/regression, historical reproduction, active comparison, verified unused or unresolved. This audit identifies a useful investigation area, not an approved deletion list.

Before removing anything, inspect direct and indirect consumers: Swift calls, Codable fields/raw values, migration/replay paths, Debug launch/accessibility IDs, Xcode source/resource membership, bundled asset names, Python/shell wrappers and documentation commands. Check Git history and overlapping work. A zero-result text search cannot prove safety. In particular, retain historical gravity/Dusk/critical-mass readers and reset fixtures unless their compatibility purpose is explicitly superseded and verified.

For each candidate record: owner/status, current source, consumers examined, evidence and counterevidence, expected benefit, uncertainty, relevant tests and recovery commit. Prioritize a concrete defect or repeated maintenance burden over line-count reduction. Adopt a single verified cleanup, update the existing register, and retain concise historical provenance. Expand only if that pilot helps. Do not introduce a second experiment database.

## Risks and verification status

The principal risks are losing a safety invariant while shortening instructions, mistaking compatibility code for dead code, and turning incomplete CI into an apparent pass. The relocation map, representative task comparisons, old-save coverage and unchanged native count/failure gates address those risks. Physical comfort, actual VoiceOver and minimum-iOS RC acceptance stay open under their existing owners; this plan does not close them.

For this planning change, runtime rule/save, interruption, accessibility, screenshots, animation and device tests are **not applicable**: only documentation and a small CI metadata snapshot are added. No source, instructions, skills or CI settings are changed. The [audit record](evidence/repo-maintenance-2026-10-19/README.md) records document checks and read-only investigation limits. Implementation acceptance remains unchecked above.
