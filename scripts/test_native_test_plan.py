import unittest
from pathlib import Path
from native_test_plan import plan


class NativeMatrixTests(unittest.TestCase):
    def test_dev_defers_only_named_actual_voiceover_sessions_and_rc_restores_them(self):
        root = Path(__file__).resolve().parents[1]
        dev, deferred = plan(root, 'dev'); rc, rc_deferred = plan(root, 'rc')
        self.assertEqual(len(deferred), 5); self.assertFalse(rc_deferred)
        self.assertEqual(rc['StarfallUITests']['expectedCount'], dev['StarfallUITests']['expectedCount'] + 5)
        self.assertEqual(dev['StarfallAppTests'], rc['StarfallAppTests'])
        self.assertTrue(all('/testVoiceOver' in name for name in deferred))
        selected = [name for names in dev['StarfallUITests']['testMethodsBySource'].values() for name in names]
        self.assertIn('testBuildIDMenuAndLargestTextTrace', selected)
        self.assertIn('testSystemReduceMotionKeepsManualPlayWorking', selected)
        self.assertIn('testFirstLightGoalCompletionRestoreReplayAndSurvival', selected)

    def test_invalid_stage_cannot_silently_reduce_coverage(self):
        with self.assertRaises(ValueError):
            plan(Path(__file__).resolve().parents[1], 'unknown')


if __name__ == '__main__':
    unittest.main()
