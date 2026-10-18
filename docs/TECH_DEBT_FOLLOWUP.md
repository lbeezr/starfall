# Ship the six follow-up debt fixes

**Status:** Accepted · **Owner:** current implementer · **Updated:** 2026-10-18

Fix the six ranked findings from main `5ba0d36` in separate verified batches. Preserve deterministic rules, saved-generation contracts and single-app delivery. Each task ships when ready; unrelated release-environment limits remain explicit.

**Next action:** ship RC failure handling, then finish the remaining UI tasks.

| Task | Observable acceptance | Status |
| --- | --- | --- |
| 1. Exact contact clock | Zero-duration contacts do not extend opening/regular/retained/challenge deadlines; real held time, stale tickets, pause/background grace and no catch-up remain correct. | Verified |
| 2. Tablet Welcome | Original largest-text Settings activation passes with native hit semantics; diagnose orientation/scroll siblings and inspect source-bound screenshots. | Pending |
| 3. Semantic saves | Impossible overflow and duplicate forecast identities are rejected; current and retained valid-save/replay corpus remains accepted. | Verified |
| 4. RC failures | Primary test failure survives cleanup; partial evidence is retained/exported with bounded storage and execution tests. | Pending |
| 5. Help context | Welcome/Entry and game help describe pending/current rules for fresh, retained Dusk and First Light without implicit defaults. | Pending |
| 6. Recovery feedback | Rejected-save replacement and encoding failure have clear accessible feedback; backup/precedence/read-only initialization and clock/input contracts remain intact. | Pending |

Source batches run Core, affected hosted/native checks, hygiene/diff and simulator builds. Routing/resources/fixtures also require Release. UI batches update the selected capture index. Actual VoiceOver remains deferred to RC. No iOS 17 runtime or physical-device acceptance is inferred from newest-OS simulator results; only the canonical updater may deliver the phone app. Raw logs/results remain ignored or temporary; durable summaries live in [follow-up evidence](evidence/debt-followup-2026-10-18/README.md).
