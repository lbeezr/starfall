"""Fictional unit inputs only, written under TemporaryDirectory.

Even records tagged human below are invented branch tests, never observations.
No populated participant data or synthetic result is saved in the repository.
"""
import csv
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("playtest_summary", HERE / "summarize.py")
summary = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(summary)


def fictional(identifier="P1", **values):
    row = dict.fromkeys(summary.FIELDS, "")
    row.update(participant_id=identifier, session_state="observed", evidence_kind="synthetic", first_time="yes")
    row.update(values)
    return row


class ObservationTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="starfall-fictional-observations-")
        self.addCleanup(self.directory.cleanup)
        self.path = Path(self.directory.name) / "fictional-only.csv"

    def write(self, rows, fields=None):
        with self.path.open("w", newline="", encoding="utf-8") as stream:
            writer = csv.DictWriter(stream, fieldnames=fields or summary.FIELDS)
            writer.writeheader()
            writer.writerows(rows)
        return self.path

    def analyze(self, rows):
        return summary.summarize(summary.read_records(self.write(rows)))

    def group(self, rows):
        return self.analyze(rows)["synthetic_not_human_results"]

    def test_blank_template_contains_no_observations(self):
        rows = summary.read_records(HERE / "blank-observations.csv")
        result = summary.summarize(rows)
        self.assertEqual([row["participant_id"] for row in rows], [f"P{i}" for i in range(1, 7)])
        self.assertTrue(all(not value for row in rows for key, value in row.items() if key != "participant_id"))
        self.assertEqual(result["blank_or_not_started_slots"], 6)
        self.assertEqual(result["observed_human_records"], 0)
        self.assertEqual(result["synthetic_test_records"], 0)
        for group in (result["human"], result["synthetic_not_human_results"]):
            self.assertIsNone(group["replay"]["independent_starts"]["percent"])
            self.assertEqual(group["comprehension"]["all_four_unaided"]["evidence"], "insufficient_evidence")
            self.assertEqual(group["comprehension"]["one_or_more_not_understood_among_complete_assessments"], 0)
            self.assertIsNone(group["ratings"]["calmness"]["median"])

    def test_human_labels_separate_from_synthetic_and_eligibility(self):
        result = self.analyze([
            fictional("P1", evidence_kind="human", satisfaction="5"),
            fictional("P2", satisfaction="1"),
            fictional("P3", evidence_kind="human", first_time="no", satisfaction="1"),
            fictional("P4", evidence_kind="human", first_time="", satisfaction="1"),
        ])
        self.assertEqual(result["observed_human_records"], 3)
        self.assertEqual(result["synthetic_test_records"], 1)
        self.assertEqual(result["human"]["protocol_records"], 1)
        self.assertEqual(result["human"]["excluded_returning_or_unclassified"], 2)
        self.assertEqual(result["human"]["ratings"]["satisfaction"]["median"], 5)
        self.assertEqual(result["synthetic_not_human_results"]["ratings"]["satisfaction"]["median"], 1)

    def test_unaided_assisted_and_incomplete_comprehension(self):
        all_unaided = dict.fromkeys(summary.COMPREHENSION, "unaided")
        result = self.group([
            fictional("P1", **all_unaided),
            fictional("P2", **(all_unaided | {"comprehension_goal": "assisted"})),
            fictional("P3", **(all_unaided | {"comprehension_goal": "not_understood"})),
            fictional("P4", **(all_unaided | {"comprehension_goal": "not_observed"})),
            fictional("P5"),
        ])["comprehension"]
        self.assertEqual(result["assessed_all_four"], 3)
        self.assertEqual(result["incomplete_assessment"], 2)
        self.assertEqual(result["all_four_unaided"]["numerator"], 1)
        self.assertEqual(result["all_four_understood_with_assistance"]["numerator"], 1)
        self.assertEqual(result["one_or_more_not_understood_among_complete_assessments"], 1)
        self.assertEqual(result["all_four_unaided"]["assessed_denominator"], 3)
        self.assertEqual(result["all_four_unaided"]["evidence"], "insufficient_evidence")

    def test_choice_and_recovery_only_use_assessed_exposure(self):
        group = self.group([
            fictional("P1", choice_options="multiple", choice_reason="current_size", recovery_seen="yes", recovery_understanding="understood"),
            fictional("P2", choice_options="multiple", choice_reason="other", recovery_seen="yes", recovery_understanding="not_observed"),
            fictional("P3", choice_options="forced", choice_reason="correct_survivors", recovery_seen="no"),
            fictional("P4", choice_options="multiple", recovery_seen="not_observed"),
        ])
        self.assertEqual(group["choice"]["reasoned_multiple_option_choice"]["numerator"], 1)
        self.assertEqual(group["choice"]["reasoned_multiple_option_choice"]["assessed_denominator"], 2)
        self.assertEqual(group["choice"]["unassessed_multiple_option_choices"], 1)
        self.assertEqual(group["recovery"]["live_observers"], 2)
        self.assertEqual(group["recovery"]["unassessed_live_observers"], 1)
        self.assertEqual(group["recovery"]["understood"]["assessed_denominator"], 1)

    def test_replay_requires_ending_time_and_independent_action(self):
        completed = dict(round_status="won", replay_time="available")
        rows = [
            fictional("P1", **completed, replay_action="new_round", replay_start_independent="yes", stated_replay_interest="no"),
            fictional("P2", **completed, replay_action="new_round", replay_start_independent="no"),
            fictional("P3", **completed, replay_action="stop"),
            fictional("P4", **completed, replay_action="new_round"),
            fictional("P5", round_status="unfinished", replay_action="continue", stated_replay_interest="yes"),
            fictional("P6", round_status="lost", replay_time="unavailable", stated_replay_interest="yes"),
            fictional("P7", round_status="lost", replay_time="not_observed"),
            fictional("P8", round_status="unfinished", replay_action="new_round", replay_start_independent="yes"),
        ]
        replay = self.group(rows)["replay"]
        self.assertEqual(replay["eligible_finished_with_time"], 4)
        self.assertEqual(replay["unassessed_eligible"], 1)
        self.assertEqual(replay["independent_starts"]["numerator"], 1)
        self.assertEqual(replay["independent_starts"]["assessed_denominator"], 3)
        self.assertEqual(replay["independent_starts"]["evidence"], "insufficient_evidence")
        for field in ("directed_starts", "declined_starts", "continued_unfinished", "restarted_unfinished", "finished_without_time", "finished_time_unassessed"):
            self.assertEqual(replay[field], 1)
        self.assertEqual(replay["stated_yes_among_asked"]["numerator"], 2)
        self.assertEqual(replay["stated_yes_among_asked"]["assessed_denominator"], 3)

    def test_unavailable_probes_and_r1_do_not_become_transfer_failures(self):
        group = self.group([
            fictional("P1", planning_a="unavailable", planning_b="unavailable", r1_recognition="observed", r1_extra_prompt="no"),
            fictional("P2", planning_a="not_observed", planning_b="not_observed", r1_recognition="unavailable"),
            fictional("P3"),
        ])
        planning = group["planning_ab"]
        self.assertEqual(planning["b_pass_without_extra_help"]["assessed_denominator"], 0)
        self.assertIsNone(planning["b_pass_without_extra_help"]["percent"])
        self.assertEqual(planning["a"], {"missing": 1, "not_observed": 1, "unavailable": 1})
        self.assertEqual(group["r1_supplementary"]["r1_recognition"]["observed"], 1)
        self.assertEqual(planning["transitions_by_explanation"]["missing"]["paired_assessed_without_extra_probe_help"], 0)

    def test_paired_transfer_excludes_help_and_keeps_explanation_groups(self):
        pair = dict(planning_a="fail", a_extra_help="no", planning_b="pass", b_extra_help="no", gravity_explanation="accepted")
        group = self.group([
            fictional("P1", **pair),
            fictional("P2", **(pair | {"gravity_explanation": "declined"})),
            fictional("P3", **(pair | {"b_extra_help": "yes"})),
            fictional("P4", **(pair | {"a_extra_help": "yes"})),
            fictional("P5", **(pair | {"planning_b": "unavailable", "b_extra_help": ""})),
            fictional("P6", **(pair | {"a_extra_help": ""})),
        ])["planning_ab"]
        accepted = group["transitions_by_explanation"]["accepted"]
        self.assertEqual(accepted["transitions"], {"fail_to_pass": 1})
        self.assertEqual(accepted["initial_fail_baselines_without_help"], 3)
        self.assertEqual(accepted["initial_fail_followup_unassessed_or_helped"], 2)
        self.assertEqual(accepted["initial_fail_to_b_pass"]["assessed_denominator"], 1)
        self.assertEqual(accepted["initial_fail_to_b_pass"]["evidence"], "insufficient_evidence")
        self.assertEqual(group["transitions_by_explanation"]["declined"]["transitions"], {"fail_to_pass": 1})
        self.assertEqual(group["b_pass_without_extra_help"]["assessed_denominator"], 4)

    def test_ratings_count_missing_without_zero_imputation(self):
        ratings = self.group([
            fictional("P1", satisfaction="5", control="1"),
            fictional("P2", satisfaction="3", control="not_observed"),
            fictional("P3", satisfaction="not_observed"),
            fictional("P4"),
        ])["ratings"]
        self.assertEqual(ratings["satisfaction"]["median"], 4)
        self.assertEqual(ratings["satisfaction"]["assessed_denominator"], 2)
        self.assertEqual(ratings["satisfaction"]["recorded_values"], {"3": 1, "5": 1, "missing": 1, "not_observed": 1})
        self.assertIsNone(ratings["calmness"]["median"])

    def test_malformed_field_values_rejected(self):
        for changes in [
            {"participant_id": "Alice"}, {"participant_id": "P0"}, {"evidence_kind": "bot"},
            {"satisfaction": "0"}, {"satisfaction": "6"}, {"control": "2.5"},
            {"calmness": "05"}, {"moves_at_stop": "19"}, {"score_at_stop": "119"},
            {"session_date": "2026-02-30"}, {"session_date": "20261016"},
            {"build_source_sha": "abc123"}, {"planning_b": "good"},
        ]:
            with self.subTest(changes=changes), self.assertRaises(summary.InvalidObservations):
                summary.read_records(self.write([fictional(**changes)]))

    def test_contradictions_rejected(self):
        for changes in [
            {"session_state": "not_started"}, {"evidence_kind": ""},
            {"recovery_seen": "no", "recovery_understanding": "understood"},
            {"choice_reason": "current_size"},
            {"planning_b": "unavailable", "b_extra_help": "no"},
            {"planning_a": "not_observed", "a_extra_help": "yes"},
            {"r1_recognition": "unavailable", "r1_extra_prompt": "no"},
            {"replay_action": "stop", "replay_start_independent": "yes"},
            {"round_status": "won", "score_at_stop": "69"},
            {"round_status": "won", "moves_at_stop": "18"},
            {"round_status": "won", "moves_at_stop": "17"},
            {"round_status": "lost", "moves_at_stop": "1"},
            {"round_status": "lost", "score_at_stop": "70"},
            {"round_status": "lost", "score_at_stop": "53"},
            {"round_status": "unfinished", "moves_at_stop": "0"},
            {"round_status": "unfinished", "score_at_stop": "70"},
            {"score_at_stop": "1", "moves_at_stop": "17"},
            {"score_at_stop": "50", "moves_at_stop": "17"},
            {"round_status": "won", "replay_action": "continue"},
            {"round_status": "lost", "replay_time": "unavailable", "replay_action": "new_round"},
        ]:
            with self.subTest(changes=changes), self.assertRaises(summary.InvalidObservations):
                summary.read_records(self.write([fictional(**changes)]))

    def test_legal_last_move_win_and_partial_state_accepted(self):
        rows = summary.read_records(self.write([
            fictional("P1", round_status="won", score_at_stop="70", moves_at_stop="0"),
            fictional("P2", round_status="lost", score_at_stop="54", moves_at_stop="0"),
            fictional("P3", round_status="unfinished", score_at_stop="0", moves_at_stop="18"),
            fictional("P4", round_status="won", score_at_stop="not_observed"),
        ]))
        self.assertEqual(len(rows), 4)

    def test_headers_row_width_and_duplicate_ids_rejected(self):
        with self.assertRaises(summary.InvalidObservations):
            summary.read_records(self.write([fictional(), fictional()]))
        for header in [summary.FIELDS[:-1], summary.FIELDS + ["name"], summary.FIELDS + [summary.FIELDS[0]]]:
            with self.subTest(header=header), self.assertRaises(summary.InvalidObservations):
                self.write([], header)
                summary.read_records(self.path)
        self.write([])
        with self.path.open("a") as stream:
            stream.write("P1,synthetic\n")
        with self.assertRaises(summary.InvalidObservations):
            summary.read_records(self.path)
        self.write([])
        with self.path.open("a") as stream:
            stream.write(",".join(["P1"] * (len(summary.FIELDS) + 1)) + "\n")
        with self.assertRaises(summary.InvalidObservations):
            summary.read_records(self.path)
        self.write([])
        with self.path.open("a") as stream:
            stream.write('"unclosed')
        with self.assertRaises(csv.Error):
            summary.read_records(self.path)

    def test_cli_reproducible_and_invalid_input_emits_no_summary(self):
        self.write([fictional(satisfaction="4")])
        command = [sys.executable, "-B", str(HERE / "summarize.py"), str(self.path)]
        first = subprocess.run(command, text=True, capture_output=True, check=True)
        second = subprocess.run(command, text=True, capture_output=True, check=True)
        self.assertEqual(first.stdout, second.stdout)
        self.assertEqual(json.loads(first.stdout)["observed_human_records"], 0)
        valid = subprocess.run(command + ["--validate-only"], text=True, capture_output=True, check=True)
        self.assertEqual(json.loads(valid.stdout)["validation"], "passed")
        self.write([fictional(satisfaction="6")])
        invalid = subprocess.run(command, text=True, capture_output=True)
        self.assertEqual(invalid.returncode, 2)
        self.assertEqual(invalid.stdout, "")
        self.assertIn("CSV row 2", invalid.stderr)

    def test_cli_bad_encoding_and_huge_integer_fail_cleanly(self):
        command = [sys.executable, "-B", str(HERE / "summarize.py"), str(self.path)]
        self.path.write_bytes(b"\xff\xfeinvalid utf8")
        invalid_encoding = subprocess.run(command, text=True, capture_output=True)
        self.write([fictional(score_at_stop="9" * 5000)])
        huge_integer = subprocess.run(command, text=True, capture_output=True)
        for result in (invalid_encoding, huge_integer):
            self.assertEqual(result.returncode, 2)
            self.assertEqual(result.stdout, "")
            self.assertIn("Invalid observations:", result.stderr)
            self.assertNotIn("Traceback", result.stderr)


if __name__ == "__main__":
    unittest.main()
