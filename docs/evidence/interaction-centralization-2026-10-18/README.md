# Centralizing input and interruption ownership

**Result:** In progress · **Owner:** current implementer · **Date:** October 18, 2026

Four independently verified PRs follow the merged gesture/Dusk refinement. Rules, saves, geometry and clocks keep their existing owners. This folder records the scoped evidence for each extraction; physical-device feel and actual VoiceOver are separate acceptance work.

1. Merged [PR #83](https://github.com/lbeezr/starfall/pull/83): [logical interaction session](session.md), trace/swap selection and exactly-once hold release ([issue #77](https://github.com/lbeezr/starfall/issues/77)).
2. Merged [PR #85](https://github.com/lbeezr/starfall/pull/85): [shared input availability](availability.md) ([issue #78](https://github.com/lbeezr/starfall/issues/78)).
3. [Interruption teardown](interruptions.md) ([issue #79](https://github.com/lbeezr/starfall/issues/79)).
4. Trace announcements through feedback ([issue #80](https://github.com/lbeezr/starfall/issues/80)).

**Next action:** Verify and merge each batch before implementing the next. Raw test output stays disposable under `/tmp/starfall-<batch>-*`; this folder keeps source hashes and compact results.
