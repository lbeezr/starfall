# Centralizing input and interruption ownership

**Result:** Verified development checks · **Owner:** current implementer · **Date:** October 18, 2026

Four independently verified PRs follow the merged gesture/Dusk refinement. Rules, saves, geometry and clocks keep their existing owners. This folder records the scoped evidence for each extraction; physical-device feel and actual VoiceOver are separate acceptance work.

1. Merged [PR #83](https://github.com/lbeezr/starfall/pull/83): [logical interaction session](session.md), trace/swap selection and exactly-once hold release ([issue #77](https://github.com/lbeezr/starfall/issues/77)).
2. Merged [PR #85](https://github.com/lbeezr/starfall/pull/85): [shared input availability](availability.md) ([issue #78](https://github.com/lbeezr/starfall/issues/78)).
3. Merged [PR #86](https://github.com/lbeezr/starfall/pull/86): [interruption teardown](interruptions.md) ([issue #79](https://github.com/lbeezr/starfall/issues/79)).
4. [Trace announcements through feedback](feedback.md) ([issue #80](https://github.com/lbeezr/starfall/issues/80)).

**Next action:** Observe physical gesture/haptic feel at the next device playtest; perform actual VoiceOver acceptance at RC. Raw test output stays disposable under `/tmp/starfall-<batch>-*`; this folder keeps source hashes and compact results. Each implementation is published through its own PR, preserving the tested tree.
