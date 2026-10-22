# Live factory tracking and the first iPhone/iPad coverage audit

**Result:** Tracking configured; source/evidence audit complete; product acceptance remains open in six issues · **Owner:** Factory coordinator (`lbeezr`) · **Date:** October 22, 2026

All **34 available labels** are live, preserving the ten existing labels. The private, repository-linked [Starfall — iPhone & iPad Project](https://github.com/users/lbeezr/projects/1) automatically imports open issues and mirrors native completion/reopening. It uses Todo, In Progress and Done, plus P0–P3 Priority; the board displays labels and sorts by Priority. There is no human approval column or required plan sign-off.

Three independent read-only workers examined gameplay/content, UI/accessibility and engineering/release. The coordinator reconciled all **29 catalogue streams**, deduplicated existing work and created [#205–#210](https://github.com/lbeezr/starfall/issues?q=is%3Aissue%20is%3Aopen%20sort%3Acreated-asc). The clearest software gap is older full-round native tests still expecting manual tap matches in new arrangement-only Story visits. This audit did **not** run those tests or establish a native failure. Human comprehension, physical touch reliability, sustained performance and minimum-OS acceptance remain unperformed evidence tasks.

**Next action:** Execute [#205](https://github.com/lbeezr/starfall/issues/205) first. Prepare the player/device tasks independently; implementation of conditional arrangement practice waits for the study's evidence. This batch ends at configured tracking and prioritized task packets, without implementing the new game backlog.

## Priorities and dispatch

Each issue names its primary stream, supporting roles, observable acceptance, dependencies, exclusions and default-branch closure contract. All six were automatically added by `github-project-automation`; none was manually added to simulate intake. All six have the native Priority field, platform labels and one primary workstream/kind. `lbeezr` is the accountable coordinator, not a claim of available specialist staffing; record the executing worker when claimed.

| Order | Issue and outcome | Primary home / required expertise | Readiness and completion boundary |
| --- | --- | --- | --- |
| P1 / first software work | [#205 — Current Story full-round regression paths](https://github.com/lbeezr/starfall/issues/205) | QA; gameplay/save compatibility and VoiceOver testing | Reproduce/classify the stale normal and accessible scenarios; exercise current arrangements and explicit retained rules without weakening win/count/skip assertions. Actual VoiceOver retains its RC stage. |
| P1 / prepare independently | [#206 — Current player comprehension and physical swaps](https://github.com/lbeezr/starfall/issues/206) | User research; touch/input, game design, participants | Prepare a short current-mode protocol, then obtain actual phone/tablet observations. Unavailable players/devices remain missing evidence. Existing [PR #60](https://github.com/lbeezr/starfall/pull/60) is a reuse candidate, not an automatic stale-branch merge. |
| P1 / prepare independently | [#207 — Sustained device budgets](https://github.com/lbeezr/starfall/issues/207) | Performance; frame pacing, memory, thermal/energy, technical art and device QA | Define bounded dense-board/map scenarios and budgets before measurement; record actual iPhone and iPad results separately. Diagnose any lost input window before optimizing. |
| P1 / dependent acceptance | [#208 — Minimum iOS 17 release evidence](https://github.com/lbeezr/starfall/issues/208) | Release; Apple platform, compatibility QA | Environment discovery can proceed; corrected full-round acceptance depends on #205. Missing runtime is explicit; a newer OS does not substitute. |
| P2 / planned evidence | [#209 — Physical contrast and restoration recognition](https://github.com/lbeezr/starfall/issues/209) | UI/UX; HUD, low vision, environment art and device QA | Inspect only named risk states, measure composited contrast and obtain physical recognition evidence; make a narrow fix only if demonstrated. |
| P2 / conditional | [#210 — Arrangement practice decision and bounded slice](https://github.com/lbeezr/starfall/issues/210) | Game design; onboarding, UX writing, gameplay, accessibility and research | Depends on #206; preserve the uncoached baseline. Existing Tutorial intentionally teaches Open Sky. A justified no-change/deferral decision is valid; do not assume a new tutorial is necessary. |

P0 is empty because this pass reproduced no urgent product failure. Priority indicates sequencing, not proven defect severity. `needs:device` identifies a real evidence dependency, never a human merge-approval stage. Keep device tasks separate from routine software acceptance so scarce hardware does not stop unrelated work. Mac remains deferred.

## Source and audit limits

Audited clean source: [`8e63ed5178679832ef77c580d947f7364207dd25`](https://github.com/lbeezr/starfall/commit/8e63ed5178679832ef77c580d947f7364207dd25). There were no build-affecting dirty inputs. Workers made no edits, issued no GitHub mutations and ran no Apple workloads. The coordinator alone owned live configuration, issue creation and shared documentation changes. Final publication changes documentation/skill instructions only; app, Core, test, resource and build sources remain unchanged.

The pass inspected current owners and retained evidence, rather than every file or every one of the 292 functional roles. Code and screenshots establish neither staffed capacity nor player enjoyment. All unrecorded staffing, hours, budget, effort and due dates remain **Unknown**. Missing evidence is not proof of a broken feature or absent employee. No per-role issues, speculative AAA features, network dependencies or in-app analytics were created.

The audit used one coordinator plus three workers, with overlapping reads and disjoint responsibilities. Peak worker WIP was three; no additional work was dispatched while returns awaited reconciliation. There were no worker write conflicts because all workers were read-only. Individual return wait and elapsed research timings were not retained and are Unknown. This is a completed parallel coverage audit, **not** one of the three implementation-throughput comparison batches.

## Findings that determine the first tasks

### Current rules and older full-round scenarios disagree

[`FallingSkyStore.startChallenge`](../../../App/FallingSkyStore.swift#L925) starts a fresh current challenge. New Lantern/Ribbon revision-3 visits use automatic arrangements; manual tap/trace activation is disabled. Yet [`SkyFlowInteractionTests.testFirstLightWinReplayAndFullSky`](../../../UITests/SkyFlowInteractionTests.swift#L92) and [`FallingSkyInteractionTests.testFirstLightGoalCompletionRestoreReplayAndSurvival`](../../../UITests/FallingSkyInteractionTests.swift#L217) search the old “toward a tap match” value while expecting a Lantern win. The [`fullFirstLight` actual-VoiceOver sibling](../../../UITests/ObservatoryInteractionTests.swift#L301) follows the same strategy. The current [`WorldJourney` regression](../../../UITests/WorldJourneyInteractionTests.swift#L453) proves tap immutability and swap scoring, but does not replace those full-round boundaries. The [minimum-OS runner](../../../scripts/rc-platforms.py#L15) selects the older full-round path.

This is source-confirmed test drift, not a newly executed failing test. #205 must reproduce/classify it, inspect siblings and repair fixture/scenario ownership before altering app behavior. Preserve explicit historical save/replay contracts. Accessible move custom actions already exist in [`FallingSkyView`](../../../App/FallingSkyView.swift#L509); actual VoiceOver cannot be replaced with coordinate drags.

### Human and physical evidence trails development verification

[Story-pattern evidence](../story-patterns-2026-10-20/README.md) separates deterministic wins from comprehension, recoverability, decision time and enjoyment. Model policies took 86 Lantern / 118 Ribbon swaps, with substantial setup and unused full-line opportunities; those are diagnostic observations, not human difficulty measurements. The [first-play protocol](../../design/FIRST_PLAYTEST_PROTOCOL.md) still targets retired Debug 70-in-18 play. #206 updates the observation target without bundling balance tuning or adding telemetry.

The touch implementation has size-dependent swap acquisition, hold intent and cancellation boundaries. The [engineering register](../../ENGINEERING.md) still calls for physical short/off-center/rapid-stroke and interruption evidence. A reported failure rate has not been measured under a controlled current-build observation. Combine this with the current study rather than opening duplicate gesture queues.

[Living-light evidence](../living-starlight-2026-10-20/README.md) retains an initially lost input window followed by unchanged passes. The cause is unresolved. Its nominal raster byte count is not a measured process/GPU footprint. The [map motion/resource sample](../ui-adversarial-2026-10-20/expanded-motion-resources.json) is bounded Simulator evidence. #207 measures sustained physical behavior before speculative optimization.

Minimum-iOS evidence remains absent; [`rc-platforms.py`](../../../scripts/rc-platforms.py) correctly refuses a newer-runtime substitute. #208 depends on the current-scenario repair. Named physical readability risks remain in the engineering register: warm Sunwheel controls, Kite's 75% cue, Seed's 25% root/pearl cue, Silver's bright foreground/“Next shower”, and bright HUD/guidance/menu states. #209 verifies those states rather than declaring a contrast defect from code alone.

## Coverage across all 29 workstreams

Applicability describes this product and phase, not the catalogue's availability flag. In this table, “Active” means implemented work/evidence was found; it does not mean every specialist role is staffed or all acceptance passed. Functional homes and all 292 roles remain in the [canonical catalogue](../../GAME_ROLE_CATALOG.md). Cross-disciplinary issue packets name the subset actually needed.

| Workstream | Applicability / source evidence | Gap, next action or revisit trigger |
| --- | --- | --- |
| Direction and production | Active: bounded factory, issue ownership, live Project and current roadmap | Coordinator owns queue/integration. Staffing, effort and dated available capacity are Unknown; estimate them when an actual milestone/resource decision requires it. |
| Game and systems design | Active: versioned deterministic rules, two current arrangement locations, retained legacy rounds | #206 tests comprehension/balance; #210 considers practice only if warranted. Keep model results distinct from enjoyment. |
| Narrative and writing | Active: approved atlas/cast, local authored dialogue and typed copy | Later lore/cinematic expansion is deferred. Check voice, repetition and comprehension at the next player study; no new content roster now. |
| Level and world design | Active: seven ready restoration locations; Lantern/Ribbon revision 3, other visits retain their definitions | Observe journey selection and current first visits in #206 before extending the rule roster. No inference that all seven share new rules. |
| Art direction and visual development | Active: approved expressive Story cast and faceless gameplay identity, production kits | Retain direction; physical recognition in #209 and budgets in #207 precede artwork expansion. |
| Environment and prop art | Active: 105 restoration paintings across seven locations, registered state geometry | #209 covers named recognition risks. #207 covers actual residency/frame budgets; asset count is not a capacity estimate. |
| Character and creature art | Active: Story portraits/cast and bounded character materials | No new character need established. Preserve separation from gameplay identity; revisit on an authorized character/story outcome. |
| Animation and cinematics | Active: finite/cancelable motion, quiet behavior, sampled map/presentation motion | Physical recognition and sustained motion remain #206/#207 evidence; no capture/cinematic staffing assumed necessary for this 2D scope. |
| Effects and motion graphics | Active: committed clear receipts and bounded flight/celebration effects | #207 covers dense sustained behavior; #206 observes distraction/feedback. No speculative particle or renderer rewrite. |
| Interface, HUD and interaction | Active: native layout/fallbacks, shared UI owners and parity evidence | #209 verifies actual readability; keep iPad portrait/landscape and large-text coverage explicit. |
| Audio, music and voice | Active: eight local cues, latest-request ownership, mute/interruption behavior | Actual speaker/headphone comfort and interruption perception remain unassessed. Revisit in the next physical acceptance session or an observed audio issue. No voice production commitment. |
| Gameplay and simulation engineering | Active: deterministic Core, explicit stores, versioned committed saves/replay | No new Core defect established in this pass. #205 must preserve current versus historical rules and restore invariants. |
| Engine and rendering | Active: committed SpriteKit presentation, shared shaders/material cache | #207 measures physical budgets; no engine migration justified. |
| Technical art and asset integration | Active: registered geometry, native asset membership, bounded caches and authored production contracts | Raster estimates are not residency measurements; #207/#209. No speculative asset family expansion. |
| Apple platforms and device interaction | Active: touch/hold/cancellation, lifecycle and native rotation paths | #206 physical comfort/reliability; #208 minimum OS. Tablet resized-window acceptance is unassessed, not a confirmed bug or new support promise. |
| Performance, memory and energy | Active with material missing acceptance: sampled native evidence, no sustained current device profile | #207 owns the largest physical engineering gap. Record budgets before judging measurements. |
| Developer tools, build and automation | Active: CI, canonical updater, source-counted inventories, offline factory helper | RC/updater direct-child timeout ownership remains an existing debt trigger: next RC/deployment-tooling change. Keep each tooling fix separate and prove descendant cancellation. No new CI jobs. |
| Quality assurance and test engineering | Active with source-confirmed test drift | #205 is first software-ready work. Test inventory is derived from source, never copied into a permanent static checklist. |
| Playtesting and player research | Active need; current-mode physical observations missing | #206 owns evidence. Participant availability and research capacity are Unknown. Agents may prepare/analyze, never impersonate players. |
| Accessibility and inclusive play | Active: native semantic controls, non-color identity and RC VoiceOver contract | #205 includes stale full-round actual-VoiceOver scenario; #209 physical low-vision/recognition. Actual assistive-technology evidence stays distinct from element exposure. |
| Localization and cultural adaptation | Deferred language expansion: English-only authored scope is explicit | Not a defect or an active translation queue. Revisit on an authorized locale: resource selection, plural/font/expansion/RTL and native locale evidence. |
| Release, packaging and distribution | Active development delivery; broader RC acceptance incomplete | #208 and existing RC/device/VoiceOver boundaries. Use canonical phone updater only if delivery is requested. No deployment-target increase. |
| Security, privacy and trust | Active offline controls: local-defaults privacy declaration, no tracking/data collection or third-party SDK/network imports found in inspected owners | Static scope check, not a security certification. Revisit when persistence, privacy, dependencies or an explicitly authorized network surface changes. |
| Marketing, community and player support | Planned for distribution; current product identity/icon evidence exists | Store metadata, audience/support readiness and staffing not fully assessed. Trigger: an explicit distribution milestone; do not add accounts/analytics to manufacture coverage. |
| Studio operations, rights and people | Applicable; authored-asset provenance guidance exists in Artwork | Actual budget, staffing, specialist availability and complete rights review remain Unknown. Trigger: asset admission, contributor engagement or distribution decision; no fabricated capacity claim. |
| Nearby multiplayer and cooperative design | Future, explicitly requested direction | Preserve local iPhone/iPad versus/co-op intent. Separate implementation task required before network code; no backend/accounts implied. |
| Online accounts and service infrastructure | Excluded | Offline scope; no backlog or labels activated. Revisit only after a new explicit product request. |
| Commerce and monetization | Excluded | No ad/IAP SDKs, entitlements, tracking or monetization UI. Any future opt-in product requires its separate target contract. |
| Live service and product analytics | Excluded | No analytics/live-operations system or speculative staffing queue. Local development evidence does not authorize product telemetry. |

The consequential coverage risk is **missing current human/device acceptance**, with an immediately actionable test-scenario mismatch. This pass cannot quantify underinvestment: demand and available hours were not supplied. At the next refill, record effort ranges and actual available time/resources only for the selected batch; compare waiting and required acceptance, not label counts or lines of code.

## Live GitHub configuration and completion proof

| Setting | Observed configuration |
| --- | --- |
| Labels | 34/34 available definitions from `.github/game-workstreams.json`, including 25 workstream labels; ten prior labels preserved; 44 total active labels. Reserved Mac/multiplayer and excluded-service labels not created. |
| Project | Private Project #1, repository-linked, default repository `lbeezr/starfall`; README records autonomy, bounded WIP and scope. |
| Intake | Auto-add to project, only `starfall`, open issues filter `is:issue is:open` (UI prefixes its standard `is:issue,pr`). Existing matching setup issue and all six new leaves appeared automatically. |
| Item added / reopened | Status Todo. Reopened workflow explicitly enabled. |
| PR linked to issue | Status In Progress; enabled. |
| Item closed / PR merged | Status Done; both enabled. The issue card is the durable completion record. |
| Sub-issues | Native auto-add enabled; no parent/child hierarchy created merely for display. |
| Reverse Auto-close issue | Disabled. Card motion cannot silently claim unresolved acceptance. Default-branch closing references close verified leaves. |
| Human review workflows | Code-review approved / changes-requested workflows disabled. No extra required Actions check, privileged event bot or approval column added. Existing relevant verification still applies. |
| Queue metadata | Priority P0/P1/P2/P3; six leaf values verified. Board sorted ascending by Priority, with labels visible. Phase, Effort and Risk stay in task packets until useful. |

GitHub's [built-in automation documentation](https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/using-the-built-in-automations) supports native event-to-Status workflows. The setup used the connected GitHub tool for issues/PRs and the existing signed-in browser for labels and Project workflow administration, which that connector does not expose. No token, GitHub App, dependency or GitHub Actions service was added.

Real setup issue [#204](https://github.com/lbeezr/starfall/issues/204) is the merge/Done acceptance case. Its documentation PR must contain `Closes #204`; the six product leaves remain open. Final verification of issue closure and automatic Done is retained in the setup PR's post-merge receipt so the evidence does not require a self-referential follow-up commit. Before merge, #204 was observed automatically imported in Todo; its PR link should move it to In Progress. Do not manually close it or move its card to simulate this proof.

Prior scaffold [PR #203](https://github.com/lbeezr/starfall/pull/203) already closed its real issue #202 on default-branch merge; that established native issue closure, not Project automation. This batch adds the live Project acceptance.

## Verification and remaining limits

| Documentation/skill check | Result |
| --- | --- |
| `python3 scripts/ci-hygiene.py` | Pass; tracked-file hygiene and Core UI-import guard. |
| `git diff --check` | Pass. |
| `python3 scripts/test_agent_factory.py` | 15 tests pass, zero skips; existing helper behavior unchanged. |
| `quick_validate.py .agents/skills/starfall-factory` | Pass with `PYTHONPATH=/private/tmp/starfall-skill-validation-deps`. Initial system-Python attempt lacked PyYAML; the existing disposable directory supplied it without a repo dependency change. |
| Local Markdown targets | 806 relative targets exist across the 11 changed/new Markdown documents; external URLs and fragment semantics are separate. |

Exact published tree and final integration checks belong in the setup PR receipt. No Swift, app resources, routing, test source or build configuration changed, so Core/hosted/UI/build workloads were not run for this tracking batch. No native game appearance or runtime documentation rendering was validated by this audit.

Live checks: label names/colors/descriptions were entered from the canonical export; all available names were present, total 44. Repository link, private visibility, saved default repository, Priority options/values, workflow toggles/target values and issue intake were inspected through the browser. Screenshots were retained as small task artifacts and inspected; they establish GitHub UI state, not game appearance, animation, VoiceOver or device behavior. Secrets/session data were not read or exported. Existing native Actions runs were not dispatched, retried or used to invent new failures.

Throughput remains unmeasured. The factory operates in the active session and does not keep running after it ends. Adding a recurring scheduler is a distinct request; live GitHub intake/completion continues independently through native Project workflows. Current player/device, actual VoiceOver and minimum-OS evidence remain in their real acceptance tasks without becoming human approval stages for routine development.
