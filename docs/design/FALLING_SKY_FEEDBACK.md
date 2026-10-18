# Turn observed play into the next gameplay improvement

**Status:** Accepted bounded development task · **Owner:** current implementer · **Updated:** 2026-10-17

Opal, storms and gravity are already integrated. Their rule studies establish possible choices; they do not establish that people notice, enjoy or replay them. Make the existing falling-sky protocol executable without fitting its observations into the obsolete 70/18 puzzle schema.

**Next action:** Use the [moderator worksheet](../../tools/playtest-results/FALLING_SKY_SESSION.md) for uncoached play before selecting another mechanic or tuning change. The blank recorder and local summary are implemented; browser visual/interaction review is unverified because local-file navigation was denied. No participant result is available yet.

## Scope and success

- [x] Record installed source/build verification, saved generation/cadence, new/retained/prepared sky, device/settings and participant familiarity. Do not infer installed source from repository HEAD.
- [x] Separate human from synthetic evidence, distinct people from repeat sessions, natural play from prepared boards, and exact build/settings cohorts. Blank sessions and missing assessments cannot become failures or participants.
- [x] Separate seeing Opal from having a choice, deliberate spending/preservation from a matching tap, before-action prediction from hindsight, and speed changes from group/order changes in storms.
- [x] Count independent replay only when time was available and the player actually starts; keep stated interest and prompted starts separate. Input failures remain visible alongside strategy observations.
- [x] Reject contradictory records, duplicate sessions, unknown fields and malformed source/type values; preserve the original classical tooling and its historical rules.
- [x] Provide a short moderator worksheet with neutral prompts, no participant-facing answer key, and a bounded decision after the first three uncoached people. Three people are a pilot, not a statistical preference claim.

## Verification and boundaries

Use fictional temporary inputs to check missing-data denominators, identity/repeat handling, source/cohort separation, prompting, replay opportunity, strict validation and CLI round trips. Run the existing observation suite and repository hygiene. This is local developer tooling: no app instrumentation, analytics, dependency, network, save reset, new app or gameplay mutation. Rule/save, native interruption, game animation and actual VoiceOver acceptance are not applicable to this tooling change; prior native evidence does not validate the tool or human enjoyment.

The initial task started at stale source `f35eba8` and duplicated a connector experiment that newer main already superseded. Its temporary code was removed before integration. A mixed simulator run showed the other mechanics build and cannot establish acceptance. Continue from current main, keeping this task focused on feedback rather than creating another mechanic variant.
