# Next tranche: shower comparison and First Light

October 16, 2026, Eastern time. Comparisons use the survival core at published `2411de6` and `tools/sample-falling-sky-balance.swift` from the strategy baseline. Candidate patches are offline experiments; neither was promoted to the app.

## Mixed-color comparison

Each candidate keeps the first-shower match and the first three matching arrivals in dry-board relief forecasts. Split-tail uses a second color for the last two stars of five-star showers. Alternating uses a second color at odd offsets in natural showers, while retaining the relief run. Both consume additional RNG draws, so shared seeds do not mean identical future shower sizes/columns. The patches and JSON results preserve the exact experiments.

| One-clear policy: first group | Baseline | Split-tail | Alternating |
| --- | ---: | ---: | ---: |
| Mean starlight | 58.52 | 52.02 | 47.81 |
| Mean showers survived | 26.21 | 25.20 | 23.35 |
| Match-ready states with multiple groups | 9.61% | 11.79% | 8.82% |

All three samples have 200 fixed seeds, a 60-shower cap, and the six policies described in the JSON. All sampled rounds ended within the cap. Split-tail raises the multi-group fraction by about two percentage points; alternating lowers it. Lower score/survival is not inherently bad, but the results do not demonstrate enough additional decision depth to replace the current default. Human comparison remains necessary. No mixed candidate received native visual or human acceptance.

Reproduction without changing the checkout: export `Sources/StarfallCore` at `2411de6` into a temporary directory, apply one retained patch there with `patch -p1`, then compile those core files with the strategy sampler using `swiftc -O`. Preserve a baseline copy for the second candidate. The JSON is event-based analysis, not 90-second player timing or enjoyment data. Candidate source is not used by the challenge prototype.

## Playable deliverable

One optional First Light challenge, accessed through Sky settings: fixed seed 42, 18 starlight, steady showers and no dark stars. Starting it replaces the current round explicitly. Paused clears and manual advance work. Completion stops the clock and core input, is saved with the same round envelope, and restores as complete. Replay starts the identical challenge; New sky returns to survival. Fixed challenge balance prevents changing the objective's configuration midway. There is no level map, XP, unlock list or persistent campaign completion.

`StarfallChallenge` is a small deterministic core boundary. Legacy saves lack its optional identifier and remain survival rounds. `isValidSave` checks challenge seed/balance; the original score/board conservation validation is unchanged. Goal completion takes precedence over overflow in the challenge outcome policy. Survival shower generation remains unchanged.

See `docs/design/MAHJONG_PROGRESSION.md` for primary-source research separating player-level counters, layout variety, and actual difficulty. This tranche tests a goal and a finish, not an infinite-content system.

Challenge validation: 60 core tests, 16 hosted store tests, nine native interaction tests, and a Release simulator build passed. The three terminal-state tests passed again after hiding inactive terminal controls. Largest-text settings also passed on iPhone 17e. These results precede the compact UI revision, which has its own checks. Actual VoiceOver speech/focus and device sound/haptic feel remain separate acceptance work.
