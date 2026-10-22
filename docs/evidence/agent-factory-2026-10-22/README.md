# Agent factory scaffold verification

**Status:** Pre-merge scaffold checks pass; throughput trial pending · **Date:** October 22, 2026

The [factory contract](../../AGENT_FACTORY.md) and [repo skill](../../../.agents/skills/starfall-factory/SKILL.md) establish bounded delegation, disjoint writes, continuous integration and GitHub completion. The optional [offline helper](../../../scripts/agent_factory.py) checks task graphs, exported native closing relationships and the [workstream/role catalogue](../../GAME_WORKSTREAMS.md). No scheduler, new Actions workflow or app behavior is added.

## Source and checks

Base source: `7a6dee86be1eacbec3b029a233df1684980119ce` (merged PR #200). Initial working tree was clean. This record describes the implementation working tree over that source: root/agent guidance, GitHub templates, factory documentation and indexes, an illustrative JSON plan, and the two factory Python files. No app, Core, resource, build-setting, native-test, updater or existing CI inputs changed. Environment: local Apple Silicon macOS, Python 3.9.6, Codex CLI `0.163.0-alpha.11.1`. No simulator or physical device was used.

Before publication, current main advanced to `2ffa561acbdfd2748d7d83d6c362abe04c24d94d` (PR #201). The workflow commit rebased cleanly, preserving its navigation changes and README/ENGINEERING corrections. The user then requested comprehensive labeling/role coverage and clarified iPhone/iPad as primary, with Mac deferred. The follow-up adds `.github/game-workstreams.json`, the tracking contract, a generated readable catalogue, task-packet guidance and a read-only catalogue export. Checks below were repeated on the combined workflow inputs; this change's app/native input delta remains empty.

| Check | Command/procedure and result |
| --- | --- |
| Behavioral helper checks | `python3 scripts/test_agent_factory.py`: 15 tests pass, no skips. Covers DAG release, transitive ordering, conflicting writers, invalid paths/graphs, WIP/resources, invalid completion claims, native closing links, wrong base, cross-repo number collisions, extra closing links, merged/completed versus open/not-planned issues, truncated/error responses, read-only CLI exit behavior, unique role ownership, available-only label export and reproducible catalogue generation. |
| Role/label catalogue | `python3 scripts/agent_factory.py catalog .github/game-workstreams.json`: 29 streams, 292 roles, 34 available labels; iOS/iPadOS primary, macOS deferred. Future/excluded streams stay outside exported labels. No live labels or Project fields were installed. |
| Runnable example | `python3 scripts/agent_factory.py plan docs/templates/AGENT_PLAN.json --integrated contract`: selects tooling and guidance independently. This is a planning example, not an actual parallel execution. |
| Skill syntax | Installed `skill-creator/scripts/quick_validate.py .agents/skills/starfall-factory`: pass with `PYTHONPATH=/private/tmp/starfall-skill-validation-deps`. Initial system-Python run lacked PyYAML; the existing disposable dependency directory supplied it without a repo dependency change. |
| Real discovery | Fresh app-server `initialize` → `skills/list`, `forceReload: true`, for root, App, Core, scripts and docs. All five return `starfall-factory` enabled with repo scope and no repo errors. Initial sandbox initialization failed on the existing Codex SQLite state; a permitted retry passed. No model turn, settings change or user chat was created. |
| Hygiene/diff | `python3 scripts/ci-hygiene.py` and `git diff --check`: pass. Explicit staging and final diff are reviewed before integration. |
| Links/ownership | Local Markdown targets and maintained-folder ownership checked for this batch; the new skill and evidence folders have front doors. |
| Apple checks | Not applicable: no Swift/native/build/resource inputs change. No claim of Apple, visual, animation, VoiceOver or device validation. |

The discovery script and raw response remain disposable under `/private/tmp/starfall-factory-discovery*`. The evidence is the actual catalog response, not an assumption from the skill filename. Rendered Markdown/Mermaid appearance has not been visually inspected; local targets and source structure were checked.

## Representative instruction decisions

Manual contract review, not an independent-agent or automatic-trigger accuracy experiment:

| Scenario | Expected decision under the implemented contract |
| --- | --- |
| Small copy correction | One agent; existing checks; no graph or planning approval. |
| Two independent source investigations | Bounded read-only subagents; compact result packets. |
| Workers touch the same store or save schema | One owner or a real dependency; no concurrent writes hidden behind separate branches. |
| Independent files depend on an unsettled interface | Settle the interface first; path separation is insufficient. |
| Two returned patches await integration | Drain integration before dispatching more. |
| Worker returns passing checks | Review actual diff/source and integration evidence; returned does not mean merged. |
| PR targets a feature branch or closes only a partial parent | Keep leaf/parent acceptance open; put fully resolved leaf references on the final default-branch PR. |
| Issue closed but Project card stale | Repair/inspect Item closed automation and reconcile the specific card within authorization. |

## Live integration limits

The connected GitHub tools confirm repository default branch `main`, no open issues at the initial audit, and the five most recent merged PRs (#196–#200) without closing keywords in their descriptions. That sample does not diagnose older pileups or establish Project workflow configuration.

The connector does not expose native closing-reference queries or Project workflow administration. The documented `gh api graphql` fallback could not run because this shell's GitHub CLI is unauthenticated. No credentials were inspected or copied. The helper's closure cases use explicit fixtures; they do not establish a live merge event, Project Done transition or the live query's successful execution. GitHub's documented native closure/automation remains the implementation mechanism.

[Issue #202](https://github.com/lbeezr/starfall/issues/202) tracks this real scaffold outcome, including the expanded role/label design. Its resolving default-branch PR is the live merge/closure exercise; use that issue's native timeline and resolving PR for the post-merge result. This pre-merge snapshot does not claim that later event has happened. The multi-task throughput trial remains separate from publishing this scaffold.

No live Project settings were edited. No claim of faster delivery is made. Run the next three authorized multi-task batches under the [bounded trial](../../AGENT_FACTORY.md#trial-and-revisit); record actual queue wait, WIP, conflicts/rework, issue-closure delay and stale cards in each batch's evidence. Revisit at the third batch or the first recurring failure.
