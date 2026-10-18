#!/usr/bin/env python3
"""Create and summarize anonymous local falling-sky observations. No telemetry or network.

Labels are entered by an observer; this tool cannot authenticate human participation,
installation provenance, or honest prediction timing. No observations are supplied.
"""
import argparse
from collections import Counter
from datetime import date
import json
from pathlib import Path
import re

# One authoritative contract; classical schema.json and summarize.py stay historical.
ENUMS = {
    "state": ("not_started", "observed"),
    "evidence_kind": ("unclassified", "human", "synthetic"),
    "experience": ("not_assessed", "first_time", "familiar"),
    "verified_install": ("not_assessed", "yes", "no"),
    "round_kind": ("not_assessed", "new_sky", "retained_sky", "same_sky_replay", "first_light", "prepared"),
    "play_mode": ("not_assessed", "automatic", "paused", "mixed"),
    "reduce_motion": ("not_assessed", "on", "off"),
    "calm_effects": ("not_assessed", "on", "off"),
    "voiceover": ("not_assessed", "on", "off"),
    "sound": ("not_assessed", "on", "off"),
    "haptics": ("not_assessed", "on", "off"),
    "settings_changed": ("not_assessed", "yes", "no"),
    "storm": ("not_assessed", "not_reached", "no_change", "changed_speed", "changed_group_or_order"),
    "opal_seen": ("not_assessed", "yes", "no"),
    "opal_choice_available": ("not_assessed", "yes", "no"),
    "opal_intent": ("not_assessed", "not_noticed", "no_deliberate_preference", "spend", "preserve"),
    "prediction_before_action": ("not_assessed", "yes", "no"),
    "prediction_help": ("not_assessed", "none", "neutral_prompt", "strategy_hint"),
    "prediction_outcome": ("not_assessed", "matched", "mismatched"),
    "input_problem": ("not_assessed", "yes", "no"),
    "replay_time": ("not_assessed", "available", "unavailable"),
    "replay_action": ("not_assessed", "unprompted_start", "prompted_start", "declined", "stated_interest_only"),
    "round_outcome": ("not_assessed", "playing", "full_sky", "challenge_complete", "stopped"),
}
TEXT = ("session_id", "participant_id", "session_date", "source_sha", "build_id", "generation", "cadence",
        "device_os", "text_size", "pace", "dark_frequency")
FIELDS = {"schema_version", *TEXT, *ENUMS}
OBSERVATIONS = ("storm", "opal_seen", "opal_choice_available", "opal_intent", "prediction_before_action",
                "prediction_help", "prediction_outcome", "input_problem", "replay_time", "replay_action", "round_outcome")
CONTEXT = ("source_sha", "build_id", "verified_install", "generation", "cadence", "round_kind", "play_mode",
           "device_os", "text_size", "pace", "dark_frequency", "reduce_motion", "calm_effects", "voiceover",
           "sound", "haptics", "settings_changed", "experience")
MISSING = {"", "not_assessed"}


class InvalidSession(ValueError):
    pass


def require(condition, message):
    if not condition:
        raise InvalidSession(message)


def blank():
    return {"schema_version": 1, **dict.fromkeys(TEXT, ""), **{key: values[0] for key, values in ENUMS.items()}}


def validate(row):
    require(isinstance(row, dict) and set(row) == FIELDS, "fields must exactly match the falling-sky template")
    require(type(row["schema_version"]) is int and row["schema_version"] == 1, "unsupported schema_version")
    for key in TEXT:
        value = row[key]
        require(type(value) is str and value == value.strip() and len(value) <= 100 and
                not any(ord(c) < 32 for c in value), f"{key} must be short plain text")
    for key, values in ENUMS.items():
        require(type(row[key]) is str and row[key] in values, f"invalid {key}")
    for key, pattern in (("participant_id", r"P[1-9][0-9]{0,2}"), ("session_id", r"S[1-9][0-9]{0,4}"),
                         ("source_sha", r"[0-9a-f]{40}|[0-9a-f]{64}")):
        require(not row[key] or re.fullmatch(pattern, row[key]) is not None, f"invalid {key}")
    if row["session_date"]:
        try:
            parsed = date.fromisoformat(row["session_date"])
        except ValueError:
            raise InvalidSession("session_date must be YYYY-MM-DD") from None
        require(parsed.isoformat() == row["session_date"], "session_date must be YYYY-MM-DD")
    if row["state"] == "not_started":
        require(row["evidence_kind"] == "unclassified" and all(row[k] == "not_assessed" for k in OBSERVATIONS),
                "not_started records cannot contain evidence or observations")
        return row
    require(row["participant_id"] and row["session_id"] and row["session_date"], "observed sessions need anonymous IDs and date")
    require(row["evidence_kind"] in {"human", "synthetic"}, "observed sessions need an evidence_kind")
    if row["verified_install"] == "yes":
        require(row["source_sha"] and row["build_id"], "verified_install needs the installed source SHA and build ID")
    if row["opal_choice_available"] not in MISSING:
        require(row["opal_seen"] == "yes", "Opal choice assessment requires observed Opal exposure")
    if row["opal_intent"] not in MISSING:
        require(row["opal_seen"] == "yes" and row["opal_choice_available"] == "yes",
                "Opal intent requires an observed choice, not merely an Opal")
    if row["prediction_outcome"] not in MISSING:
        require(row["prediction_before_action"] == "yes" and row["prediction_help"] not in MISSING and
                row["opal_intent"] in {"spend", "preserve"},
                "prediction accuracy needs deliberate Opal intent, before-action recording and help classification")
    if row["prediction_help"] not in MISSING:
        require(row["prediction_before_action"] == "yes", "help classification requires a before-action prediction")
    if row["replay_action"] in {"unprompted_start", "prompted_start", "declined"}:
        require(row["replay_time"] == "available", "observed replay action requires available replay time")
    return row


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        require(key not in result, f"duplicate JSON field: {key}")
        result[key] = value
    return result


def read(path):
    path = Path(path)
    require(path.stat().st_size <= 65536, "session exceeds 64 KiB")
    return validate(json.loads(path.read_text(encoding="utf-8-sig"), object_pairs_hook=unique_object))


def counts(rows, key):
    return dict(sorted(Counter(row[key] or "missing" for row in rows).items()))


def rate(numerator, denominator):
    return {"numerator": numerator, "assessed_sessions": denominator,
            "percent": round(100 * numerator / denominator, 1) if denominator else None}


def summarize(records):
    records = [validate(r) for r in records]
    observed = [r for r in records if r["state"] == "observed"]
    ids, firsts = set(), set()
    for row in observed:
        identity = (row["evidence_kind"], row["session_id"])
        require(identity not in ids, "duplicate observed session_id")
        ids.add(identity)
        person = (row["evidence_kind"], row["participant_id"])
        if row["experience"] == "first_time":
            require(person not in firsts, "one participant cannot supply two first-time sessions")
            firsts.add(person)
    groups = {}
    for row in observed:
        key = (row["evidence_kind"], *(row[k] for k in CONTEXT))
        groups.setdefault(key, []).append(row)
    cohorts = []
    for key, rows in sorted(groups.items()):
        choices = [r for r in rows if r["opal_choice_available"] == "yes"]
        intent = [r for r in choices if r["opal_intent"] not in MISSING]
        predictions = [r for r in rows if r["prediction_outcome"] not in MISSING and r["prediction_help"] in {"none", "neutral_prompt"}]
        replay = [r for r in rows if r["replay_time"] == "available" and r["replay_action"] in {"unprompted_start", "prompted_start", "declined"}]
        cohorts.append({
            "evidence_kind": key[0], "context": {k: rows[0][k] for k in CONTEXT},
            "observed_sessions": len(rows), "distinct_people": len({r["participant_id"] for r in rows}),
            "unverified_install_sessions": sum(r["verified_install"] != "yes" for r in rows),
            "storm": counts(rows, "storm"), "opal_exposure": counts(rows, "opal_seen"),
            "opal_choices": counts(rows, "opal_choice_available"), "opal_intent": counts(rows, "opal_intent"),
            "unassessed_offered_choices": len(choices) - len(intent),
            "deliberate_opal_choice": rate(sum(r["opal_intent"] in {"spend", "preserve"} for r in intent), len(intent)),
            "prediction_matched_without_strategy_hint": rate(sum(r["prediction_outcome"] == "matched" for r in predictions), len(predictions)),
            "predictions_by_help": {help_kind: rate(
                sum(r["prediction_help"] == help_kind and r["prediction_outcome"] == "matched" for r in rows),
                sum(r["prediction_help"] == help_kind and r["prediction_outcome"] not in MISSING for r in rows))
                for help_kind in ("none", "neutral_prompt", "strategy_hint")},
            "strategy_assisted_predictions": sum(r["prediction_help"] == "strategy_hint" and r["prediction_outcome"] not in MISSING for r in rows),
            "input_problems": counts(rows, "input_problem"), "outcomes": counts(rows, "round_outcome"),
            "replay_actions": counts(rows, "replay_action"), "replay_time": counts(rows, "replay_time"),
            "unassessed_replay_opportunities": sum(r["replay_time"] == "available" and r["replay_action"] not in {"unprompted_start", "prompted_start", "declined"} for r in rows),
            "unprompted_replay_starts": rate(sum(r["replay_action"] == "unprompted_start" for r in replay), len(replay)),
        })
    def totals(kind):
        rows = [r for r in observed if r["evidence_kind"] == kind]
        return {"sessions": len(rows), "distinct_people": len({r["participant_id"] for r in rows})}
    return {"schema_version": 1, "input_records": len(records), "not_started_records": len(records)-len(observed),
            "human": totals("human"), "synthetic_not_human": totals("synthetic"), "cohorts": cohorts,
            "limits": "Observer-declared labels. Rates describe sessions, not independent people. Exact cohorts are kept separate; prepared/paused/familiar runs cannot establish cold automatic-play enjoyment. Missing assessments are not failures. No tuning/adoption or causal conclusion is made."}


def render_form():
    template = Path(__file__).with_name("falling-sky-session.html").read_text(encoding="utf-8")
    token = "__STARFALL_SESSION_CONTRACT__"
    require(template.count(token) == 1, "form template contract marker changed")
    contract = {"blank": blank(), "enums": ENUMS,
                "choices": list(OBSERVATIONS[:7]), "replay": list(OBSERVATIONS[7:])}
    return template.replace(token, json.dumps(contract).replace("<", "\\u003c"))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    new = commands.add_parser("new", help="write an entirely unobserved session; never overwrite")
    new.add_argument("output", type=Path)
    form = commands.add_parser("form", help="write a standalone offline moderator form; never overwrite")
    form.add_argument("output", type=Path)
    report = commands.add_parser("summarize")
    report.add_argument("sessions", nargs="+", type=Path)
    args = parser.parse_args()
    try:
        if args.command == "form":
            with args.output.open("x", encoding="utf-8") as stream:
                stream.write(render_form())
            print(f"Offline moderator form: {args.output}")
        elif args.command == "new":
            with args.output.open("x", encoding="utf-8") as stream:
                json.dump(blank(), stream, indent=2); stream.write("\n")
            print(f"Blank session: {args.output}")
        else:
            print(json.dumps(summarize([read(p) for p in args.sessions]), indent=2, sort_keys=True))
    except (OSError, UnicodeError, json.JSONDecodeError, InvalidSession) as error:
        parser.exit(2, f"Invalid session: {error}\n")


if __name__ == "__main__":
    main()
