# Local first-playtest kit

Prepared 16 October 2026. **Ready-to-print materials; zero human sessions or results collected.** Rules remain 7×7, five kinds, orthogonal groups of 3+, 70 cleared jewels in 18 valid moves. This kit adds no app feature, seed selector, analytics, recording, recruitment, network service or dependency.

## Open and print

- [Participant card R1](../../tools/playtest-kit/participant-card.html): one page, with the actual 43/70 score and nine moves remaining, five shape/color/letter identities, top-down player coordinates and neutral prediction prompts. No seed, tap history, answer, selected group or link to the moderator packet is present.
- [Moderator packet](../../tools/playtest-kit/moderator-packet.html): three pages, separately printable. Page 1 is session guidance; page 2 contains the answer and reachability inputs; page 3 is a blank per-person observation sheet. Print extra copies of page 3 as needed. Keep the packet out of the participant's view.

Both files are self-contained: inline CSS and SVG, system fonts, no scripts, external images, remote fonts or network requests. Open the HTML locally in a browser and print at 100% on Letter or A4, with browser headers/footers off. The stylesheet requests 10 mm margins. Color printing helps, but every kind also has a distinct shape and letter. If a participant needs a larger or spoken representation, provide it; mark the probe unavailable if access is inadequate.

The card is a **supplement to [FIRST_PLAYTEST_PROTOCOL.md](FIRST_PLAYTEST_PROTOCOL.md)**. Run uncoached live play and the replay questions first. Do not show the answer or teach the setup beforehand. R1 does not replace the synthetic A→B transfer pair or its thresholds. Record whether that pair or the gravity explanation was already seen; repeating R1 after teaching is not a transfer result. No person should be hurried to complete a round.

## The verified position

The source is the fourth retained record in [reachable-examples.json](../../tools/gameplay-study/results-2026-10-16/reachable-examples.json). It was reached by actual core play: seed 1, nine largest-policy taps, score 43 and nine moves left.

The exact prior taps are recorded below as `(row,column)`:

- **Player coordinates, top-down 1–7:** `(7,3), (3,2), (7,3), (7,3), (7,2), (2,1), (7,4), (3,2), (5,4)`.
- **Core coordinates, bottom-up 0–6:** `(0,2), (4,1), (0,2), (0,2), (0,1), (5,0), (0,3), (4,1), (2,3)`.

Clearing the bottom-left three rose, player row 7 / columns 1–3, joins **at least nine known mint**, for a two-clear floor of **12**. The largest current group clears five and has a best known follow-up of four, a floor of **9**. A second tap/move is required. Unknown refill may improve either choice; neither comparison proves a globally best move, a whole-round guarantee or a forced loss for another choice.

The answer key marks the nine known mint at player `(3,5), (4,3), (4,5), (4,6), (5,1), (5,2), (5,3), (5,4), (5,5)`. Its question marks represent unknown new jewels. Seed/history appear only in moderator materials for provenance, never as a skill signal or participant input.

## Generate and check

From the repository root:

```sh
python3 tools/playtest-kit/build.py
python3 tools/playtest-kit/build.py --check
```

The generator reads the retained record and unchanged visible-survivor helper, verifies the source, then writes both HTML files and [verification.json](../../tools/playtest-kit/verification.json). `--check` recompiles the focused verifier against a temporary frozen copy of the current real core and compares regenerated artifacts without writing them. It uses only Python's standard library and the installed Swift compiler. Compiler/cache files remain temporary; it does not use the app/package build directories.

Checks passed against core SHA-256 `9ab2d57af8fe0ee804ce56e762eb5833a08ae5f39e8916ffaa0fe708d90e7086`:

- Exact nine-tap replay, stable-largest choices, board contents and score/moves.
- Both illustrated first clears, resolved known-survivor positions and free-recovery absence.
- All **125 assignments** to the three unknown refill slots preserve the nine known mint.
- Actual real-core rose clear and mint follow-up: three then nine, reaching score 55 with seven moves left.
- Participant answer/provenance isolation and inline-only content.
- Glyph-letter contrast ratios **8.74:1–10.60:1**, with shape and letter redundancy. These calculations are not an accessibility usability test.

The verification file's section counts describe HTML structure; they are deliberately separate from measured printed pagination.

## Print review performed

The optional [print-proof renderer](../../tools/playtest-kit/print-proof.cjs) used the already bundled Playwright and installed Chromium as an **isolated offline HTML-to-PDF renderer**, without accessing a user browser session, game or simulator. No packages were installed. Four actual proofs were generated: participant **one page on Letter and A4**, moderator **three pages on Letter and A4**. Text extraction matched across paper sizes, and actual PDF pages plus print-style screenshots were inspected for legibility, board alignment and clipping. The initial Letter observation-sheet footer overflow was corrected before this final check.

[Print-review evidence](../../tools/playtest-kit/print-review.json) records the reviewed HTML hashes, measured PDF page counts and historical proof hashes/paths. The original local proof directory was `/private/tmp/starfall-playtest-print`, containing the four PDFs and actual Letter-page PNGs `participant-letter.png` and `observation-letter.png`. Those temporary proofs are not repository dependencies. Regenerate them from the retained HTML; PDF metadata can change byte hashes, so compare source HTML, pagination, text and appearance when checking a new render.

With an existing Node installation whose module resolution includes Playwright, reproduce the optional proof with:

```sh
node tools/playtest-kit/print-proof.cjs /tmp/starfall-playtest-print
```

For a Codex bundled runtime, discover its current Node and package paths with `load_workspace_dependencies`, set `NODE_PATH` to that runtime's existing `node_modules`, and invoke its Node executable. No install is required on the reviewed machine. This optional check is not required to generate or print the HTML. It writes temporary Letter/A4 PDFs, screenshots and layout measurements, with a bounded renderer timeout. Inspect the resulting PDF page counts separately; generating a PDF alone is not a layout pass. A managed environment may require permission to launch the bundled browser process.

This is document-layout verification. No physical printer, participant, screen-reader session or native game visual validation was exercised. The HTML remains the deliverable; browser/printer scaling settings can change pagination, so inspect print preview before handing out copies. All observation fields remain blank.

## Scope and handoff

Owned additions are `tools/playtest-kit/` and this document only. Existing game source, UI/HUD, assets, tests, native-validation work, retained study results and the original playtest protocol remain unchanged. The next action is to use the materials in an authorized observed session and record actual behavior; bot checks and an answer key must not fill any human-result field.
