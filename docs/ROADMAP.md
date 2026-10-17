# Starfall roadmap

Updated October 16, 2026, Eastern time. This is the current roadmap for **falling sky**, the default game in Debug and Release. The [original-puzzle roadmap](archive/ROADMAP-original-puzzle-2026-10-16.md) is historical. Earlier game-bible and playtest documents describe the original puzzle unless explicitly updated for falling sky.

## Product direction

A small, readable, satisfying falling-sky puzzle worth replaying. Keep the 7×7 board, five jewel kinds, orthogonal matching worth 3+, growth, dark stars, automatic showers, pause, manual next shower, and local balance controls. Preserve full falling animations, with accessible reduced-motion alternatives.

No progression, power-ups, backend, accounts, analytics, ads, purchases, paid assets, or external SDKs. The original 70-jewel/18-move puzzle stays available for Debug regression testing; its rules do not govern falling sky.

## Current baseline

- Falling sky is the default. New skies offer a first-shower match; matching runs help dry boards when a low column has room. Existing saves retain their previous sky-generation rules.
- Faster comets, manual next shower, paused clears, matching-group outlines/count, clear rings/score popups, and optional local sound/haptics are implemented.
- One optional First Light challenge is implemented: fixed seed 42, 18 starlight, steady showers and no dark stars; entry starts a new round from Settings. This is a single objective prototype, not a campaign or unlock system.
- Local evidence at the published pacing tree: 56 core tests, 14 falling-sky store tests, seven UI checks and a Release simulator build passed. Checks include real system Reduce Motion gameplay and a smaller iPhone at the largest text size. These are local results, not a claim about a new cloud CI run.
- [Pacing evidence](evidence/falling-sky-pacing-2026-10-16/README.md) records exact scope and limitations. VoiceOver speech/focus and physical-device feel remain open.

## 1. Make choices engaging — active

**Question:** Is the player making useful decisions, or simply clearing the only available group?

The [strategy baseline](evidence/falling-sky-strategy-2026-10-16/README.md) is complete. Across 200 seeds, only about 10% of match-ready states in one-clear-per-shower policies offer multiple groups. Largest-first and first-group policies score almost identically. This is a reason to investigate decision depth, not proof that the game is unenjoyable.

The [next-tranche record](evidence/falling-sky-tranche-2026-10-16/README.md) compares two offline mixed-color candidates. Neither replaced the default. One optional objective-driven First Light round is the playable comparison in this tranche.

Ongoing experiment sequence:

1. Compare the current same-color showers with a two-color shower distribution in an offline candidate. Preserve the first-shower match, bounded dry-board assistance, dark-star settings, save compatibility, and unchanged announced previews.
2. Measure simultaneous groups, waits without a useful move, score/survival distributions, and whether clearing a high column actually helps. Include a clear-all policy; one clear per shower is only a diagnostic constraint.
3. Promote a candidate only after core checks and an actual short simulator playthrough. Preserve the current version for comparison. Do not pick a winner solely from bot scores.
4. Use the [falling-sky playtest](PLAYTEST-FALLING-SKY.md) to compare comprehension, perceived waiting, choices, and replay preference. Record only observed play; there are no participant results yet.

**Exit:** Opening remains playable within one settled shower; long dead stretches do not return in the regression sample; a player can describe a useful choice and prefers the candidate or clearly identifies the next issue. Numeric sample targets are design hypotheses, not release gates.

## Progression direction — one challenge prototype, campaign deferred

[Mechanics/progression research](design/FALLING_SKY_RESEARCH.md) and [Mahjong-solitaire research](design/MAHJONG_PROGRESSION.md) distinguish puzzle difficulty from a long level counter. The user's next-tranche request advances the plan to one optional First Light challenge. Validate completion/retry and compare goal-driven play with survival before authoring more skies. No campaign, unlock system, XP, currency or infinite-content generator is included. Future challenge sequences should vary layout, goals and pressure, with readable changes and easier relief rounds rather than an assumed endlessly rising difficulty curve.

## 2. Polish physical feel — next

- Review comet speed, landing/growth emphasis, clear readability and input response on a real iPhone.
- Tune optional sound/haptics for comfort, silent mode and interruptions; keep defaults off and mute immediate.
- Profile repeated rounds for frame pacing, memory growth and leftover effect nodes before optimizing.

**Exit:** No distracting effect blocks the next decision; no input lock or accumulating effects; device observations and profiles are retained.

## 3. Make danger and outcomes readable

- Communicate nearly full columns and growth-blocked jewels without relying on color or motion alone.
- Keep the preview legible while preserving the current hidden landing places.
- Make overflow cause, final score, replay and new sky easy to understand and reach.
- Keep pause and manual shower controls reachable on smaller screens and with large text.

**Exit:** A first-time player can explain the loss and their next action; native input, settings dismissal and layout checks pass on affected screens.

## 4. Finish accessibility and reliability

- Actual VoiceOver speech, focus, matching-group rotor, activation and focus return from Settings.
- Actual system Reduce Motion while playing; paused/manual play and Calm effects remain usable.
- Minimum-supported OS, small phone, iPad portrait/landscape, large text and contrast review.
- Rapid taps, moving-arrival interruptions, save/relaunch, replay/new sky, audio interruption and repeated-round stress.

**Exit:** Retained source-bound results distinguish simulator automation from device/human observations. No blanket accessibility claim from structural checks.

## 5. Prepare a shareable build

- Reconcile current falling-sky acceptance/release documents with the selected mechanics.
- Verify clean dependencies, privacy declaration, icons, version/build metadata and Release packaging.
- Configure signing and run on a device before preparing TestFlight distribution.

**Exit:** Reproducible signed build, clean-edition checks, known-issues list and completed device checklist. Upload/distribution remains a concrete final action when requested.

## Delivery discipline

Work in small verified batches. Keep rules in StarfallCore, presentation/feedback explicit, saves compatible and other local edits intact. Update this roadmap with the outcome of each experiment; historical evidence remains append-only. No feature is marked accepted just because it compiles or a bot performs better.
