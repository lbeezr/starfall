# Track game-development coverage without multiplying task queues

**Status:** Tracking design and validated catalogue; live labels/Project configuration not installed · **Updated:** October 22, 2026

**Primary targets are iPhone and iPad, using the current iOS 17+ app.** Mac/Mac mini support is a deferred porting assessment. The goal is broad production coverage and a high quality bar, not a commitment to a different engine, a larger game, every AAA feature or hundreds of staff.

The [catalogue](GAME_ROLE_CATALOG.md) covers **29 workstreams and 292 functional roles/specialisms** across the development lifecycle. Its [machine-readable source](../.github/game-workstreams.json) defines **34 available labels**, including 25 workstream labels. Four conditional streams remain visible in the inventory: nearby multiplayer is future work; online services, commerce and live-service analytics are excluded from the current product. A listed role is not automatically needed, staffed or authorized. Studio titles vary; this is a comprehensive responsibility inventory, not a universal list of every possible job title.

**Next action:** For the next authorized batch, choose its primary workstream and required roles, identify owners/evidence gaps, then execute through [the factory loop](AGENT_FACTORY.md). Provision labels as real work needs them. Do not open 292 role issues or 29 standing implementation queues merely to populate a board.

## Keep four things distinct

| Dimension | Meaning | Example |
| --- | --- | --- |
| Workstream | Accountable home for an outcome | Interface, HUD and interaction |
| Role | Expertise or responsibility required to deliver it | HUD designer, UI engineer, accessibility QA specialist |
| Task | Bounded, independently mergeable outcome | Make the paused HUD readable at the largest text size on phone and tablet |
| Evidence | Observable acceptance for that outcome | Native controls exercised, captures inspected, actual VoiceOver checked at its required stage |

One person or agent can cover several roles; a role can contribute to many streams. Each role has one primary catalogue home so omissions can be audited, while task packets name all relevant contributors. The primary workstream follows the delivered outcome and accountable owner, not whichever file extension dominates the diff. A cross-disciplinary slice stays one coherent issue when it has one merge boundary. Dependent content/engine contracts still need explicit ordering.

Avoid permanent “designer”, “programmer”, “tester” agent silos with handoff approvals between each. Ask a worker to deliver a concrete slice with the necessary perspectives. Use an independent specialist when a real uncertainty, acceptance risk or missing expertise warrants it. Agents can assist with production; performer rights, human taste, player experience, consent, business decisions and actual device/accessibility evidence retain their real owners.

## Label vocabulary

| Family | Values | Use |
| --- | --- | --- |
| `workstream:` | The 25 available primary homes in the catalogue | Exactly one per tracked leaf task; supporting roles go in its packet. |
| `kind:` | `feature`, `bug`, `research`, `maintenance`, `verification` | One describes the outcome; change it if the task changes. Content/asset implementation can be a feature. |
| `platform:` | `ios`, `ipados` | Add only when device-specific behavior or required acceptance matters. A shared task can use both. `macos` is reserved for an explicit future assessment. |
| `needs:` | `decision`, `device` | Temporary actionable gaps, with a named question/check and next action. Remove when resolved. These are not approval stages. |

The catalogue command exports available label definitions, including colors and descriptions, without applying them:

```sh
python3 scripts/agent_factory.py catalog .github/game-workstreams.json
python3 scripts/agent_factory.py catalog .github/game-workstreams.json --format labels
python3 scripts/agent_factory.py catalog .github/game-workstreams.json --format markdown > docs/GAME_ROLE_CATALOG.md
```

Reuse or rename an existing equivalent label when adopting this vocabulary; search before creating duplicates. Apply labels to issues through the connected GitHub tools within the requested task. Do not delete existing labels or bulk-relabel historical issues as incidental cleanup. No label is created by these commands, and reserved/excluded labels are omitted from the export. The role catalogue is generated from one source; tests check reproducibility and unique primary role ownership.

Keep **Status, Priority, Phase, Milestone, Effort and Risk** as Project fields or existing milestone metadata, rather than creating combinatorial label families. Initial values can be:

- Status: Ready, Working, In review, Done; blocked work carries its actual blocker/next action.
- Priority: P0 urgent failure, P1 next outcome, P2 planned, P3 optional/deferred. Priority is separate from defect severity.
- Phase: Discovery, Preproduction, Vertical slice, Production, Alpha, Beta/RC, Release, Maintenance. These describe work maturity, not permission gates.
- Risk: Low, Medium, High, Unknown. Effort and available capacity are estimates with a date, unit and range; Unknown stays unknown.

When no Project is configured, use a short issue packet and existing milestones instead of simulating every field with labels. The issue's native open/completed state remains authoritative, with [merge closure driving Done](AGENT_FACTORY.md#completion-follows-github). A label must never determine whether an issue auto-closes.

## The coverage review

At planning time, and when an observed gap changes the next batch, inspect applicable workstreams using the following small register in the existing plan. It records responsibility and capacity; task progress remains on linked GitHub issues.

| Field | What to record |
| --- | --- |
| Applicability | Active, Planned, Deferred, Not applicable, or Unassessed, with a reason. “Available” in the catalogue does not mean Active. |
| Accountable owner | The actual person or coordinator responsible; unrecorded ownership is Unknown, not assumed coverage. |
| Required roles | The subset needed for the current product/phase, with each covered, missing or unassessed. A 2D game need not staff groom/capture/destruction roles. |
| Demand | Linked outcomes, rough remaining effort range and the milestone they serve. No speculative backlog for excluded features. |
| Capacity | Available human time and agent slots for this batch, plus exclusive native/device resources. A list of agent names is not a capacity estimate. |
| Flow | Running tasks, returned tasks awaiting integration, oldest wait and blocked duration/cause. |
| Evidence gap | The missing source-bound acceptance and who/what can supply it. |
| Next action | One bounded task, a staffing/reallocation decision, or an explicit deferral with a revisit trigger. |

Distinguish the resulting signals:

- **Unowned:** an applicable outcome has no accountable owner.
- **Uncovered:** a required role or required acceptance has no credible provider/evidence.
- **Capacity risk:** estimated demand exceeds recorded available capacity before its milestone; incomplete estimates mean Unknown.
- **Bottleneck:** work waits persistently at a scarce reviewer, integration boundary, simulator or device. Reallocate to drain that boundary before adding more upstream workers.
- **Intentionally deferred/not applicable:** a documented product decision, not a resource failure.

Do not infer underinvestment from issue counts, lines of code, number of assets, agent tokens or a stream having no tickets. Three difficult accessibility tasks can need more capacity than twenty copy edits. Compare like-for-like effort, waiting and acceptance. These are local production measurements; no in-app analytics, tracking SDK or network telemetry is introduced.

The first pass need not fill every box. Record Unknown explicitly, then investigate the most consequential missing coverage. No new review ceremony blocks an otherwise complete low-risk task. Coverage review feeds the next decomposition rather than becoming another approval queue.

## iPhone and iPad coverage that needs explicit owners

Apple's [handheld interface guidance](https://developer.apple.com/videos/play/meet-with-apple/243/) emphasizes flexible screens, legibility and touch interaction. Its [Games Pathway](https://developer.apple.com/games/get-started/) separates device capabilities, graphics, input and distribution. Use these to define work that desktop-oriented role lists can miss.

| Coverage | Primary home; supporting responsibilities | Observable acceptance |
| --- | --- | --- |
| Small/large phone and iPad layouts | `ui-ux`; HUD design, native UI, level composition, accessibility and QA | Board/control hierarchy, readable copy, safe-area/occlusion behavior and actual hit alignment across intended orientations/text sizes. iPad is a first-class layout, not a scaled phone screenshot. |
| Touch and interruption behavior | `platform-input`; interaction design, gameplay, haptics and native QA | Rapid input, gesture cancellation, multitouch, Settings/background/resume, audio interruption and committed save integrity on applicable devices. Controller/keyboard support is a separately scoped capability. |
| Sustained play | `performance`; rendering, asset budgets and device QA | Measured frame pacing, responsiveness, memory, energy and thermal behavior in a reproducible real-device session. Simulator builds cannot establish this. |
| Inclusive play | `accessibility`; UX, audio, native controls, disabled-player research and QA | Non-color identity, readable text, quiet/full-motion equivalence, focus/activation and actual VoiceOver at the repository's required development/RC stage. |
| Language and cultural readiness | `localization`; UX writing, fonts, narrative, audio and locale QA | Supported-language scope declared; externalized copy, expansion/font/locale/RTL handling when relevant and inspected localized states. English-only scope is an explicit decision. |
| Local state and trust | `gameplay-engineering`; privacy, save QA and release engineering | Deterministic outcomes, retained-save/replay compatibility, interruption recovery and no unauthorized data collection. |
| Shipping | `release`; build/signing, compliance, marketing assets, support and QA | Intended distribution path, correct identity/signature, honest compatibility claims, source-bound RC evidence and approved delivery. Current phone updates keep the canonical updater. |

Apple's [WWDC26 performance session](https://developer.apple.com/videos/play/wwdc2026/388/) reinforces measuring long sessions across device conditions. Its newer tooling does not raise this game's minimum OS, require Metal 4, or authorize a renderer migration.

## Initial Starfall gap signals

This is a prioritization starting point from existing evidence, not a staffing audit or a statement that the listed roles are absent:

| Signal | Workstreams to examine | Bounded next question |
| --- | --- | --- |
| Arrangement rules have model/native evidence while human balance remains open | Game design + user research | Can players explain setups, recover mistakes and enjoy repeated new Lantern/Ribbon visits? [Current evidence](evidence/story-patterns-2026-10-20/README.md). |
| Native UI samples do not establish all actual VoiceOver/physical acceptance | Accessibility + QA + platform | Which required RC/device checks still lack current-source evidence? Use [the engineering register](ENGINEERING.md), not a new universal test list. |
| Dense-board appearance is sampled; physical sustained performance remains separate | Performance + technical art + QA | Who owns a measured session on the supported hardware, and what issue does it reproduce? [Living-light limits](evidence/living-starlight-2026-10-20/README.md). |
| Seven restoration locations are delivered and five remain unbuilt | Level design + environment art + narrative + integration | Which next authorized location has a complete content/native-asset contract? No automatic content expansion is implied. [Roadmap](ROADMAP.md). |
| Ownership/capacity across the larger role inventory has not been measured | Production | Which functions are needed for the next milestone, who covers them, and which are deliberately out of scope? |

No current-source claim of insufficient staffing, localization failure or distribution unreadiness follows solely from this inventory. The first resource review should separate missing evidence from missing implementation and missing ownership.

## Conditional work stays visible without entering the ready queue

Nearby versus/cooperative restoration is a user-requested future direction, deferred until its own implementation task. Online accounts/backends/matchmaking, monetization and live-service analytics remain excluded. Commerce roles are retained only to make the broader industry coverage explicit; a future monetized product still requires a separately authorized opt-in target and dependency boundary. This inventory authorizes none of those features.

For a future Mac/Mac mini discussion, first assess native iPad-on-Mac compatibility versus an explicitly chosen desktop build, keyboard/mouse/controller interaction, windowing/fullscreen, display behavior, sound, sustained performance, signing/distribution and regression effort. Mac mini is hardware within the macOS platform, not another workstream. Do not add Mac release gates, a new target, an engine rewrite or universal support claims before that assessment and a user implementation request. tvOS/visionOS are also outside the current targets.

## Research and maintenance

Sources checked October 22, 2026: [ScreenSkills games careers](https://www.screenskills.com/job-profiles/browse/games) supplies broad production/design/art/technical/audio/programming/QA families; [IGDA's discipline groups](https://igda.org/sigs/) highlight research, writing, localization, accessibility, credits, business and other easily missed functions. The detailed 292-role grouping is this repository's authored synthesis, including conditional specialists, rather than a copied staffing model or a claim that all studios use these titles.

Keep the JSON catalogue authoritative. Regenerate the readable catalogue after changing roles; retain one primary home per role. During the factory's three-batch trial, assess whether labels distinguish real outcomes and whether the register exposes actionable gaps. Merge/split a stream only when repeated ambiguous ownership warrants it. Add labels when used, and keep the default ready queue bounded regardless of catalogue size.
