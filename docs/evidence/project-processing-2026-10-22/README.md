# Project processing diagnosis

**Status:** Native configuration inspected; service recovery and end-to-end acceptance outstanding · **Date:** October 22, 2026 · **Owner:** Factory coordinator · **Issue:** [#220](https://github.com/lbeezr/starfall/issues/220)

The native completion workflows are already enabled. No configuration defect or late In Progress overwrite was established, so no workflow was reset or replaced. The factory contract now checks service health before changing a stale card. **This is a diagnostic/process correction, not a demonstrated repair of GitHub's Project processing. #220 stays open.**

## Observations and source

Repository inspection used clean main `943862da8bf89ca86b8f1369c9536cac61cd2e4f` (tree `8daf8cf1df841e4947f4a4159c3698e81bb28ebb`). No app, Core, test, build, resource, save, rule or device-delivery input changed. The current batch changes only documentation; native/physical/VoiceOver acceptance is inapplicable and no such checks were run.

At 18:48 UTC the signed-in browser showed these existing workflows in [Starfall — iPhone & iPad](https://github.com/users/lbeezr/projects/1):

| Workflow | Actual inspected configuration |
| --- | --- |
| Item closed, `125467505` | Enabled; issues and pull requests; Set value: Done |
| Pull request merged, `125467506` | Enabled; Set value: Done |
| Pull request linked to issue, `125467509` | Enabled; Set value: In Progress |
| Auto-add, `125469438` | Enabled; new/updated matching items |

The fresh unfiltered canonical View 1 showed ten items, including #212, #213 and #215, where earlier checks showed only the original seven (#204–210). These three rows appeared without a new membership edit in this investigation. This is partial recovery, not proof that every newer issue is visible or that delayed status events have drained.

[GitHub's active incident](https://www.githubstatus.com/incidents/wq8305lppdc2), first reported at 15:28 UTC, overlaps the observed failures. Its 17:43 update explicitly reported queued Project updates still processing; at 18:26 other services had recovered while Projects remained under investigation. This supports a service-backlog explanation; it does not establish the precise cause or event ordering for each Starfall item. Earlier #229/#226/#233 manual Done changes remain manual evidence. #228 had shown Done without intervention; its canonical-row acceptance was not established by that issue-side observation.

Official [built-in automation documentation](https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/using-the-built-in-automations) confirms the native completion mechanism. The [linked-PR announcement](https://github.blog/changelog/2025-11-06-improved-onboarding-flow-for-github-projects/) supplies no event-order guarantee. Do not assert a competing-workflow race without a timeline showing one. The [Project status event schema](https://docs.github.com/en/graphql/reference/projects#projectv2itemstatuschangedevent) exposes prior/current status, time and whether the event was automated when a supported API is available.

The connected repository tools expose no Projects/GraphQL administration; the shell CLI is unauthenticated. No credentials were inspected/copied and no hidden browser networking was used. A new Actions workflow would not repair the current capability gap: GitHub [requires separate Project authentication](https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/automating-projects-using-actions), which the ordinary repository token does not provide.

## Acceptance still required

1. After service recovery, inspect a new factory leaf in canonical View 1 and compare its issue-side Project field and item identity. Deduplicate before any necessary reconciliation.
2. Observe a genuine fully resolving default-main PR merge, completed issue and automated Done transition on that same card without manual Done. Preserve actual times and distinguish a later overwrite if one occurs.
3. Resolve #220 through its fully resolving PR only when visibility and completion acceptance are met. Keep unrelated verified gameplay merges moving while this external dependency waits.

The durable [investigation comment](https://github.com/lbeezr/starfall/issues/220#issuecomment-6348677210) records the service-health discovery and fresh queue result. No synthetic issue or empty merge was created to manufacture completion evidence.

## Gameplay refill

An independent fresh queue/source pass found only #206–210, deferred #217 and active #220. It examined dialogue recovery/paused controls, mode-specific help, input admission/buffering, committed move feedback and feedback cancellation. No new source-backed player defect emerged. #206/#207/#209 need actual player/device evidence; #208 needs the minimum runtime; #210 depends on #206. No new native or hardware-blocked checks, speculative gameplay changes, or VoiceOver work were dispatched.

## Verification

Documentation batch on the source above plus only the six documentation paths in this PR: `python3 scripts/ci-hygiene.py` and `git diff --check` both exited 0. A targeted independent review found no blocking concern. Publication must preserve the reviewed documentation tree; existing native results belong to their original source-bound records.
