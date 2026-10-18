# White connector rule trial · October 17, 2026

[Acceptance and hypothesis](../../design/WHITE_CONNECTOR_TRIAL.md) were written before implementation. The candidate is an isolated pure-core patch, with no production spawning, presentation or save changes.

## Observed results

All 70 package tests passed (61 existing, nine candidate checks). Two authored fixtures establish different useful choices:

- **Hold:** clearing the aqua connection now earns three; preserving its shared white connector through the announced amber arrival permits an amber clear worth four. Both use one shower and one clear and leave the same occupied count.
- **Spend:** a smaller aqua/white clear frees a full column and survives the announced arrival. Taking the larger rose/white clear consumes that same connector while leaving the threatened column full; the arrival overflows.

Other focused checks cover competing families, valid colored tap anchors, invalid white-only taps, growth, dark adjacency, boundaries, overflow, committed-arrival save round trips and malformed saves. Layout-only fixtures are not restorable saves.

Forty ordinary seeds under two policies, through 24 showers or overflow, produced **2,917 byte-identical encoded states** against baseline `202aabb50d83bf7c94c210dfa34f8a35b48880d5`. This bounds regression evidence to that sample; it is not an exhaustive equivalence proof. The candidate's app target also compiled in Debug for an arm64 iPhone 17e / iOS 27.0 simulator. It was not installed or launched.

## Decision

Retain this exclusive-connector rule for a bounded native comparison: both named decision fixtures passed. Do not adopt it into production or combine it with storm/constellation rules yet. Rule consequences do not establish understandable choices, enjoyment or replayability. Native presentation, animation, interruption, actual VoiceOver, Reduce Motion and human preference are **unverified** for white stars. Existing presentation would not distinguish them correctly. A native trial needs a distinct visual/non-color identity and a separate save contract before launching.

Reproduce with `python3 tools/mechanics/check-white-connector.py`. [Source manifest](source.json) records baseline, patch/tool hashes, exported workspace, raw package log and simulator build log. The only dirty inputs are the named design/tool/test/patch files; the runner archives the committed baseline and explicitly overlays the patch and tests. No unrelated working-tree edits enter its candidate.
