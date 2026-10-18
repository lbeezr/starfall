# Find useful choices in selected constellations

**Status:** Accepted bounded analysis · **Owner:** current implementer · **Date:** 2026-10-17

The user-selected tracing mechanic already lets players preserve stars. Before adding white or changing storm cadence, determine whether different legal selections have different useful consequences. This is a baseline of the existing isolated rules, not a new rule candidate.

**Question:** can two five-star traces worth the same light differ in column safety or the next available clear? Can spending five instead of a whole component preserve a better opportunity? More gesture paths to the same selected set do not count as additional decisions.

## Scope and acceptance before implementation

- Derive the exact selected-trace Core using the canonical `candidate_source` and `trace_core` transformations. Record committed production source and all analysis/transformation hashes; do not modify shipping Core, generator, saves or native app.
- Sample seeds 0–15 through shower 24 or overflow. Clear repeatedly after each shower under two fixed, future-blind policies: largest available whole/tap clear; and five-star trace choices plus ordinary taps, largest light first. Canonical cell-mask ties make each reproducible. Preserve policy-specific denominators; outcomes describe these policies, not optimal or human play.
- Enumerate unique connected sets of exactly five within eligible eight-neighbor families, plus whole eligible components and ordinary tap groups. Build valid bounded walks with retracing. Exclude six-through-intermediate-size selections from claims: this is not the complete action space. Cap each enumeration frontier at 512 and a state at 1,024 distinct choices; report capped states, exclude them from choice comparisons, and record a whole/tap fallback for the five-star policy.
- Compare same-value five-star choices on the identical source state. Record immediate score/column heights, then consequences through the already committed next shower and the largest available follow-up clear. This diagnostic reads a hidden preview; neither policy may use that lookahead. It does not establish player foresight or actual urgency.
- Validate every visited/compared committed state. Retain at most three strongest source-bound counterexamples with exact initial save, selected walks and expected outcomes. Round-trip and replay retained fixtures through their best follow-up; do not manufacture save counters or use authored layout boards as restorable saves.
- Check enumeration against known small graphs, de-duplication of tap/trace outcomes, valid walk construction, cap behavior and selected-set commits. Run existing package tests on the derived Core. No native gesture, interruption, visual/animation, accessibility, device or enjoyment claim follows from this offline tool.

## Decision point

If a reproducible difference exists, retain the smallest useful case for a prediction-before-input native comparison in the existing selected-tracing lab; introduce no additional phone app. If differences are absent or rare in this bounded sample, report that counterevidence before proposing pressure or a special star. A larger score, longer simulated round or more enumerated subsets does not establish satisfying cleverness or replayability.

## First native observation: bounded save and input bridge

Restore one naturally reached case into the existing selected-trace bundle on this task's private simulator only. Validate its exported runtime hashes against the published native Core and preserve the exact saved state; do not reset a phone or normal round. Append a test-only hosted bridge to stage that committed save, and a UI test to capture the app after ordinary restore. No App/Core/gesture source changes or new bundle identity.

Ask the familiar simulated tester to choose a first action from the screenshot without the retained alternatives, analysis report or hidden landing. If a trace is proposed, it may later be committed through the real store's selected-path API in the hosted bridge and its saved result shown natively. Label that as a logical/store action plus native visual outcome, **not a finger swipe, full-motion or actual VoiceOver test**. Gesture acceptance remains with the existing native/physical workstream. This observation tests whether the visible board supports the reasoning found offline, not cold human learning or enjoyment.

## Visible setup follow-up (acceptance before implementation)

Extend the same pinned sample with an immediate, pre-shower comparison. After a legal first clear, measure the best ordinary/whole-component follow-up on the settled board **before any arrival**. This reads only the starting board and deterministic gravity; preserve the existing post-shower diagnostic separately. Count states where a five-star subset beats its containing whole component over at most two immediate clears, and states where equal-value fives differ in their immediate follow-up. Retain at most one additional strongest natural-state fixture for the subset-versus-whole category, including the exact second action. Round-trip and replay without calling `letStarsFall` between those actions. Add a focused check distinguishing pre- and post-shower probes and verify that neither probe mutates its source. Keep policy decisions unchanged so earlier trajectories remain comparable.

If the strongest existing follow-up case needs an unseen arrival, explicitly withdraw it as evidence of a visible setup. If a visible benefit exists, use the existing private-simulator observation bridge for one prediction-before-action comparison. Otherwise report its absence in this sample and select a bounded rule refinement rather than coaching the tester with hidden outcomes. No new runtime rule, phone variant or save field is authorized by this analysis.

The first pre-shower run found zero subset-versus-whole gains in either policy; the retained seed4 example depends on the hidden next shower. Extend this same sample once to all states with multiple legal actions, including ordinary taps: compare each first action plus its best immediate follow-up with the largest-first action plus its own best follow-up. Count strictly smaller-first gains separately from equal-first-value move-order gains. Retain only the strongest additional smaller-first fixture; inspect the full alternative actions so a subset-only comparison cannot conceal an obvious dominating full clear. This is a two-clear horizon, not optimal play or deliberate waiting. If no smaller-first gain is found, record the absence and end this baseline extension without manufacturing a teaching example.

Retain at most one same-value pre-shower fixture as a positive replay check for the immediate follow-up probe, including its largest-first comparison. This verifies a nonempty second action even if no smaller-first gain exists. It is diagnostic evidence, not a reason to force a native teaching exercise.
