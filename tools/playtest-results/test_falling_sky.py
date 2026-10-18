"""Fictional, temporary branch tests only. No participant observations are retained."""
import importlib.util
import json
import re
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("falling_sky", HERE / "falling_sky.py")
tool = importlib.util.module_from_spec(spec)
spec.loader.exec_module(tool)


def fictional(**updates):
    row = tool.blank()
    row.update(state="observed", evidence_kind="synthetic", participant_id="P1", session_id="S1",
               session_date="2026-10-17", experience="first_time", round_kind="new_sky", play_mode="automatic",
               source_sha="a" * 40, build_id="dev.fictional", verified_install="yes",
               generation="gravityOrbits", cadence="fasterV2")
    row.update(updates)
    return row


def choice(**updates):
    return fictional(opal_seen="yes", opal_choice_available="yes", opal_intent="preserve",
                     prediction_before_action="yes", prediction_help="none", prediction_outcome="matched", **updates)


class FallingSkyObservationTests(unittest.TestCase):
    def test_blank_is_not_a_person_or_failed_assessment(self):
        report = tool.summarize([tool.blank()])
        self.assertEqual(report["human"]["sessions"], 0)
        self.assertEqual(report["synthetic_not_human"]["sessions"], 0)
        self.assertEqual(report["not_started_records"], 1)
        self.assertEqual(report["cohorts"], [])

    def test_missing_choice_and_replay_do_not_enter_denominators(self):
        report = tool.summarize([fictional(opal_seen="no"), fictional(session_id="S2", participant_id="P2", opal_seen="yes", opal_choice_available="yes")])
        cohort = report["cohorts"][0]
        self.assertEqual(cohort["deliberate_opal_choice"]["assessed_sessions"], 0)
        self.assertIsNone(cohort["deliberate_opal_choice"]["percent"])
        self.assertEqual(cohort["unassessed_offered_choices"], 1)
        self.assertIsNone(cohort["unprompted_replay_starts"]["percent"])

    def test_deliberate_spending_is_as_valid_as_preserving(self):
        other = choice(session_id="S2", participant_id="P2")
        other["opal_intent"] = "spend"
        cohort = tool.summarize([choice(), other])["cohorts"][0]
        self.assertEqual(cohort["deliberate_opal_choice"]["numerator"], 2)
        self.assertEqual(cohort["opal_intent"], {"preserve": 1, "spend": 1})

    def test_strategy_hints_cannot_inflate_unassisted_predictions(self):
        assisted = choice(session_id="S2", participant_id="P2")
        assisted["prediction_help"] = "strategy_hint"
        neutral = choice(session_id="S3", participant_id="P3")
        neutral["prediction_help"] = "neutral_prompt"
        cohort = tool.summarize([choice(), assisted, neutral])["cohorts"][0]
        self.assertEqual(cohort["prediction_matched_without_strategy_hint"]["assessed_sessions"], 2)
        self.assertEqual(cohort["predictions_by_help"]["none"]["assessed_sessions"], 1)
        self.assertEqual(cohort["predictions_by_help"]["neutral_prompt"]["assessed_sessions"], 1)
        self.assertEqual(cohort["strategy_assisted_predictions"], 1)

    def test_hindsight_and_unclassified_help_are_rejected(self):
        for field, value in [("prediction_before_action", "no"), ("prediction_help", "not_assessed"), ("opal_intent", "not_assessed")]:
            row = choice(); row[field] = value
            with self.subTest(field=field), self.assertRaises(tool.InvalidSession): tool.validate(row)

    def test_replay_interest_and_no_time_do_not_become_replay_failures(self):
        rows = [fictional(participant_id="P1", session_id="S1", replay_time="unavailable", replay_action="stated_interest_only"),
                fictional(participant_id="P2", session_id="S2", replay_time="available", replay_action="unprompted_start"),
                fictional(participant_id="P3", session_id="S3", replay_time="available", replay_action="prompted_start"),
                fictional(participant_id="P4", session_id="S4", replay_time="available", replay_action="declined"),
                fictional(participant_id="P5", session_id="S5", replay_time="available")]
        cohort = tool.summarize(rows)["cohorts"][0]
        self.assertEqual(cohort["unprompted_replay_starts"], {"numerator": 1, "assessed_sessions": 3, "percent": 33.3})
        self.assertEqual(cohort["unassessed_replay_opportunities"], 1)
        row = fictional(replay_time="unavailable", replay_action="unprompted_start")
        with self.assertRaises(tool.InvalidSession): tool.validate(row)

    def test_humans_and_repeated_people_are_not_synthetic_participants(self):
        a = fictional(evidence_kind="human")
        b = fictional(evidence_kind="human", experience="familiar", session_id="S2")
        report = tool.summarize([a, b, fictional()])
        self.assertEqual(report["human"], {"sessions": 2, "distinct_people": 1})
        self.assertEqual(report["synthetic_not_human"], {"sessions": 1, "distinct_people": 1})
        self.assertEqual(len(report["cohorts"]), 3)
        with self.assertRaises(tool.InvalidSession): tool.summarize([a, dict(a, session_id="S2")])
        with self.assertRaises(tool.InvalidSession): tool.summarize([a, dict(a)])

    def test_contexts_and_prepared_automatic_play_remain_separate(self):
        rows = [choice()]
        for i, (field, value) in enumerate([(k, "different") for k in ("source_sha", "build_id", "generation", "cadence", "pace", "device_os")]
                                         + [("round_kind", "prepared"), ("play_mode", "paused"), ("verified_install", "no"), ("settings_changed", "yes")], 2):
            row = choice(participant_id=f"P{i}", session_id=f"S{i}")
            row[field] = "b" * 40 if field == "source_sha" else value
            rows.append(row)
        report = tool.summarize(rows)
        self.assertEqual(len(report["cohorts"]), len(rows))
        self.assertEqual(sum(r["unverified_install_sessions"] for r in report["cohorts"]), 1)

    def test_exposure_and_typed_fields_are_strict(self):
        corruptions = [dict(opal_seen="no", opal_choice_available="yes"),
                       dict(opal_seen="yes", opal_choice_available="no", opal_intent="spend"),
                       dict(schema_version=True), dict(source_sha="abc"), dict(session_date="2026-02-30"),
                       dict(participant_id="Alice"), dict(build_id=["dev.x"]), dict(device_os="iPhone\nname"),
                       dict(state="not_started"), dict(evidence_kind="unclassified"), dict(unexpected="anything")]
        for updates in corruptions:
            with self.subTest(updates=updates), self.assertRaises(tool.InvalidSession): tool.validate(fictional(**updates))

    def test_form_uses_the_authoritative_contract_and_no_network_or_storage(self):
        html = tool.render_form()
        self.assertNotIn("__STARFALL_SESSION_CONTRACT__", html)
        contract = json.loads(re.search(r"const contract = (.*);", html).group(1))
        self.assertEqual(contract["blank"], tool.blank())
        self.assertEqual({key: tuple(value) for key, value in contract["enums"].items()}, tool.ENUMS)
        self.assertEqual(set(contract["choices"] + contract["replay"]), set(tool.OBSERVATIONS))
        self.assertNotRegex(html, r"<script[^>]+src=|<link[^>]+href=|<img[^>]+src=")
        self.assertNotRegex(html, r"fetch\(|XMLHttpRequest|localStorage|sessionStorage")

    def test_cli_blank_roundtrip_no_overwrite_and_duplicate_json_fields(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "blank.json"
            command = [sys.executable, str(HERE / "falling_sky.py")]
            subprocess.run(command + ["new", str(path)], check=True, capture_output=True)
            original = path.read_bytes()
            result = subprocess.run(command + ["summarize", str(path)], check=True, capture_output=True, text=True)
            self.assertEqual(json.loads(result.stdout)["human"]["sessions"], 0)
            self.assertNotEqual(subprocess.run(command + ["new", str(path)], capture_output=True).returncode, 0)
            self.assertEqual(path.read_bytes(), original)
            path.write_text('{"schema_version":1,"schema_version":1}')
            with self.assertRaises(tool.InvalidSession): tool.read(path)
            path.write_text("x" * 65537)
            with self.assertRaises(tool.InvalidSession): tool.read(path)


if __name__ == "__main__":
    unittest.main()
