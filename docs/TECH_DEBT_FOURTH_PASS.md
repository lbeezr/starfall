# Preserve current feedback and stop timed-out simulator work

**Status:** Closed for scoped fixes · **Owner:** current implementer · **Updated:** 2026-10-18

Two concrete failures reproduced on main `99803b3`. Implement and ship each separately; preserve game rules, saved state, UI layout and existing CI budgets.

| Rank | Workstream | Acceptance criteria | Status |
| --- | --- | --- | --- |
| 1 — P2 | Stale automatic result | Retained seed 0, 23 showers with one available clear per shower, then automatic shower and independent clear: both completion orders retain the newest clear dialogue/speech, save and score. Duplicate and interrupted callbacks remain inert. | Merged — PR #129 |
| 2 — P2 | Primary CI timed-out descendants | A command spawning a delayed-writing child times out with status 124, stops its process group and leaves no later output. Preserve stdout, signal/error codes, timing receipts and owned simulator cleanup. | Verified; ready to integrate |

**Next action:** verify current-main canonical delivery and retain minimum-iOS, actual VoiceOver and physical-play RC gates. Apply process-group ownership to the separately documented RC/updater wrappers when touching those boundaries. Both scoped corrections pass their relevant tests; no layout/artwork change or new visual acceptance is required.

The first failure affects retained rounds that permit independent input during an automatic presentation; fresh critical-mass aging generally reserves occupied columns and did not reproduce this overlap. The second reproduction uses real parent/child processes, not mocked timeout results. Ordinary descendants inherit the new group; this is not a sandbox for processes deliberately escaping their session.

Evidence: [fourth-pass report](evidence/debt-fourth-pass-2026-10-18/README.md).
