# Preserve current feedback and stop timed-out simulator work

**Status:** Accepted · **Owner:** current implementer · **Updated:** 2026-10-18

Two concrete failures reproduced on main `99803b3`. Implement and ship each separately; preserve game rules, saved state, UI layout and existing CI budgets.

| Rank | Workstream | Acceptance criteria | Status |
| --- | --- | --- | --- |
| 1 — P2 | Stale automatic result | Retained seed 0, 23 showers with one available clear per shower, then automatic shower and independent clear: both completion orders retain the newest clear dialogue/speech, save and score. Duplicate and interrupted callbacks remain inert. | Verified; ready to integrate |
| 2 — P2 | Timed-out descendants | A command spawning a delayed-writing child times out with status 124, stops its process group and leaves no later output. Preserve stdout, signal/error codes, timing receipts and owned simulator cleanup. | Reproduced; pending |

**Next action:** correct presentation ownership, run focused and native regression checks, integrate it, then correct subprocess lifetime and run execution tests. Source changes require Core/hosted tests, simulator build, hygiene and diff checks. Native coverage includes ordinary motion, rapid input, outcomes/replay, interruption, settings and Reduce Motion. No layout/artwork change: new visual acceptance is inapplicable. Actual VoiceOver, minimum iOS and physical play retain their separate RC gates. Canonical updater verifies physical installation after integration.

The first failure affects retained rounds that permit independent input during an automatic presentation; fresh critical-mass aging generally reserves occupied columns and did not reproduce this overlap. The second reproduction uses real parent/child processes, not mocked timeout results. Ordinary descendants inherit the new group; this is not a sandbox for processes deliberately escaping their session.

Evidence: [fourth-pass report](evidence/debt-fourth-pass-2026-10-18/README.md).
