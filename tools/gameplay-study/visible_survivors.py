#!/usr/bin/env python3
"""Describe guaranteed survivor groups after each legal clear, without refill RNG.

Study aid only: does not execute StarfallCore, rate a complete turn, model humans,
or establish seed solvability. Row zero is bottom, columns run left to right.
Run without arguments for a synthetic lesson board, or pass a JSON file containing
{"rows_bottom_to_top": ["RTTVMRA", ... seven rows ...]}.
Kinds: R rose, A aqua, T amber triangle, V violet, M mint.
"""

import argparse
import json
from pathlib import Path

SIDE = 7
KINDS = frozenset("RATVM")
DEMO = ["RTTVMRA", "RVVMRAT", "ARMRATV", "ARRATVM", "ATATVMR",
        "RVRARAR", "RTMMMMM"]


def components(board):
    """Return all nonempty orthogonal components in bottom-row-first order."""
    seen = set()
    result = []
    for row in range(SIDE):
        for column in range(SIDE):
            start = (row, column)
            kind = board[row][column]
            if kind is None or start in seen:
                continue
            seen.add(start)
            pending = [start]
            group = set()
            while pending:
                cell = pending.pop()
                group.add(cell)
                r, c = cell
                for neighbor in ((r - 1, c), (r + 1, c), (r, c - 1), (r, c + 1)):
                    nr, nc = neighbor
                    if (0 <= nr < SIDE and 0 <= nc < SIDE
                            and neighbor not in seen and board[nr][nc] == kind):
                        seen.add(neighbor)
                        pending.append(neighbor)
            result.append(group)
    return result


def settle_survivors(board, cleared):
    """Compact each column; unknown refill slots stay None above survivors."""
    settled = [[None] * SIDE for _ in range(SIDE)]
    for column in range(SIDE):
        survivors = [board[row][column] for row in range(SIDE)
                     if (row, column) not in cleared]
        for row, kind in enumerate(survivors):
            settled[row][column] = kind
    return settled


def analyze(rows):
    if (not isinstance(rows, list) or len(rows) != SIDE
            or any(not isinstance(row, str) or len(row) != SIDE
                   or not set(row) <= KINDS for row in rows)):
        raise ValueError("Expected seven bottom-to-top strings of seven RATVM kinds")
    board = [list(row) for row in rows]
    actions = []
    for group in components(board):
        if len(group) < 3:
            continue
        row, column = min(group)
        settled = settle_survivors(board, group)
        known_sizes = sorted((len(other) for other in components(settled)
                              if len(other) >= 3), reverse=True)
        largest = max(known_sizes, default=0)
        actions.append({
            "anchor_row_column": [row, column],
            "kind": board[row][column],
            "immediate_clear": len(group),
            "guaranteed_next_component_sizes": known_sizes,
            "two_clear_floor_if_round_continues": len(group) + largest,
            "survivors_top_to_bottom_question_marks_are_unknown": [
                "".join(kind if kind is not None else "?" for kind in line)
                for line in reversed(settled)
            ],
        })
    return {"rows_bottom_to_top": rows, "actions": actions,
            "limits": "No refill, repair, terminal-state or human model; no seed input"}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("board_json", nargs="?", type=Path)
    args = parser.parse_args()
    try:
        rows = (json.loads(args.board_json.read_text())["rows_bottom_to_top"]
                if args.board_json else DEMO)
        result = analyze(rows)
    except (OSError, ValueError, KeyError, TypeError) as error:
        parser.exit(2, f"Invalid study board: {error}\n")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
