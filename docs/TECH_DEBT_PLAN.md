# Ship seven independent debt reductions

**Status:** Accepted · **Owner:** current implementer · **Updated:** 2026-10-18

Address the source review at `be75cc5` in separate verified batches. Preserve gameplay, save compatibility and the one-app delivery contract. Ship completed batches without waiting for unrelated acceptance work.

**Next action:** separate historical gravity and neutral settling/presentation in task 5.

## Scope and success

| Task | Acceptance criterion | Status |
| --- | --- | --- |
| 1. Save recovery | Rejected current/old/wrong-type saves survive activation; valid saves and migration remain unchanged; errors are observable. | Shipped: PR #108 |
| 2. Native failures | Reproduce First Light outcomes and mixed-order Dusk motion; preserve assertions and record cause or remaining uncertainty. | Shipped: PR #109; historical cause still unknown |
| 3. Coordination | Extract pure turn-dialogue and cohesive presentation reservations with equivalent behavior and stale-completion coverage. | Shipped: PR #110 |
| 4. Input cost | Measure representative dense admission/trace work; remove demonstrated repetition without speculative caching or weaker commit checks. | Verified: 78.4 → 3.7 ms sample |
| 5. Historical mechanics | Isolate historical gravity logic; neutral shared collapse/settling ownership; old-save replay remains green. | Pending |
| 6. Build gates | Add bounded Release automation and explicit minimum-OS/tablet RC coverage, preserving Actions cost policy. | Pending |
| 7. Active register | Short current debt index distinguishes active, closed and historical findings and links closure evidence. | Pending |

Each task gets a separate commit/PR and source-bound evidence. Source changes require Core, affected hosted/UI checks and simulator build; routing/resources/configuration also require Release. Actual VoiceOver remains deferred to RC; routine batches are development builds. Physical-device enjoyment and minimum-OS behavior cannot be inferred from simulator results. No new gameplay, dependencies or networking.
