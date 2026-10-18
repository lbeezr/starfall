# Seed-17 storm-choice follow-up

Date: 2026-10-17. **Final completed scope: Surge 24 showers / 57 starlight / 13 successful clears; Natural 24 showers / 37 starlight / 10 successful clears plus one invalid cell tap. Neither run overflowed.** This is an agent simulation with substantial prior game familiarity, Surge first and Natural second. Natural's initial run stopped before shower 16; the exact verified prefix was replayed once on a dedicated simulator, then the remaining decisions completed through 24. Replay actions are not counted as new choices or added clears. No human learning, enjoyment, replayability, real-time urgency, actual VoiceOver listening, or full-animation acceptance is established.

## Recommendation and strongest evidence

**Revise the isolated Surge candidate before adoption; do not infer a gameplay win from this run.** The warning was understandable and changed cashout timing, but the trace does not yet demonstrate a substantial phase-specific tradeoff beyond available stars and ordinary growth-versus-space decisions. The Natural run supplies concrete counterevidence: it produced the same support-clear tactics without a phase cue. Keep this as a baseline for a bounded strategy experiment, not evidence to add a special star or alter shipped rules automatically.

- At the matched shower-8 board (score 8, same first-seven decisions), Surge's warning prompted an amber cashout for 5. Natural held the same three-high amber stack, then cashed it at 11 for 5 when an aqua landing created a useful drop/connection. The cost was retaining occupied cells for three showers versus giving up future connections earlier. There was no demonstrated danger from the hold; the warning clear was also the biggest obvious clear. This is a timing preference, not proof of deeper strategy.
- Surge 10 chose smaller mint (+3) while holding larger aqua for growth. Surge 12 chose two smaller supports, violet (+4) then amber (+3), to lower a blocked left tower while retaining aqua. These decisions had spatial reasons. Natural 13 made a similar smaller violet support clear (+4) under a five-high column, holding larger aqua, with no Recovery label. These examples do not isolate phases as the cause of useful clear ordering.
- Surge 20 warning led to clearing both independent ready groups (+3 aqua, +6 violet). This was plainly easy cleanup for a space-first policy; little ordering interest remained. Surge 22 took the largest rose group (+7). Surge 21 and 23 offered no useful repair choice despite an event label. Early showers 1–3 and recovery 15–16 included repetitive optional holds with ample headroom.
- Dark-star repairs at Surge 6, 14, 17 and Natural 6, 15 were clear and useful, but mostly obvious once a ringed adjacent group appeared. Natural 12–14 involved waiting for that opportunity. Blocker removal supplied a local objective without requiring phases.

## Separate axes

| Axis | Actual observation | Limit |
|---|---|---|
| Pressure | Event showers made taller stacks and the warning encouraged earlier cleanup. Surge survived 24 with headroom; at 11 I explicitly held through a remaining heavy shower. | Paused input plus restore between observations cannot establish urgency. No counterfactual proves that a different cashout would overflow. |
| Reward for setup/hold timing | Violet support clears at 4 and aqua support clears at 9 joined new groups in both modes. Natural's amber hold through 11 created a later aqua connection. | Connection rewards existed in Natural too. Many holds were low-risk; no measured opportunity cost or uniquely phase-dependent reward was established. |
| Replayability | A changed seed and reversed order reduced reliance on the earlier demonstration. | One familiar agent, one seed per mode, relocated Natural run: no preference/enjoyment/replayability claim. |

## Method and boundaries

Ordinary launches used `--starfalls-reset --starfalls-seed=17`, no prepared fixture, isolated bundles `com.starfall.mechanics.observatory.surge` and `com.starfall.mechanics.observatory.natural`, on Mechanics Lab `A84C81F5-AE41-496A-97AE-E17C63E18D29`, iPhone 17e / iOS 27.0. Parent supplied matched app/source identity and normal-mode setup evidence. The player did not inspect Core/source/hidden forecasts, change app/system preferences, or touch production saves.

The remote input bridge failed before play (Appendix A). Both apps were subsequently reset through the native XCTest action driver. Each chosen command used an XCUI button accessibility ID; each Next asserted exactly one committed shower increment. One shower was observed at a time. Every action reason was stated in commentary before the native call, with screenshot inspection before any hierarchy-value consultation. The only batched clears were independent left aqua and right violet at Surge 20; the intermediate board was not independently observed, so this does not prove their commutativity.

Each driver call terminates the app after attachments, so restore occurs between observations. Early Surge clear screenshots (call indices 5, 8, 11, 13, 15, 18, 19) captured transient clear effects. Committed hierarchy confirmed aqua-3 after call 5 and violet-4 after call 13; those exact values assisted subsequent holds. Remaining decisions used visible shape/color, rings, height, guide messages and score; hierarchy afterward verified committed shower/score and action targets. Target IDs encode core row 0 at the visual bottom and zero-based columns; no node position was used as a rule oracle.

At the boundary after Surge 13, a test-only overlay added bounded condition waits for Next enabled or terminal outcome after clears, applied identically to both export test files. It did not change App/Core/assets. The final exact overlay is [StormChoiceNativeDriver.swift](StormChoiceNativeDriver.swift); its later `observe` diagnostic skips taps without weakening input assertions. Normal text only. Native screenshots are evidence of layout and committed visual state, not full animation quality.

## Interruption after Natural 15

The native call intending Next 16 failed **before target.tap** at the enabled expectation in exported UITests/FallingSkyInteractionTests.swift:656. The screenshot was white; captured Natural hierarchy exposed Next disabled. No shower-16 success is claimed, and no gameplay retry/reset occurred.

- Failed result: `/Users/lbeezr/Library/Developer/XcodeBuildMCP/workspaces/Starfall-27844ad883f3/result-bundles/test_sim_2026-10-17T19-20-49-524Z_pid85616_c84b6ea4.xcresult`.
- Failure exports: `/tmp/storm-choice-natural-failed16`; white capture `8EBBC13E-8954-4F46-9923-EBEA937E71E4.jpeg`; Next debug text `BA7AC9A1-67AA-49A3-9AB6-C0B1E6741A15.txt`.
- One parent-authorized observation-only activation (no reset/tap) reported `app.state=3; board=15 showers, 1 matching groups ready; score=23 starlight; nextEnabled=false`. Its screenshot showed a different visible board at score 0 with guide text about four large diagonal stars, while the Natural hierarchy retained 15/23. The player did not create that visible fixture. This mismatch is evidence of foreground/interference or capture context uncertainty, not a rule/save-quality conclusion. Input stopped as agreed.
- Observation result: `/Users/lbeezr/Library/Developer/XcodeBuildMCP/workspaces/Starfall-27844ad883f3/result-bundles/test_sim_2026-10-17T19-22-35-755Z_pid85616_5983b5e9.xcresult`; screenshot `/tmp/storm-choice-natural-24/CB9A5F23-0DE3-4AFD-B438-833D023D2F22.png`; diagnostics `/tmp/storm-choice-natural-24/CB1A2771-F19C-41B5-8C5D-220A06808B3C.txt`.

## Representative screenshots

| State before next decision | Exact native attachment path |
|---|---|
| Surge 8, score 8, before amber cashout | `/tmp/storm-choice-surge-10/98BE14AF-C44C-443E-B965-A5F6E8013020.png` |
| Natural 8, score 8, before amber hold | `/tmp/storm-choice-natural-11/71AFC37C-D489-4509-BAB3-FCBBBC2FEEC1.png` |
| Surge 10, before smaller mint clear | `/tmp/storm-choice-surge-14/C6D4F903-402A-4E12-B7EC-2591D5C42C6F.png` |
| Surge 12 recovery, before support clears | `/tmp/storm-choice-surge-17/303CF467-426F-4650-84C9-913627F9F0DF.png` |
| Natural 13, before smaller support clear | `/tmp/storm-choice-natural-18/0A9B83FC-4AFA-44E8-A0F0-527EFA931874.png` |
| Surge 20 warning, before clear-all | `/tmp/storm-choice-surge-30/8D7B3FBD-88BA-40AA-A22D-D715B46AF31C.png` |
| Surge 24 final | `/tmp/storm-choice-surge-36/BFAD71B7-84D9-4C11-AEA2-573B209BB355.png` |
| Natural 15 final verified game state after dark removal | `/tmp/storm-choice-natural-22/FCB2792A-E6D8-49F5-9579-9DEF145DC0B6.png` |

## Ordered action trace

Commands are exact accessibility IDs. Each row records the state **after** its command(s). Reasons were stated before acting; no unseen showers were batched. Full native results remain under the result paths in [native-actions.json](native-actions.json), which also maps every screenshot and hierarchy attachment. The trace starts after the separate successful Surge reset result `test_sim_2026-10-17T19-00-25-631Z_pid85616_155e78f7.xcresult`.

### Surge

| Call | Chosen command(s) | After: shower / score | Pre-action reason |
|---|---|---|---|
| 1 | `experiment.next` | 1 / 0 | 0: empty, wait |
| 2 | `experiment.next` | 2 / 0 | 1: hold low violet triple for growth; space ample |
| 3 | `experiment.next` | 3 / 0 | 2: same sole low violet option; wait for growth |
| 4 | `experiment.next` | 4 / 0 | 3: isolated grown amber; violet unchanged; wait with headroom |
| 5 | `experiment.cell.0.2` | 4 / 3 | 4: clear supporting violet to drop aqua next to bottom aqua pair |
| 6 | `experiment.next` | 5 / 3 | 4 after clear: AX confirms aqua3; hold for growth; advance5 |
| 7 | `experiment.next` | 6 / 3 | 5: hold both aqua groups for growth, accepting occupancy; 4 calmer remain |
| 8 | `experiment.cell.1.0` | 6 / 8 | 6: clear aqua adjacent dark; preserve amber and separate aqua for growth |
| 9 | `experiment.next` | 7 / 8 | 6 after aqua+5 dark dissolved: retain other low groups, advance7 |
| 10 | `experiment.next` | 8 / 8 | 7: low board; hold groups another calmer shower; clear-all also safe |
| 11 | `experiment.cell.0.2` | 8 / 13 | 8 warning: bank tallest amber; hold low violet/aqua; timing tradeoff but biggest-clear counterevidence |
| 12 | `experiment.next` | 9 / 13 | 8 after amber+5: hold low groups; advance9 boundary |
| 13 | `experiment.cell.0.0` | 9 / 16 | 9: clear left aqua support to join violet and reduce height; hold separate bottom aqua |
| 14 | `experiment.next` | 10 / 16 | 9 after aqua+3: AX confirms violet4; hold through first heavy shower, accepting occupancy |
| 15 | `experiment.cell.1.0` | 10 / 19 | 10: smaller mint clear lowers left column; retain larger aqua growth reserve despite heavy showers |
| 16 | `experiment.next` | 11 / 19 | 10 after mint+3: keep violet/aqua held; advance11 |
| 17 | `experiment.next` | 12 / 19 | 11: headroom ample; wait on large aqua despite one heavy remaining; phase not forcing action |
| 18 | `experiment.cell.0.1` | 12 / 23 | 12 recovery: clear violet support under tall blocked left stack, smaller than aqua; geometry over phase |
| 19 | `experiment.cell.0.0` | 12 / 26 | 12 after violet+4: clear amber support to lower blocked column further |
| 20 | `experiment.next` | 13 / 26 | 12 after support clears score26: hold remaining groups, advance13 recovery |
| 21 | `experiment.next` | 14 / 26 | 13: no ready match adjacent dark; wait; driver now waits settled clear capture |
| 22 | `experiment.cell.1.1` | 14 / 31 | 14: clear newly ready violet adjacent dark; preserve separate groups |
| 23 | `experiment.next` | 15 / 31 | 14 after violet+5 dark dissolved: optional growth hold through15 |
| 24 | `experiment.next` | 16 / 31 | 15: aqua supports violet; headroom ample, wait one more recovery shower |
| 25 | `experiment.next` | 17 / 31 | 16: isolated rose growth, options unchanged; repetitive wait17 |
| 26 | `experiment.cell.1.6` | 17 / 34 | 17: smaller rose clear adjacent dark; blocker removal obvious over largest aqua |
| 27 | `experiment.next` | 18 / 34 | 17 after rose+3: blocker removed, no difficult sacrifice; wait18 |
| 28 | `experiment.cell.0.3` | 18 / 41 | 18: largest aqua lowers five-high centre; forgo possible growth due height |
| 29 | `experiment.next` | 19 / 41 | 18 after aqua+7: low violet held for future connections/growth; wait19 |
| 30 | `experiment.next` | 20 / 41 | 19: new low aqua group, no blocker; hold versus safe clear-all; advance20 |
| 31 | `experiment.cell.1.0,experiment.cell.1.4` | 20 / 50 | 20 warning: independent left aqua and right violet clear-all; forgo future growth; batching coupling limited |
| 32 | `experiment.next` | 21 / 50 | 20 after clear-all+9 score50: no rings, advance21 boundary |
| 33 | `experiment.next` | 22 / 50 | 21 event no ready groups: forced wait22 |
| 34 | `experiment.cell.1.1` | 22 / 57 | 22: bank largest left rose before remaining heavy showers; obvious largest clear |
| 35 | `experiment.next` | 23 / 57 | 22 after rose+7: no further ready clear, advance23 |
| 36 | `experiment.next` | 24 / 57 | 23: dark atop centre, no adjacent ready group; forced wait24 |

### Natural: original verified prefix

| Call | Chosen command(s) | After: shower / score | Pre-action reason |
|---|---|---|---|
| 1 | `reset` | 0 / 0 | Natural reset ordinary seed17; exclude all prior app states |
| 2 | `experiment.next` | 1 / 0 | 0 empty wait1 |
| 3 | `experiment.next` | 2 / 0 | 1 hold low violet for growth; space unnecessary |
| 4 | `experiment.next` | 3 / 0 | 2 unchanged sole violet group; repetitive wait3 |
| 5 | `experiment.next` | 4 / 0 | 3 isolated amber grew; no new legal choice; wait4 |
| 6 | `experiment.cell.0.2` | 4 / 3 | 4 clear violet support to connect aqua; same geometry choice as Surge |
| 7 | `experiment.next` | 5 / 3 | 4 after violet+3 visible aqua join; hold growth, advance5 |
| 8 | `experiment.next` | 6 / 3 | 5 hold two low aqua groups; growth-space tradeoff independent of phases |
| 9 | `experiment.cell.1.0` | 6 / 8 | 6 clear aqua adjacent dark; obvious blocker priority matches Surge |
| 10 | `experiment.next` | 7 / 8 | 6 after aqua+5 dark gone, hold remaining groups; advance7 |
| 11 | `experiment.next` | 8 / 8 | 7 low board; optional hold, advance8 |
| 12 | `experiment.next` | 9 / 8 | 8 hold amber three-high absent warning; deliberate contrast to Surge cashout; risk may be small |
| 13 | `experiment.cell.0.0` | 9 / 11 | 9 clear left aqua support to join violet; retain amber, spatial choice independent of storm |
| 14 | `experiment.next` | 10 / 11 | 9 after aqua+3 violet join; hold all ready groups with headroom, advance10 |
| 15 | `experiment.next` | 11 / 11 | 10 isolated mint arrivals; no new ready alternative; wait11 |
| 16 | `experiment.cell.0.2` | 11 / 16 | 11 clear held amber support to drop grown aqua into bottom group; four-high column |
| 17 | `experiment.next` | 12 / 16 | 11 after amber+5 aqua group enlarges; hold growth, advance12 |
| 18 | `experiment.next` | 13 / 16 | 12 dark arrival adjacent groups undersized; wait for growth rather than remote scoring |
| 19 | `experiment.cell.0.1` | 13 / 20 | 13 smaller violet support lowers five-high left; larger aqua held; geometry mirrors Surge12 |
| 20 | `experiment.next` | 14 / 20 | 13 after violet+4 left lower; right blocker unresolved; hold aqua reserve, advance14 |
| 21 | `experiment.next` | 15 / 20 | 14 no direct dark repair; wait, remote aqua cashout would not remove blocker |
| 22 | `experiment.cell.2.4` | 15 / 23 | 15 newly grown violet adjacent dark; obvious repair after waits |

Natural original call 23 was the failed Next-16 attempt described above; call 24 was observation-only, not gameplay. No further input used Mechanics Lab. The dedicated continuation below completes the comparison.

## Dedicated relocation and final Natural continuation

The parent confirmed parallel constellation work had used Mechanics Lab and supplied a new booted dedicated simulator: **Starfall Storm Choice 01a149f6**, iPhone 17e / iOS 27.0, `536BCC00-751C-47BA-BC2F-C1702941CFC8`. No further player action used Mechanics Lab. The driver now asserts `app.wait(for: .runningForeground, timeout: 10)` after launch/activate and before button interaction. That exact final driver was mirrored into both exported test files and the evidence copy; no App/Core/assets or rules changed.

One native-call batch replayed `reset` plus the exact original Natural chosen prefix through call 22, once. This was relocation replay, not new play or a new policy comparison. Its screenshot was inspected first; hierarchy then confirmed **15 showers / 23 starlight, Next enabled**. Foreground assertion passed. Replay result: `/Users/lbeezr/Library/Developer/XcodeBuildMCP/workspaces/Starfall-27844ad883f3/result-bundles/test_sim_2026-10-17T19-26-26-792Z_pid85616_e6f27565.xcresult`; screenshot: `/tmp/storm-choice-natural-dedicated-1/0B6FA227-343A-400E-8E86-6C396CF6AE95.png`. Subsequent native calls each asserted foreground and exactly one committed shower increment when advancing. No new failure occurred.

Natural 16–24 added four successful clears: aqua17 +5, rose18 +3/dark dissolved, amber20 +3, violet22 +3. Its right column became six high at17 and full at22, with no supporting ready match. The remote aqua17 clear opened other columns but could not directly lower that threatened column. This demonstrated **pressure without a useful local repair**, counterevidence that increased occupancy alone supplies interesting decisions. No overflow happened by24, so no claim is made that it would inevitably lose on the next shower.

At Natural20, I called the amber cashout visually largest before acting, but its +3 result showed I had overstated its value. At23 I misread two small bottom rose stars as ready, tapped `experiment.cell.0.1`, and got **no state/score change** with corrective threshold guidance. After screenshot inspection, hierarchy confirmed connected value2 and zero matching groups. This is one invalid tap, not a successful clear or extra shower. Ready-ring absence and guide feedback corrected the mistake; exact AX values did not drive that decision. These mistakes limit visual-value inference in this agent run and must not be rewritten as verified optimal strategy.

| Dedicated call | Command(s) | After: shower / score | Pre-action reason / observed correction |
|---|---|---|---|
| 1 | `reset + exact original prefix (full commands in JSON)` | 15 / 23 | Relocation replay only: exact verified Natural prefix through15/23; no new decisions |
| 2 | `experiment.next` | 16 / 23 | 15 restored23: hold low aqua reserve; continue original Next16 decision |
| 3 | `experiment.next` | 17 / 23 | 16 dark low left adjacent aqua not ready; hold remote large group, wait17 |
| 4 | `experiment.cell.0.2` | 17 / 28 | 17 right column six-high no supporting ready clear; bank only large aqua for other space, cannot solve threatened column |
| 5 | `experiment.next` | 18 / 28 | 17 after aqua+5 score28: no ready group, threatened right unchanged; forced advance18 |
| 6 | `experiment.cell.2.0` | 18 / 31 | 18 new rose pair directly above dark; clear for dissolution, right threat separate |
| 7 | `experiment.next` | 19 / 31 | 18 after rose+3 dark gone; hold low violet, cannot repair right; advance19 |
| 8 | `experiment.next` | 20 / 31 | 19 isolated amber, no repair; hold low violet and advance20 |
| 9 | `experiment.cell.2.4` | 20 / 34 | 20 bank largest middle amber; retain low violet; obvious cashout absent warning |
| 10 | `experiment.next` | 21 / 34 | 20 amber only+3 score34; visual largest estimate overstated value; hold violet, advance21 |
| 11 | `experiment.next` | 22 / 34 | 21 dark above isolated violet, separate ready violet cannot repair; wait22 |
| 12 | `experiment.cell.0.2` | 22 / 37 | 22 right full no supporting clear; sole ready violet clear for other space, clear-all no ordering interest |
| 13 | `experiment.next` | 23 / 37 | 22 after sole violet+3 no groups; invite23 despite full right no local repair |
| 14 | `experiment.cell.0.1` | 23 / 37 | 23 clear new bottom rose to lower left/open space; full right unrepairable, straightforward sole clear **Invalid; not a clear.** |
| 15 | `experiment.next` | 24 / 37 | 23 invalid rose tap score37 unchanged; guide threshold; no ready rings, advance24 |

Additional representative screenshots:

- Natural17 six-high right column before remote aqua cashout: `/tmp/storm-choice-natural-dedicated-3/CB5E1F29-1C7F-4062-9DFB-38CE07DAE495.png`.
- Natural22 full right column before sole ready violet clear: `/tmp/storm-choice-natural-dedicated-11/5A01926F-647A-441B-AFF1-75138A5104EE.png`.
- Natural23 invalid tap correction: `/tmp/storm-choice-natural-dedicated-14/B7131D5A-5DBF-4A51-9898-4EF7848F80C7.png`.
- Natural24 final state, score37: `/tmp/storm-choice-natural-dedicated-15/6038705B-1ADA-41C7-AEFB-CC5D151A479E.png`.

The final recommendation remains **revise before adoption**: phase8 affected timing, but the clearest setup rewards and smaller-first clear choices also arose in Natural. Pressure, reward for setup/hold timing, and replayability remain separate axes. This baseline did not evaluate a special-star change, and neither score nor survival demonstrates enjoyment.

## Appendix A: excluded remote bridge attempt

Before native-driver play, repeated remote Next shower taps, a touch down/up, and one menu tap reported success without changing the initial empty Surge screen. The parent then ran its explicit normal-mode setup (actual VoiceOver disabled, Reduce Motion off, per parent assertions). After fresh reset/seed17, exactly one additional remote Next tap still left score 0, Prepare 9, initial instruction and an empty board. The player stopped rather than retrying. Snapshot hash `0zhlxm0`, no nonempty cells, controls `e71` menu, `e81` Start sky, `e82` Next shower. The native driver subsequently demonstrated that game input works; do not treat remote-bridge no-ops as gameplay evidence.

Remote screenshots: before final tap `/var/folders/fs/9shw9bf142jg3280dc9n3hhc0000gn/T/screenshot_optimized_db63284c-8cb2-40d5-9a74-d67c8c7a3fa4.jpg`; after tap, still zero showers, `/var/folders/fs/9shw9bf142jg3280dc9n3hhc0000gn/T/screenshot_optimized_945d9192-4bac-4c05-8300-f0ab3c8d0663.jpg`. These attempts were excluded by native-driver resets of both apps.
