# Supernova rule comparison

October 17, 2026, Eastern time. Source: `a999e6bf7e7c74026d6b8d457e138af29d68d537` core with the isolated candidate in `tools/mechanics/supernova.patch`; rotation applies the runner's explicit substitution. Tools and this evidence are working-tree additions. Existing Xcode project/workspace drift remains preserved and is not used by these samples.

Hypothesis and scope, stated before implementation: clearing a group worth five or more can reshape nearby opportunities; compare adopting the group's identity with rotating each neighbor's identity. Three-point ordinary taps remain legal. No bonus points, extra removal radius, cascade, free growth, special star, new shower rule or campaign. Only orthogonal colored survivors adjacent to the original group change before settling. Standard Dusk removal still applies. This is a bounded offline experiment before gesture/UI adoption.

Acceptance for this tranche: deterministic results, mutation-free invalid charges, original ordinary-clear baseline, exact forecast preservation, identity/growth preservation, diagonal exclusion, no automatic cascade, score/save conservation, save round-trip and continued replay. Fixtures and the sampled states pass these checks. Adoption additionally requires a credible tap/charge tradeoff and native comprehension/feel checks; these remain open.

## Observed comparison

On identical ordinary-tap trajectories, both candidates have 690 eligible decisions among 3224 clears. Adopting the group identity offers more immediate legal groups in 297 cases and fewer in five; rotation offers more in 151 and fewer in seven. Both change the settled board in 623 cases. These metrics capture only immediate group counts, not the strength of every future strategy.

| Clear-all policy | Ordinary tap | Adopt identity whenever eligible | Rotate whenever eligible |
| --- | ---: | ---: | ---: |
| Total score, 200 rounds | 12419 | 16601 | 14487 |
| Total showers | 5290 | 6255 | 5818 |
| Rounds ended by 60-shower cap | 200 | 195 | 198 |

Survivors are censored; totals are not final-round score estimates. Policies visit different subsequent boards. The follow-up-choice policy and every denominator are retained in JSON. The ordinary policy exactly matches the prior expanded clear-all baseline's score, showers and clears.

Decision: neither candidate is adopted into the app. Matching-identity recoloring is the stronger match creator in this diagnostic, but both mostly favor charge on eligible groups. Rotation adds a transformation rule without establishing a better tradeoff. Next: investigate a readable cost/constraint or a different neighborhood effect before introducing a timed hold. Any native prototype must define release/cancel, stale intent on showers/restart/background/settings, an accessible untimed equivalent, identity-correct rendering, and full/reduced-motion feedback. No evidence here resolves those boundaries.

## Executed checks and limits

`python3 tools/mechanics/run-supernova.py` and `python3 tools/mechanics/run-supernova.py --rotate` passed with optimized Swift compilation and assertions. Matching-identity output repeated byte-for-byte. Both run 200 seeds × three policies, up to 60 showers. Every sampled committed shower/clear passes `isValidSave`; each clear's JSON restore compares equal and produces the same next shower. The ordinary baseline metrics match the previous sampler. `python3 -m py_compile tools/mechanics/run-supernova.py`, `python3 scripts/ci-hygiene.py` and `git diff --check` passed. Toolchain: Xcode 27.1 (27A9275), host Swift compiler; no simulator needed for the offline runner. Raw output lives in `/tmp/starfall-supernova*`; selected results are beside this record.

The preceding unchanged-core batch passed 60 package tests and a Debug generic simulator build. These candidate rules are compiled and exercised only by the isolated runner; they are not in that app build. Hosted/UI, interruptions, native gestures, animation, actual VoiceOver, physical-device and human-play acceptance are unverified. Production saves are untouched; restoring a candidate in the current app is not a supported migration.

Research: [Automated Playtesting of Matching Tile Games](https://arxiv.org/abs/1907.06570) compares multiple automated play styles and separately compares agents with human traces. It supports using several diagnostic policies and retaining a human-validation boundary; it does not validate these simple policies as human models or endorse either Starfall rule.

## Follow-up: value and announced-shower comparison

The same source core with the expanded sampler produced `adopt-identity-depth.json` and `rotate-identity-depth.json`. Every pre-existing output field matches its preceding candidate result, checked by script across all three policies. The new fields compare total starlight in legal groups and overflow through the announced shower, with no intermediate clear. Counterfactual shower states also pass save invariants. Both runner commands, Python compilation, hygiene and diff checks passed.

On the shared ordinary-tap trajectory, adopting the cleared identity improves immediately clearable value in 329/690 eligible decisions and reduces it in three. Rotation improves it in 165 and reduces it in nine. Neither produces an immediate survival difference in this sample. That observation covers the visited first-group decisions and one announced shower; it does not establish long-term equivalence.

The matching-identity tap counterexamples occur at seeds 124/shower 9 (six clearable starlight after tap versus five after charge), 127/shower 7 (three versus zero), and 192/shower 10 (three versus zero). Exact pre-input core states and tapped cells are retained in JSON for a native comparison fixture. This establishes that recoloring can destroy useful matches, while confirming that the effect is rare in this policy. The earlier no-adoption decision stands; no extra cost or threshold was added to force a numerical tradeoff. Charge duration and automatic-shower exposure are absent from this offline model and remain native design questions.
