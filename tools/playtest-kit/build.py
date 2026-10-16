#!/usr/bin/env python3
"""Build/check a dependency-free printable playtest kit, verifying the real core.

Run: python3 tools/playtest-kit/build.py [--check]
Uses the existing study record and geometry helper; no simulation or human data.
"""
import argparse
import hashlib
import html
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
EXAMPLES = ROOT / "tools/gameplay-study/results-2026-10-16/reachable-examples.json"
CORE = ROOT / "Sources/StarfallCore/Game.swift"
KINDS = {
    "R": ("Rose", "circle", "#f3b4c6", '<circle cx="32" cy="32" r="24"/>'),
    "A": ("Aqua", "diamond", "#98d9e8", '<path d="M32 4 60 32 32 60 4 32Z"/>'),
    "T": ("Amber", "triangle", "#f5ce7b", '<path d="M32 4 61 57H3Z"/>'),
    "V": ("Violet", "hexagon", "#c8b8ed", '<path d="M18 6H46L61 32 46 58H18L3 32Z"/>'),
    "M": ("Mint", "square", "#a4d8b3", '<rect x="8" y="8" width="48" height="48" rx="2"/>'),
}
CSS = """
:root{color-scheme:light;color:#152333;background:#e8edf0;font-family:Arial,Helvetica,sans-serif}
*{box-sizing:border-box}body{margin:0;font-size:11pt;line-height:1.32}
.page{width:186mm;min-height:250mm;margin:8mm auto;padding:7mm;background:white;break-after:page}
.page:last-child{break-after:auto}.eyebrow{font-size:9pt;font-weight:bold;letter-spacing:.12em;text-transform:uppercase;color:#42566a}
h1{font-size:25pt;line-height:1.1;margin:2mm 0 3mm}h2{font-size:15pt;margin:5mm 0 2mm}h3{font-size:12pt;margin:3mm 0 1mm}
p{margin:2mm 0}.small{font-size:9pt}.muted{color:#42566a}.row{display:flex;gap:5mm}.row>*{flex:1}
.stats{display:flex;gap:4mm;margin:4mm 0}.stat{border:1px solid #6b7a87;border-radius:2mm;padding:2mm 4mm;font-size:12pt;flex:1}
.stat strong{font-size:19pt}.legend{display:flex;gap:2mm;justify-content:space-between;margin:4mm 0 2mm}
.legend-item{display:flex;align-items:center;gap:1mm;font-size:9pt;line-height:1.15}.legend svg{width:9mm;height:9mm;flex-shrink:0}
.board{border-collapse:collapse;margin:2mm auto;table-layout:fixed}.board caption{font-size:9pt;font-weight:normal;margin-bottom:1mm}
.board th{font-size:10pt;text-align:center;font-weight:bold;width:8mm;height:8mm}.board td{width:14mm;height:14mm;border:1px solid #a6afb7;text-align:center;padding:1mm}
.board td svg{display:block;width:11.5mm;height:11.5mm}.board td.joined{outline:2px solid #152333;outline-offset:-2px;background:#e9f4ed}
.board.compact td{width:11mm;height:11mm;padding:.6mm}.board.compact td svg{width:9.5mm;height:9.5mm}
.unknown{font-size:19pt;color:#42566a}.questions{margin:4mm 0}.questions p{margin-top:3mm}.rule{height:8mm;border-bottom:1px solid #88949e;margin:0 0 2mm}
.box{border:1px solid #8795a1;padding:2mm 3mm;margin:3mm 0}.note{border-left:3px solid #526f84;padding-left:3mm}
.grid{width:100%;border-collapse:collapse;font-size:9.5pt}.grid th,.grid td{border:1px solid #8795a1;padding:2mm;vertical-align:top;text-align:left}
.grid th{font-weight:bold;background:#f0f3f5}.grid .blank{height:14mm}.checkline{margin:3mm 0}.footer{margin-top:4mm;border-top:1px solid #b1bbc3;padding-top:2mm;font-size:8.5pt}
.observation .grid .blank{height:12mm}.observation h2{margin-top:3mm}
ul,ol{padding-left:5mm;margin:2mm 0}li{margin:1.5mm 0}.sr-only{position:absolute;width:1px;height:1px;padding:0;overflow:hidden;clip:rect(0,0,0,0);white-space:nowrap;border:0}
code{font-size:8.5pt;overflow-wrap:anywhere}.provenance{font-size:9pt}.blanklines{min-height:13mm;background:repeating-linear-gradient(white,white 6mm,#aeb7be 6.1mm,white 6.3mm)}
@page{size:auto;margin:10mm}
@media print{:root,html,body{background:white}.page{width:180mm;min-height:0;margin:0 auto;padding:0;break-inside:avoid}body{-webkit-print-color-adjust:exact;print-color-adjust:exact}.page+.page{break-before:page}.board,.legend,.box,.grid,tr{break-inside:avoid}}
"""


def esc(value):
    return html.escape(str(value), quote=True)


def glyph(letter):
    if letter == "?":
        return '<span class="unknown" aria-label="Unknown new jewel">?</span>'
    name, shape, color, geometry = KINDS[letter]
    y = 40 if letter == "T" else 39
    return (f'<svg viewBox="0 0 64 64" aria-hidden="true"><g fill="{color}" stroke="#152333" stroke-width="2.5">'
            f'{geometry}</g><text x="32" y="{y}" text-anchor="middle" font-family="Arial,Helvetica,sans-serif" '
            f'font-size="21" font-weight="bold" fill="#152333">{letter}</text></svg>'
            f'<span class="sr-only">{name} {shape}, {letter}</span>')


def legend():
    return '<div class="legend" aria-label="Five jewel kinds">' + ''.join(
        f'<div class="legend-item">{glyph(letter)}<span><strong>{letter} · {name}</strong><br>{shape}</span></div>'
        for letter, (name, shape, _, _) in KINDS.items()) + '</div>'


def board(rows, *, compact=False, joined=()):
    heading = '<thead><tr><th scope="col"><span class="sr-only">Row / column</span></th>'
    heading += ''.join(f'<th scope="col">{i}</th>' for i in range(1, 8)) + '</tr></thead>'
    body = ''
    for r, line in enumerate(rows, 1):
        body += f'<tr><th scope="row">{r}</th>'
        for c, letter in enumerate(line, 1):
            classname = ' class="joined"' if (r, c) in joined else ''
            body += f'<td{classname}>{glyph(letter)}</td>'
        body += '</tr>'
    classname = 'board compact' if compact else 'board'
    return f'<table class="{classname}" aria-label="Jewel board, rows top to bottom and columns left to right"><caption>Columns → · rows 1–7 from top to bottom</caption>{heading}<tbody>{body}</tbody></table>'


def document(title, pages):
    return ('<!doctype html>\n<html lang="en"><head><meta charset="utf-8">'
            '<meta name="viewport" content="width=device-width, initial-scale=1">'
            f'<title>{esc(title)}</title><style>{CSS}</style></head><body>'
            + ''.join(f'<section class="page">{page}</section>' for page in pages)
            + '</body></html>\n')


def contrast(color, ink="#152333"):
    def luminance(value):
        rgb = [int(value[i:i+2], 16) / 255 for i in (1, 3, 5)]
        linear = [v / 12.92 if v <= .04045 else ((v + .055) / 1.055) ** 2.4 for v in rgb]
        return sum(v * weight for v, weight in zip(linear, (.2126, .7152, .0722)))
    low, high = sorted((luminance(color), luminance(ink)))
    return (high + .05) / (low + .05)


def assemble(example, joined, core_hash):
    participant = document("Starfall — participant board R1", [f"""
<div class="eyebrow">Starfall · participant card R1</div><h1>A board to think about</h1>
<p>Take your time. You can point, speak, or write. There is no timer.</p>
<div class="stats"><div class="stat"><strong>{example['score']} / 70</strong><br>jewels cleared</div><div class="stat"><strong>{example['moves']}</strong><br>moves left</div></div>
{legend()}{board(example['board_top_to_bottom'])}
<div class="questions"><p><strong>What would you choose next, and why?</strong></p><div class="rule"></div>
<p>What do you expect to happen after that choice?</p><div class="rule"></div>
<p>Which parts can you know now, and which parts are unknown?</p><div class="rule"></div></div>
<div class="footer">Matching groups connect up, down, left and right. A group needs at least three.<br>One cleared jewel scores one; each valid clear uses one move. A new group needs another tap.</div>
"""])
    setup = example["strict_smaller_setups"][0]
    player_path = [[7-r, c+1] for r, c in example["prior_largest_policy_taps_bottom_zero"]]
    joined_text = "; ".join(f"row {r}, columns {', '.join(str(c) for rr, c in sorted(joined) if rr == r)}"
                            for r in sorted({r for r, _ in joined}))
    moderation = f"""
<div class="eyebrow">Starfall · moderator only · page 1 of 3</div><h1>Run the session, then R1</h1>
<p class="note"><strong>Preparation only.</strong> No participants or results are supplied. Keep this packet separate from the participant card.</p>
<h2>Before the card</h2>
<p>Use the existing six-person first-playtest protocol and an identified, authorized build. Reserve 10–15 minutes so an ending can happen without rushing. Use the person's preferred text, motion, sound and input setup; offer breaks or stop whenever needed.</p>
<p><strong>Opening:</strong> “We’re trying out the game, not testing you. You can pause or stop whenever you want. Please say what you are noticing when it feels comfortable; silence is fine.”</p>
<table class="grid"><tr><th>Live session</th><th>Observe without coaching</th></tr>
<tr><td>First impression</td><td>What can you do? What is the goal? Record unaided rule and goal understanding.</td></tr>
<tr><td>Uncoached play</td><td>Ask what the person is considering at one natural choice. Record the reason before its result, invalid taps and actual choices available.</td></tr>
<tr><td>Recovery / ending</td><td>Ask what changed and whether it used a move, only when observed. Ask what the result means. Do not force an event.</td></tr>
<tr><td>Debrief / free choice</td><td>Ask what felt satisfying or confusing; whether they prefer continuing, another round or stopping, and why. Record stated interest separately from actual replay.</td></tr></table>
<h2>Optional R1 prompt, after replay questions</h2>
<ol><li>Explain the five-kind legend and top-down coordinates. Provide a usable large-print or spoken form if needed; if access remains inadequate, mark unavailable.</li>
<li>Show only the participant card. Ask its three questions without indicating a preferred group. Record the prediction before showing an outcome or answer.</li>
<li>If needed, ask: <strong>“What could you guarantee from the pieces already here over two moves?”</strong> Mark this as an extra planning prompt, not spontaneous strategy.</li>
<li>Offer the same optional explanation: “Survivors fall straight down in their own columns and can join matching neighbors. New refill pieces are unknown. A new group needs another tap and another move.” Record acceptance, prior exposure and any other help.</li></ol>
<p class="small">R1 is a supplementary reachable-board probe. It does not replace the protocol's A→B transfer pair or its scoring. Repeating R1 after explanation is not evidence of transfer. If used after A/B, record that prior teaching. Do not change the protocol's thresholds based on this card.</p>
<div class="footer">No recruitment, recording, account, analytics or distribution is included. Use anonymous notes. An unfinished round is not a loss; unavailable evidence is not a pass.</div>
"""
    answer = f"""
<div class="eyebrow">Starfall · moderator only · page 2 of 3</div><h1>R1 answer and provenance</h1>
<p><strong>Actual context:</strong> 43 cleared, 9 moves left. No choice here is claimed to guarantee the whole round.</p>
<div class="row"><div><h3>A useful smaller clear</h3><p>Clear the <strong>three rose at row 7, columns 1–3</strong>. Known survivors join <strong>at least nine mint</strong>. A second tap gives a total of at least <strong>12</strong> over two moves.</p>
<p>The largest current group has <strong>five mint</strong>, including row 5, column 4. Its best known two-clear floor is <strong>5 + 4 = 9</strong>.</p>
<p>Unknown refill can improve either choice. Do not call another choice a guaranteed loss or the rose choice globally optimal.</p>
<p class="small"><strong>Recognition requires:</strong> identifying the joining survivors, allowing the second tap/move, and separating them from unknown refill. Choosing a triple alone is insufficient.</p></div>
<div><h3>After rose: known survivors only</h3>{board(setup['survivors_top_to_bottom'], compact=True, joined=joined)}
<p class="small">Outlined cells are the nine known mint. <strong>?</strong> means unknown new jewels, not empty game cells.</p></div></div>
<p class="small"><strong>Known mint positions:</strong> {joined_text}.</p>
<h2>Exact reachability inputs</h2>
<div class="provenance"><p>Recorded source: <code>tools/gameplay-study/results-2026-10-16/reachable-examples.json</code>, fourth record. Game seed <strong>{example['seed_provenance_only']}</strong>; nine prior largest-policy taps.</p>
<p><strong>Player row/column, top-down 1–7:</strong><br><code>{esc(json.dumps(player_path))}</code></p>
<p><strong>Core row/column, bottom-up 0–6:</strong><br><code>{esc(json.dumps(example['prior_largest_policy_taps_bottom_zero']))}</code></p>
<p><strong>Verified core SHA-256:</strong><br><code>{core_hash}</code></p>
<p><strong>Repeat:</strong> <code>python3 tools/playtest-kit/build.py --check</code></p></div>
<div class="footer">Seed and tap history establish reachability only. They are not shown to participants and are never evidence of future-RNG prediction. A supplied answer key is not a human result.</div>
"""
    observation = """<div class="observation">
<div class="eyebrow">Starfall · moderator only · page 3 of 3</div><h1>Blank observation sheet</h1>
<p>Anonymous ID: __________ Date: __________ Moderator: __________</p>
<p>Build/source: _____________________ Device / OS: _____________________</p>
<p>Preferred access setup / adjustments / help: ______________________________</p>
<p class="small">U = unaided; A = after help; N = not understood; NO = not observed or unavailable. All fields are blank for collection.</p>
<table class="grid"><tr><th style="width:36%">Live play</th><th>Observation / exact words / help</th></tr>
<tr><td>3+, orthogonal, goal, moves<br>U / A / N / NO: ______</td><td class="blank"></td></tr>
<tr><td>Choice reason before result<br>Multiple groups? ______</td><td class="blank"></td></tr>
<tr><td>Recovery / ending reached?<br>Meaning understood? ______</td><td class="blank"></td></tr>
<tr><td>Shapes, text, touch, narration,<br>focus, settings, motion/sound</td><td class="blank"></td></tr></table>
<p class="checkline">Round finished? ____ Score / moves: ____ / ____ Enough time for another? ____</p>
<p>Stated preference and why: _____________________________________________</p>
<p>Actual action: continue / new round / stop / NO: ____ Reason: ________________</p>
<h2>R1: prompted card evidence</h2>
<p>Before R1: A/B seen? ____ Explanation already heard? ____</p>
<p>Extra two-move prompt used? ____ Explanation accepted / declined / NO: ____</p>
<p>Chosen group + exact predicted survivors <strong>before</strong> answer/help:</p><div class="blanklines"></div>
<p>Second tap/move recognized? ____ Unknown refill distinguished? ____</p>
<p>R1 recognition: observed / not yet / unavailable: ____ Extra help: ______________</p>
<p class="small">Record the original A→B probe separately: A ____ → B ____; help/explanation ____.<br>Do not score R1 or a repeated R1 as that transfer result.</p>
<h2>Experience, after open-ended comments</h2>
<p>Satisfaction ____ / 5 · Control ____ / 5 · Calmness ____ / 5</p>
<p class="small">1 = low, 5 = high; informal ratings, not validated scales.</p>
<p>Specific satisfying/confusing moment; reason for ratings; next issue:</p><div class="blanklines"></div>
<div class="footer">Use NO where an opportunity did not occur. No participant data is prefilled. Bot evidence cannot fill these fields.</div></div>
"""
    return participant, document("Starfall — moderator packet R1", [moderation, answer, observation])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Verify current core and compare generated files without writing them")
    args = parser.parse_args()
    records = json.loads(EXAMPLES.read_text())
    matches = [r for r in records if r["seed_provenance_only"] == "1" and r["score"] == 43 and r["moves"] == 9]
    assert len(matches) == 1, "Expected the retained reachable 3→9 example exactly once"
    example = matches[0]
    spec = importlib.util.spec_from_file_location("visible_survivors", ROOT / "tools/gameplay-study/visible_survivors.py")
    helper = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(helper)
    analysis = helper.analyze(list(reversed(example["board_top_to_bottom"])))
    setup = example["strict_smaller_setups"][0]
    selected = next(a for a in analysis["actions"] if a["anchor_row_column"] == setup["anchor_bottom_zero_row_column"])
    assert selected["immediate_clear"] == 3 and selected["two_clear_floor_if_round_continues"] == 12
    assert selected["survivors_top_to_bottom_question_marks_are_unknown"] == setup["survivors_top_to_bottom"]
    survivor_board = [[None if c == "?" else c for c in row] for row in reversed(setup["survivors_top_to_bottom"])]
    group = max(helper.components(survivor_board), key=len)
    assert len(group) == 9 and all(survivor_board[r][c] == "M" for r, c in group)
    joined = {(7-r, c+1) for r, c in group}
    contrasts = {letter: round(contrast(value[2]), 2) for letter, value in KINDS.items()}
    assert min(contrasts.values()) >= 7, "Print glyph labels must keep strong contrast"
    core_source = CORE.read_bytes()
    core_hash = hashlib.sha256(core_source).hexdigest()
    with tempfile.TemporaryDirectory(prefix="starfall-playtest-kit-") as scratch_name:
        scratch = Path(scratch_name)
        (scratch / "Game.swift").write_bytes(core_source)
        (scratch / "main.swift").write_bytes((HERE / "verify.swift").read_bytes())
        (scratch / "fixture.json").write_text(json.dumps({"example": example, "known_followup_cells_core": sorted(group)}))
        subprocess.run(["swiftc", "-O", "-module-cache-path", str(scratch / "cache"), str(scratch / "Game.swift"), str(scratch / "main.swift"), "-o", str(scratch / "verify")], check=True)
        verified = subprocess.run([str(scratch / "verify"), str(scratch / "fixture.json")], check=True, text=True, capture_output=True).stdout.strip()
    participant, moderator = assemble(example, joined, core_hash)
    for forbidden in ("seed", "RNG", "known nine", "at least nine", "guarantee", "3 + 9", "moderator-packet"):
        assert forbidden.lower() not in participant.lower(), f"Participant answer/provenance leak: {forbidden}"
    for content in (participant, moderator):
        assert '<script' not in content and 'http://' not in content and 'https://' not in content
        assert 'src=' not in content, "All art must be inline and local"
    validation = {
        "status": "passed", "real_core_verification": verified,
        "core_sha256": core_hash, "example_file_sha256": hashlib.sha256(EXAMPLES.read_bytes()).hexdigest(),
        "generator_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        "verifier_sha256": hashlib.sha256((HERE / "verify.swift").read_bytes()).hexdigest(),
        "participant_html_sections": 1, "moderator_html_sections": 3,
        "print_validation": "Separate optional rendering check; these section counts are not measured printed page counts",
        "glyph_letter_contrast_ratios": contrasts,
        "participant_answer_seed_network_checks": "passed",
        "known_followup_player_row_column": sorted(joined),
        "human_observations_collected": 0,
    }
    outputs = {"participant-card.html": participant, "moderator-packet.html": moderator,
               "verification.json": json.dumps(validation, indent=2, sort_keys=True) + "\n"}
    for filename, content in outputs.items():
        destination = HERE / filename
        if args.check:
            assert destination.read_text() == content, f"Stale generated artifact: {destination}"
        else:
            destination.write_text(content)
    print(verified)
    print(f"PASS: {'checked' if args.check else 'built'} participant card, separate 3-section moderator packet, answer isolation, inline-only assets, and ≥7:1 glyph-letter contrast.")


if __name__ == "__main__":
    main()
