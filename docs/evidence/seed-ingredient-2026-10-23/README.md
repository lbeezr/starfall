# Seed Moon: spend or preserve a grown ingredient

**Status:** Integrated development verification in progress · **Issue:** [#279](https://github.com/lbeezr/starfall/issues/279) · **Date:** October 23, 2026

New Seed visits select revision 4: 23 stars, 24 light, one visibly grown aqua ingredient and an announced 11,000-point objective. Spending it in a four-star line earns 6,000 immediately; moving it into the five-star arrangement earns 8,000 after setup. Complete ordinary routes finish at 11,000 and 13,000. One ignored shower leaves both finishes available; the preserve route reaches 14,000 through naturally grown rose light. Waiting does not raise the already-grown aqua star's value.

This adapts the [seven-place curriculum](../../design/STORY_ENCOUNTER_CURRICULUM.md) and [Puzzle League reference](../../design/POKEMON_PUZZLE_LEAGUE_REFERENCE.md) into a distinct ingredient choice. The 2,000-point first-clear difference includes an additional star and the existing pattern-size bonus; it is not a new grown-star multiplier. These are separate depth-one clears, not a causal chain. Ordinary legal alternatives can win; no required order, shower, or minimum duration is added.

Historical Seed0 remains manual/18-light on Continue and same-round Replay; nonexistent Seed1–3 reject. Explicit new visits select Seed4. The existing archive13, seeded supply, scoring, clocks, scene, paintings and journey owners remain authoritative. Seed completion earns immediate Silver access; Silver's new sequencing encounter is a separate subsequent slice.

## Verification and limits

Computed runtime input `dev.a7fb00d69e` starts from merged main `b41a623c633d22dc9248e4fcdfc5bb505be1452f`; actual local test bundles use `dev.local`. [Verification](verification.json) records exact input hashes, commands and results. Raw logs and result bundles remain under `/private/tmp/starfall-next-encounters-20261023/`.

The full Core suite passes 257 tests with zero failures/skips. The initial sandboxed invocation could not write the existing compiler cache; the authorized execution passed. Core coverage includes full-state equivalence of moving the grown aqua before the first shower versus after it, 14,000-point recovery, replay, old-save admission and immediate terminal behavior. Catalogue validation passes 457 keys, 103 scripts and 108 unique line IDs; all 100 previous scripts remain unchanged.

Native/hosted, Release, visual and final integrated acceptance remain in progress. The first automatic-shower native route reached the Seed win, then its new helper incorrectly compared the entire spoken ceremony sentence with the bare live-HUD score label. The same mistake affected the persisted result comparison. The test-only correction keeps an exact delimited numeric score slot in the ceremony; outcomes and targets are unchanged. Preserve the failed run separately from its rerun.

Uncoached player recognition, comfort and enjoyment, physical-device play, minimum-OS and actual VoiceOver acceptance are not performed here. VoiceOver stays deferred. No physical device was probed or installed.
