import importlib.util
import sys
import unittest
from pathlib import Path
from types import ModuleType, SimpleNamespace
from unittest.mock import Mock, patch


SCRIPT = Path(__file__).resolve().parents[2] / "charts/operator-wandb/files/verify_connection.py"
spec = importlib.util.spec_from_file_location("verify_connection", SCRIPT)
verifier = importlib.util.module_from_spec(spec)
spec.loader.exec_module(verifier)


def complete_history():
    return {
        "lastStep": 11,
        "keys": {
            key: {"previousValue": value}
            for key, value in {"loss": 0.1, "dict.val1": 1.0, "dict.val2": 2}.items()
        },
    }


class VerifyConnectionTest(unittest.TestCase):
    def setUp(self):
        self.now = 0
        self.clock = patch.object(verifier.time, "monotonic", side_effect=lambda: self.now)
        self.sleep = patch.object(verifier.time, "sleep", side_effect=self.advance)
        self.clock.start()
        self.sleep.start()
        self.addCleanup(self.clock.stop)
        self.addCleanup(self.sleep.stop)
        self.metric_run = SimpleNamespace(
            id="test-check_run", history_keys=complete_history(),
            summary_metrics={"loss": 0.1}, load=Mock(),
        )

    def advance(self, seconds):
        self.now += seconds

    def test_complete_metrics_do_not_wait(self):
        verifier.wait_for_run_metrics(self.metric_run)
        self.metric_run.load.assert_not_called()
        self.assertEqual(self.now, 0)

    def test_missing_then_partial_metrics_refresh_the_same_run(self):
        self.metric_run.history_keys = None
        self.metric_run.summary_metrics = {}

        def refresh(force):
            self.assertTrue(force)
            self.metric_run.history_keys = complete_history()
            if self.now >= 2:
                self.metric_run.summary_metrics = {"loss": 0.1}

        self.metric_run.load.side_effect = refresh
        verifier.wait_for_run_metrics(self.metric_run)
        self.assertEqual(self.metric_run.load.call_count, 2)
        self.assertEqual(self.metric_run.id, "test-check_run")

    def test_missing_or_incorrect_values_still_fail(self):
        for field in ("loss", "dict.val1", "dict.val2", "lastStep", "summary"):
            with self.subTest(field=field):
                self.metric_run.history_keys = complete_history()
                self.metric_run.summary_metrics = {"loss": 0.1}
                if field == "lastStep":
                    self.metric_run.history_keys[field] = 10
                elif field == "summary":
                    self.metric_run.summary_metrics = {}
                else:
                    self.metric_run.history_keys["keys"][field]["previousValue"] = -1
                with self.assertRaisesRegex(TimeoutError, "test-check_run"):
                    verifier.wait_for_run_metrics(self.metric_run, timeout=2)

    def test_permanently_missing_keys_fail_within_deadline(self):
        self.metric_run.history_keys = {}
        with self.assertRaises(TimeoutError):
            verifier.wait_for_run_metrics(self.metric_run, timeout=2.5)
        self.assertEqual(self.now, 2.5)
        self.assertEqual(self.metric_run.load.call_count, 3)

    def test_api_errors_are_not_swallowed(self):
        self.metric_run.history_keys = {}
        self.metric_run.load.side_effect = RuntimeError("API unavailable")
        with self.assertRaisesRegex(RuntimeError, "API unavailable"):
            verifier.wait_for_run_metrics(self.metric_run)

    def test_sdk_assertions_and_other_checks_keep_their_results(self):
        wandb = ModuleType("wandb")
        target = self.metric_run
        other = SimpleNamespace(id="other-run")

        class Api:
            def run(self, path):
                return target if path == "target" else other

        wandb.Api = Api

        def original_check_run(api):
            self.assertIs(wandb.Api().run("target"), target)
            self.assertIs(wandb.Api().run("other"), other)
            return False  # An unrelated original SDK assertion still fails.

        sdk_verify = SimpleNamespace(check_run=original_check_run, nice_id=lambda _: target.id)

        def cli_verify():
            self.assertFalse(sdk_verify.check_run(Api()))
            self.assertIs(wandb.Api, Api)
            raise SystemExit(1)

        modules = {
            "wandb": wandb,
            "wandb.cli": SimpleNamespace(cli=SimpleNamespace(verify=cli_verify)),
            "wandb.sdk.verify": SimpleNamespace(verify=sdk_verify),
        }
        with patch.dict(sys.modules, modules), patch.object(verifier, "wait_for_run_metrics") as wait:
            with self.assertRaises(SystemExit) as result:
                verifier.main()
            self.assertEqual(result.exception.code, 1)
            wait.assert_called_once_with(target)
        self.assertIs(wandb.Api, Api)
        self.assertIs(sdk_verify.check_run, original_check_run)


if __name__ == "__main__":
    unittest.main()
