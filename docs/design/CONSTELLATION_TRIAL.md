# Test diagonal constellations before changing the sky

**Status:** Superseded by selected-star tracing · **Owner:** current implementer · **Updated:** 2026-10-17

**Follow-up:** [The tracing design](CONSTELLATION_TRACE.md) supersedes whole-component taps. The user chose to clear only the stars actually traced; this document retains the initial comparison question.

Investigate whether five connected same-family stars make the terrace easier to read and provide useful clears. Keep the comparison in separately installed native apps: shipping rules, saves, the phone round and shower generation remain unchanged. More generous connectivity can merge independent choices, so a higher score alone is insufficient.

**Decision (user confirmed October 17):** count five actual stars, with grown stars contributing one star to eligibility and two starlight to score. Clear the whole connected constellation from any member; this takes precedence over contained ordinary groups. No tracing, charge or special power.

**Next action:** try Constellation Lab against Starfall Control on the iPhone; observe prediction errors and useful clear/wait choices before adopting or removing the rule. [Native comparison evidence and instructions](../evidence/constellations-native-2026-10-17/README.md).

## Proposed behavior

Tap any member of an eight-neighbor same-family component containing five or more actual stars to clear that entire component. This takes precedence over an ordinary group contained inside it, so every member gives the same result. Otherwise preserve the ordinary orthogonal three-starlight rule. This precedence is confirmed for the trial: it removes the ability to clear only an orthogonal subset. Compare that cost explicitly rather than silently mixing two outcomes by tap location.

Dark stars never connect families or count toward five. Only dark stars orthogonally beside the cleared component are removed, matching today's rule; diagonal darkness neither shades growth nor disappears. Existing column settling happens once; newly connected groups require another tap. Connections are recomputed from committed board cells after settling, never stored as persistent links or inferred from rendered positions.

The reported pink cells `(0,4), (1,3), (2,4), (1,5), (1,6)` are front-based core coordinates. Fixtures add contrasting support beneath elevated stars: this is a deterministic reproduction of the reported relationship, not a reconstruction of the whole phone board. No raw screenshot is retained.

## Acceptance defined before implementation

- Fixture fails ordinary eligibility and clears exactly five colored stars under the candidate from every member; four diagonal stars fail even when their value reaches five. Ordinary grown-plus-small clears remain legal.
- Orthogonal dark adjacency, diagonal dark exclusion, family boundaries, edges without wraparound, overlapping ordinary groups, one-time settling and invalid/terminal input have focused checks. Score, IDs, preview and RNG continuity survive clear/restore.
- Compare 200 seeds, six existing bounded policies and sixty showers; report dry periods, distinct choices, consequential choices and capped survival. On identical baseline-trajectory boards, measure new availability and lost independent choices. Do not treat different visited states as matched boards.
- Candidate clear detection must not change the generator's ordinary dry-board relief predicate. Board changes can still change subsequent forecasts; preserve the announced preview and RNG draw sequence through the clear itself.
- No app route or save namespace is needed for offline analysis. The native pair has distinct bundles/defaults suites and replay fixtures; never reset normal saves.
- Native adoption requires normal/rapid taps, restart, loss/First Light precedence, pause/settings/background interruption, full and reduced motion, Dynamic Type and actual VoiceOver focus/activation. These are unverified in offline tooling.

## Presentation and comprehension gate

Implemented only in the native candidate: quiet thin links behind eligible stars, using the shared cell projection. Use a spanning tree rather than every possible edge, keep faces unobscured and give eligibility a non-color cue. Preview/highlight and clear must resolve the same committed component. Recompute links only after settlement; no floating persistent chain. Tap remains a native button action with a spoken group count and collected value. VoiceOver and Reduce Motion must not depend on seeing links or timing a gesture. No geometry change is proposed.

A native paired session should ask the learner to predict the five-star clear, four-grown-star non-clear, overlap outcome, dark removal and post-settle result before tapping; record errors and explanations, not just success after coaching. Observe natural play without requiring immediate clears: an always-clear bot may remove opportunities before a constellation can form.

## Decision point

The named 200-seed comparison justified the user-requested native extension. Count versus value and precedence are resolved for this trial. After the iPhone comparison, adopt/remove or record one bounded remaining question. Adoption still needs useful observed clear/wait decisions and comprehension/accessibility evidence. Existing shower/Surge candidates remain separate experiments; no combined rule promotion follows from this trial.
