# Opal choice opportunity study

Status: completed bounded analysis; native comprehension remains unverified; no rule or app change. Owner: current implementer.

Question: in seeded production histories, does preserving an existing Opal sometimes improve the next clear enough to repay a smaller or equal first clear? The shared-Orb fixture establishes one ordinary-follow-up example; this study must include traced follow-ups as well, so an omitted legal action cannot manufacture an advantage.

Scope before implementation: seeds 0–63, 24 showers, one visible-board action per settled shower, two deterministic policies (largest immediate reward; largest immediate reward with fewer Opals spent on ties). Each policy has its own trajectory and denominator. Decisions do not see hidden incoming columns. No real clock, gesture speed, animation or human preference is modeled.

Candidate first actions include every ordinary tap group, every whole diagonal family component, and connected five-star subsets. Deduplicate identical selected sets. Enumerate at most 256 partial sets per expansion/component and 512 actions per state; report capped states separately and exclude them from opportunity comparisons. This is complete only within this bounded action family, not an optimal strategy over every possible subset or full round.

For uncapped Opal states, compare candidate first actions with the largest-reward action from the identical committed state. Execute the best legal second clear both immediately and after the same committed shower. A best single-clear reward can be found from whole components and ordinary groups because all matched stars have positive value; verify every action through Core. Record immediate gains separately from hidden-forecast/oracle gains. A first-action wait is an oracle diagnostic only, never a trajectory policy; it sacrifices the first clear opportunity and may overflow.

Acceptance: valid committed Core states; colored trace anchors and bounded walks; identical-set deduplication; explicit cap checks; source probes cannot mutate their history; deterministic repeated output; source/tool hashes and separate policy counts; no inferred human enjoyment. Preserve positive and negative examples with replayable source states. Decision point: inspect the 64-seed results before tuning anything. If capped states dominate, improve the measurement before drawing a frequency conclusion. If apparent gains disappear with traced follow-ups, report that directly. Any held-out expansion must use a named fresh seed range.

## Discovery decision, before held-out sampling

Seeds 0–63 repeated byte-for-byte (raw report SHA256 `e7b9df8f84f689b3f53eae15286b5bfd38c9e9ae18908fd383b9f4a90c1fd104`). There were no capped states. The largest-immediate trajectory exposed 402 Opal decisions with a legal clear: ten had a smaller-first immediate gain and two had an equal-first immediate gain. These categories may overlap; do not add them as a unique-state count. Preservation also had counterexamples. Keep rules unchanged. Confirm with the named held-out range **64–127**, identical 24-shower/two-policy/action-enumeration method. The samples are correlated trajectories, not a population or human frequency estimate. Whole-component walks prove legality, not minimum gesture time; do not infer automatic-play feasibility from this untimed study.

## Decision after held-out sampling

Retain the approved rules. The smaller-first immediate advantage appeared in four of 388 eligible held-out states on the largest-immediate trajectory, and the tie-preservation score advantage did not repeat. See the [source-bound report](../evidence/opal-choice-study-2026-10-17/README.md). Main subsequently adopted faster cadence and refined tracing in `4aab6a7`; assess native comprehension and execution on that source or newer before tuning placement or frequency.
