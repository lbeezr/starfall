#!/usr/bin/env python3
"""Validate anonymous local CSV observations and print a descriptive JSON summary.

No observations are supplied by this program. Human/synthetic labels are declared
by the record author, not authenticated. Input is never changed; nothing is sent.
"""
import argparse
from collections import Counter
import csv
from datetime import date
import json
from pathlib import Path
import re
from statistics import median

SCHEMA = json.loads(Path(__file__).with_name("schema.json").read_text())
FIELDS = [field["name"] for field in SCHEMA["fields"]]
COMPREHENSION = [name for name in FIELDS if name.startswith("comprehension_")]
MISSING = {"", "not_observed"}
ASSESSED = {"pass", "fail"}


class InvalidObservations(ValueError):
    pass


def require(condition, line, message):
    if not condition:
        raise InvalidObservations(f"CSV row {line}: {message}")


def number(value):
    return None if value in MISSING else int(value)


def validate_record(row, line):
    for field in SCHEMA["fields"]:
        name, value = field["name"], row[field["name"]]
        if name == "participant_id":
            require(bool(re.fullmatch(r"P[1-9][0-9]{0,2}", value)), line, "participant_id must be an anonymous ID P1..P999")
        elif not value:
            continue
        elif "values" in field:
            require(value in field["values"], line, f"{name} must use a value listed in schema.json")
        elif field["type"] == "integer":
            if value == "not_observed":
                continue
            require(bool(re.fullmatch(r"0|[1-9][0-9]*", value)), line, f"{name} must be an integer or not_observed")
            require(len(value) <= len(str(field["maximum"])), line, f"{name} is outside its allowed range")
            require(field["minimum"] <= int(value) <= field["maximum"], line, f"{name} is outside its allowed range")
        elif field["type"] == "git_sha":
            require(bool(re.fullmatch(r"[0-9a-f]{40}|[0-9a-f]{64}", value)), line, "build_source_sha must be a full lowercase Git SHA")
        elif field["type"] == "date":
            try:
                parsed = date.fromisoformat(value)
            except ValueError:
                parsed = None
            require(parsed is not None and parsed.isoformat() == value, line, "session_date must be YYYY-MM-DD")

    if row["session_state"] in {"", "not_started"}:
        require(not any(row[key] for key in FIELDS if key not in {"participant_id", "session_state"}),
                line, "a blank/not_started slot cannot contain evidence or observations")
        return
    require(row["evidence_kind"] in {"human", "synthetic"}, line, "an observed session requires evidence_kind")
    if row["recovery_understanding"] not in MISSING:
        require(row["recovery_seen"] == "yes", line, "recovery understanding requires a live recovery observation")
    if row["choice_reason"] not in MISSING:
        require(row["choice_options"] in {"multiple", "forced"}, line, "a choice reason requires observed choice options")
    for probe in ("a", "b"):
        if row[f"{probe}_extra_help"] not in MISSING:
            require(row[f"planning_{probe}"] in ASSESSED, line, f"{probe.upper()} help classification requires an assessed probe")
    if row["r1_recognition"] in {"unavailable", "not_observed", ""}:
        require(row["r1_extra_prompt"] in MISSING, line, "an unavailable/unobserved R1 cannot have a classified prompt")
    if row["replay_start_independent"] not in MISSING:
        require(row["replay_action"] == "new_round", line, "replay independence applies only to a new-round start")

    state = row["round_status"]
    score, moves = number(row["score_at_stop"]), number(row["moves_at_stop"])
    if state == "won" and score is not None:
        require(score >= 70, line, "a won round must have score at least 70")
    if state == "won" and moves is not None:
        require(moves <= 16, line, "a won round requires at least two valid moves")
    if state in {"lost", "unfinished"} and score is not None:
        require(score < 70, line, "a lost/unfinished round must have score below 70")
    if state == "lost" and moves is not None:
        require(moves == 0, line, "a lost round must have zero moves left")
    if state == "lost" and score is not None:
        require(score >= 54, line, "a lost round's 18 valid moves must clear at least 54")
    if state == "unfinished" and moves is not None:
        require(moves > 0, line, "an unfinished round must have moves left")
    if score is not None and moves is not None:
        turns = 18 - moves
        require(3 * turns <= score <= min(49 * turns, 118), line, "score/moves violate the fixed round rules")
    if state in {"won", "lost"}:
        require(row["replay_action"] != "continue", line, "a completed round cannot be continued")
        require(not (row["replay_action"] == "new_round" and row["replay_time"] == "unavailable"),
                line, "a post-ending new round contradicts unavailable replay time")


def read_records(path):
    with Path(path).open(newline="", encoding="utf-8-sig") as stream:
        reader = csv.DictReader(stream, strict=True)
        headers = reader.fieldnames or []
        if len(headers) != len(set(headers)) or set(headers) != set(FIELDS):
            raise InvalidObservations("CSV header must contain each schema field exactly once; unknown/missing columns are rejected")
        rows, ids = [], set()
        for line, raw in enumerate(reader, 2):
            require(None not in raw and all(value is not None for value in raw.values()), line, "wrong number of CSV cells")
            row = {key: value.strip() for key, value in raw.items()}
            validate_record(row, line)
            require(row["participant_id"] not in ids, line, "participant_id must be unique within this file")
            ids.add(row["participant_id"])
            rows.append(row)
    return rows


def counts(rows, field):
    return dict(sorted(Counter(row[field] or "missing" for row in rows).items()))


def ratio(numerator, denominator, minimum=1):
    return {
        "numerator": numerator, "assessed_denominator": denominator,
        "percent": round(100 * numerator / denominator, 2) if denominator else None,
        "minimum_assessed_for_protocol_context": minimum,
        "evidence": "insufficient_evidence" if denominator < minimum else "descriptive_only",
    }


def summarize_group(observed):
    # The protocol is for first-time participants. Returning/unclassified records
    # remain in the input and the eligibility counts, never silently in its rates.
    rows = [row for row in observed if row["first_time"] == "yes"]
    complete = [row for row in rows if all(row[key] in {"unaided", "assisted", "not_understood"} for key in COMPREHENSION)]
    unaided = sum(all(row[key] == "unaided" for key in COMPREHENSION) for row in complete)
    assisted = sum(all(row[key] in {"unaided", "assisted"} for key in COMPREHENSION) and
                   any(row[key] == "assisted" for key in COMPREHENSION) for row in complete)
    choices = [r for r in rows if r["choice_options"] == "multiple" and r["choice_reason"] not in MISSING]
    recovery_seen = [r for r in rows if r["recovery_seen"] == "yes"]
    recovery_assessed = [r for r in recovery_seen if r["recovery_understanding"] not in MISSING]

    eligible = [r for r in rows if r["round_status"] in {"won", "lost"} and r["replay_time"] == "available"]
    replay_assessed = [r for r in eligible if r["replay_action"] == "stop" or
                       (r["replay_action"] == "new_round" and r["replay_start_independent"] in {"yes", "no"})]
    independent = sum(r["replay_action"] == "new_round" and r["replay_start_independent"] == "yes" for r in replay_assessed)
    interest = [r for r in rows if r["stated_replay_interest"] in {"yes", "no", "unsure"}]

    b_without_help = [r for r in rows if r["planning_b"] in ASSESSED and r["b_extra_help"] == "no"]
    transitions = {}
    for explanation in ("accepted", "declined", "not_offered", "not_observed", ""):
        group = [r for r in rows if r["gravity_explanation"] == explanation]
        paired = [r for r in group if r["planning_a"] in ASSESSED and r["planning_b"] in ASSESSED and
                  r["a_extra_help"] == "no" and r["b_extra_help"] == "no"]
        initial_fail_baselines = [r for r in group if r["planning_a"] == "fail" and r["a_extra_help"] == "no"]
        initially_unsuccessful = [r for r in paired if r["planning_a"] == "fail"]
        transitions[explanation or "missing"] = {
            "records": len(group), "paired_assessed_without_extra_probe_help": len(paired),
            "initial_fail_baselines_without_help": len(initial_fail_baselines),
            "initial_fail_followup_unassessed_or_helped": len(initial_fail_baselines) - len(initially_unsuccessful),
            "transitions": dict(sorted(Counter(r["planning_a"] + "_to_" + r["planning_b"] for r in paired).items())),
            "initial_fail_to_b_pass": ratio(sum(r["planning_b"] == "pass" for r in initially_unsuccessful),
                                            len(initially_unsuccessful), 3),
            "unpaired_or_helped_records": len(group) - len(paired),
        }
    ratings = {}
    for key in ("satisfaction", "control", "calmness"):
        values = [number(r[key]) for r in rows if r[key] not in MISSING]
        ratings[key] = {"assessed_denominator": len(values), "median": median(values) if values else None,
                        "recorded_values": counts(rows, key), "evidence": "descriptive_only" if values else "insufficient_evidence"}
    return {
        "observed_records": len(observed), "first_time_classification": counts(observed, "first_time"),
        "protocol_scope": "Only records explicitly marked first_time=yes; all rates are descriptive",
        "protocol_records": len(rows), "excluded_returning_or_unclassified": len(observed) - len(rows),
        "comprehension": {"assessed_all_four": len(complete), "incomplete_assessment": len(rows) - len(complete),
                          "all_four_unaided": ratio(unaided, len(complete), 6),
                          "all_four_understood_with_assistance": ratio(assisted, len(complete), 6),
                          "one_or_more_not_understood_among_complete_assessments": len(complete) - unaided - assisted,
                          "by_rule": {key: counts(rows, key) for key in COMPREHENSION}},
        "choice": {"options": counts(rows, "choice_options"), "reasons": counts(rows, "choice_reason"),
                   "reasoned_multiple_option_choice": ratio(sum(r["choice_reason"] in {"current_size", "correct_survivors"} for r in choices), len(choices), 6),
                   "unassessed_multiple_option_choices": sum(r["choice_options"] == "multiple" and r["choice_reason"] in MISSING for r in rows)},
        "recovery": {"exposure": counts(rows, "recovery_seen"), "live_observers": len(recovery_seen),
                     "unassessed_live_observers": len(recovery_seen) - len(recovery_assessed),
                     "understood": ratio(sum(r["recovery_understanding"] == "understood" for r in recovery_assessed), len(recovery_assessed), 3)},
        "rounds": counts(rows, "round_status"),
        "replay": {"eligible_finished_with_time": len(eligible), "unassessed_eligible": len(eligible) - len(replay_assessed),
                   "independent_starts": ratio(independent, len(replay_assessed), 4),
                   "directed_starts": sum(r["replay_action"] == "new_round" and r["replay_start_independent"] == "no" for r in replay_assessed),
                   "declined_starts": sum(r["replay_action"] == "stop" for r in replay_assessed),
                   "finished_without_time": sum(r["round_status"] in {"won", "lost"} and r["replay_time"] == "unavailable" for r in rows),
                   "finished_time_unassessed": sum(r["round_status"] in {"won", "lost"} and r["replay_time"] in MISSING for r in rows),
                   "continued_unfinished": sum(r["round_status"] == "unfinished" and r["replay_action"] == "continue" for r in rows),
                   "restarted_unfinished": sum(r["round_status"] == "unfinished" and r["replay_action"] == "new_round" for r in rows),
                   "round_status_unassessed": sum(r["round_status"] in MISSING for r in rows),
                   "stated_interest": counts(rows, "stated_replay_interest"),
                   "stated_yes_among_asked": ratio(sum(r["stated_replay_interest"] == "yes" for r in interest), len(interest))},
        "planning_ab": {"a": counts(rows, "planning_a"), "b": counts(rows, "planning_b"),
                        "a_extra_help": counts(rows, "a_extra_help"), "b_extra_help": counts(rows, "b_extra_help"),
                        "b_pass_without_extra_help": ratio(sum(r["planning_b"] == "pass" for r in b_without_help), len(b_without_help), 6),
                        "transitions_by_explanation": transitions,
                        "interpretation": "Descriptive paired observations only; no causal teaching or general mastery claim"},
        "r1_supplementary": {key: counts(rows, key) for key in ("r1_recognition", "r1_prior_ab", "r1_prior_explanation", "r1_extra_prompt")},
        "ratings": ratings,
    }


def summarize(records):
    observed = [r for r in records if r["session_state"] == "observed"]
    return {
        "schema_version": SCHEMA["schema_version"], "input_slots": len(records),
        "blank_or_not_started_slots": len(records) - len(observed),
        "observed_human_records": sum(r["evidence_kind"] == "human" for r in observed),
        "synthetic_test_records": sum(r["evidence_kind"] == "synthetic" for r in observed),
        "human": summarize_group([r for r in observed if r["evidence_kind"] == "human"]),
        "synthetic_not_human_results": summarize_group([r for r in observed if r["evidence_kind"] == "synthetic"]),
        "limits": "Missing/unobserved/unavailable values are not failures. No threshold, tuning, release, retention or causal decision is made. CSV labels do not authenticate observations.",
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("csv_path", type=Path)
    parser.add_argument("--validate-only", action="store_true")
    args = parser.parse_args()
    try:
        records = read_records(args.csv_path)
        result = summarize(records)
    except (OSError, UnicodeError, csv.Error, InvalidObservations) as error:
        parser.exit(2, f"Invalid observations: {error}\n")
    if args.validate_only:
        result = {key: result[key] for key in ("schema_version", "input_slots", "blank_or_not_started_slots", "observed_human_records", "synthetic_test_records")}
        result["validation"] = "passed"
    print(json.dumps(result, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
