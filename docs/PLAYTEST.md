# Round balance diagnostic and five-minute playtest

> Historical original-puzzle material. For the current default game, start with [the falling-sky roadmap](ROADMAP.md), [comparison playtest](PLAYTEST-FALLING-SKY.md), and [pacing evidence](evidence/falling-sky-pacing-2026-10-16/README.md). Earlier passes do not automatically validate falling sky.

## Decision this supports

Keep the provisional **70 jewels / 18 valid moves** unchanged until human play is observed. The deterministic sample shows a useful difference between two simple strategies, but does not establish that the game is fun, relaxing, fair, solvable on every seed, commercially viable, or likely to retain players. No rules or tuning were changed for this diagnostic.

## Executed diagnostic — 2026-10-16 11:23 UTC

Owner: round-balance diagnostic lane. Source workspace HEAD: `2c1deb4328402cf50fabedca56a9c93eaca68bf3`; the exact core file used was `Sources/StarfallCore/Game.swift`, Git blob `32cc17995b4d6530f5e130e9ef74be1b8f846d86`, SHA-256 `145b02ce1be99cd3c5855615eb674c11bf08273db87b0557f29af4d186e14142`.

A temporary Swift driver was compiled alongside that real core with the official Linux Swift 6.0.3 compiler, optimization enabled. It executed **4,000 complete rounds**, with `isValidSave` asserted after every accepted turn and a nonempty legal-action list asserted while playing. The program exited successfully. This is rules execution, not an iPhone playtest or rendering/performance measurement.

### Reproducible sampling and policies

- Same 2,000 starting seeds for both policies: integers 0–999, followed by `i &* 0x9E3779B97F4A7C15 &+ 0xD1B54A32D192ED03` for `i` in 0–999, with wrapping UInt64 arithmetic.
- Enumerate cells by ascending row then column. Row zero is the **bottom** of the board. Deduplicate connected components; each legal component needs at least three jewels.
- **First legal:** choose the first component in that enumeration. This is an intentionally weak, location-biased baseline, not a model of a beginner or random player.
- **Largest cluster:** choose the largest currently legal component, retaining the first component on ties. No lookahead, future-RNG inspection or search.
- Stop when the actual core returns won or lost. Record terminal score, valid moves used, `Turn.reshuffled` occurrences and turns with more than one distinct legal component.
- Repairs counted below are **after turns**; an initial `ensureMove` correction is not separately observable through the public initializer and is not counted.

Temporary driver SHA-256: `556d50f0c7a4722aa99b5403f476653a719d438004489bc82d1f808b762bd0e7`. Raw results JSON SHA-256: `82dd5b26de5423b55bc4abcdc8529d16a71faccd4b83ba4b5e3f0237bb319744`. These identify this local diagnostic's inputs/output; they are not claims that the raw files are published in the repository.

| Metric | First legal | Largest cluster |
| --- | ---: | ---: |
| Wins / 2,000 | 904 (45.2%) | 1,266 (63.3%) |
| Mean terminal score | 68.05 | 69.47 |
| Score min / P10 / median / P90 / max | 56 / 63 / 69 / 72 / 81 | 58 / 65 / 70 / 73 / 82 |
| Mean moves used, all rounds | 17.65 | 17.16 |
| Moves min / P10 / median / P90 / max | 13 / 17 / 18 / 18 / 18 | 11 / 15 / 18 / 18 / 18 |
| Mean moves used by winners | 17.22 | 16.67 |
| Rounds with a post-turn repair | 1,358 (67.9%) | 1,229 (61.45%) |
| Mean post-turn repairs / round | 1.64 | 1.48 |
| Maximum post-turn repairs / round | 11 | 11 |
| Turns offering >1 legal component | 69.63% | 72.06% |

Percentiles use sorted observations at zero-based indices 200 and 1,800; medians are the middle-pair average. Scores are terminal and may overshoot 70. Winning rounds stop early, so means are not fixed-18-turn scores.

The sequential-seed cohort yielded 43.5% versus 61.6% wins; the dispersed cohort 46.9% versus 65.0%. Across paired seeds, both policies won 694, only first-legal won 210, only largest-cluster won 572, and both lost 524. Seed 42 is illustrative: first-legal scored 64 and lost; largest-cluster scored 73 in 17 moves and won.

### Interpretation and limits

- The largest-cluster policy wins **18.1 percentage points** more often in this sample. That suggests immediately visible choices can matter; it does not prove deep strategy or human agency.
- Greedy selection is not uniformly better. Different choices produce different board/refill histories; paired seeds share an initial state, not identical future boards. These two policies do not search all legal play sequences. Neither their losses nor the 524 joint failures prove an impossible seed.
- Most rounds reach or nearly reach the move limit. No measured play duration follows: animation, reading, deliberation and human taps are absent from the simulation.
- Repairs are common. The existing message, “A fresh cluster appeared. No extra move used”, should be tested for comprehension. Do players notice what changed, understand that the repair itself is free, and still feel in control? A high repair rate alone is not a defect or authority to change the rule.
- This fixed seed sample is a diagnostic, not a population estimate, confidence interval, difficulty target, retention metric or release gate. Broader or optimal-policy analysis would be a separately scoped investigation if human evidence makes it useful.

## Five-minute moderated human playtest

Use an authorized, identified build and device/simulator; record source SHA, build, device, OS, date, motion setting and whether the person has seen the game before. Do not invite testers or distribute a build without the required approval. No analytics or recording service is needed; handwritten observations suffice. Stop at five minutes even if no terminal result occurs.

1. **0:00–0:30 — First impression.** Show the board with its normal instructions. Ask: “What do you think you do here, and what are you trying to achieve?” Do not explain the matching rule before their answer. Note shape/color recognition and whether target/moves are understood.
2. **0:30–2:30 — Uncoached play.** Ask them to play and say what they are choosing. Note their first valid clear, invalid taps, any uncertainty about adjacency, and whether a clear/settle feels responsive and pleasant. If they get stuck, record the point before giving the smallest hint.
3. **2:30–3:30 — Choice and recovery.** Ask: “What makes one move better than another?” If a free repair occurs naturally, ask what they think happened and whether it cost an extra move. Do not force one or describe a simulation result as their experience. Record “not observed” if none occurs.
4. **3:30–4:30 — Ending or resuming.** If a round ends, observe whether the outcome and New game action make sense. Otherwise use Menu and Continue, then ask whether the remaining task is clear. Do not make the player hurry to force an ending.
5. **4:30–5:00 — Debrief.** Ask: “What felt most satisfying? What felt confusing or frustrating? Would you choose another round right now, and why?” Record their words and whether they voluntarily start again; do not lead with “relaxing” or suggest the desired answer.

### Compact observation record

- Build/source/device/date:
- First-time or returning player; motion setting:
- Rule and goal understood unaided / smallest hint needed:
- Shape/color/touch issues:
- Chosen strategy, if any:
- Repair observed and understood / not observed:
- Terminal state reached and understood / not reached:
- Most satisfying moment; most confusing or frustrating moment:
- Voluntary replay behavior and reason:
- Concrete defect or proposed small change, tied to the observation:

**Next permitted transition:** the coordinator reviews actual observations against existing native acceptance evidence, chooses at most one bounded improvement, obtains independent review and reruns proportionate exact-head tests. No additional mechanics, target change or monetization follows automatically from this diagnostic. Accessibility audits, actual VoiceOver use, physical-device responsiveness and sustained retention need their own evidence.
