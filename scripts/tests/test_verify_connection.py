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
        self.other_run = SimpleNamespace(id="other-run")
        self.agent = Mock(return_value="agent-result")
        self.use_artifact = Mock(return_value="artifact-result")
        target, other = self.metric_run, self.other_run
        use_artifact = self.use_artifact

        class Api:
            def run(self, path):
                return target if path == "target" else other

        class Run:
            def use_artifact(run, *args, **kwargs):
                return use_artifact(run, *args, **kwargs)

        self.wandb = ModuleType("wandb")
        self.wandb.Api = Api
        self.wandb.agent = self.agent
        self.wandb.sdk = SimpleNamespace(wandb_run=SimpleNamespace(Run=Run))
        self.sdk_verify = SimpleNamespace(
            check_run=Mock(), nice_id=lambda _: self.metric_run.id,
        )

    def advance(self, seconds):
        self.now += seconds

    def run_verifier(self, cli_verify):
        modules = {
            "wandb": self.wandb,
            "wandb.cli": SimpleNamespace(cli=SimpleNamespace(verify=cli_verify)),
            "wandb.sdk.verify": SimpleNamespace(verify=self.sdk_verify),
        }
        with patch.dict(sys.modules, modules):
            verifier.main()

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
        wandb = self.wandb
        target = self.metric_run
        other = self.other_run
        Api = wandb.Api
        original_use_artifact = wandb.sdk.wandb_run.Run.use_artifact

        def original_check_run(api):
            self.assertIs(wandb.Api().run("target"), target)
            self.assertIs(wandb.Api().run("other"), other)
            return False  # An unrelated original SDK assertion still fails.

        sdk_verify = self.sdk_verify
        sdk_verify.check_run = original_check_run

        def cli_verify():
            self.assertFalse(sdk_verify.check_run(Api()))
            self.assertIs(wandb.Api, Api)
            raise SystemExit(1)

        with patch.object(verifier, "wait_for_run_metrics") as wait:
            with self.assertRaises(SystemExit) as result:
                self.run_verifier(cli_verify)
            self.assertEqual(result.exception.code, 1)
            wait.assert_called_once_with(target)
        self.assertIs(wandb.Api, Api)
        self.assertIs(wandb.agent, self.agent)
        self.assertIs(wandb.sdk.wandb_run.Run.use_artifact, original_use_artifact)
        self.assertIs(sdk_verify.check_run, original_check_run)

    def test_sweep_agent_executes_one_trial(self):
        def cli_verify():
            self.assertEqual(
                self.wandb.agent("sweep-id", function="trial", count=10),
                "agent-result",
            )

        self.run_verifier(cli_verify)
        self.agent.assert_called_once_with("sweep-id", function="trial", count=1)
        self.assertIs(self.wandb.agent, self.agent)

    def test_artifact_use_waits_for_run_visibility(self):
        self.use_artifact.side_effect = [
            RuntimeError("failed to find run verify/test-use_artifact"),
            "artifact-result",
        ]
        run = self.wandb.sdk.wandb_run.Run()

        def cli_verify():
            self.assertEqual(run.use_artifact("artifact:v0", type="dataset"), "artifact-result")

        self.run_verifier(cli_verify)
        self.assertEqual(self.use_artifact.call_count, 2)
        self.use_artifact.assert_called_with(run, "artifact:v0", type="dataset")
        self.assertEqual(self.now, 1)

    def test_artifact_use_does_not_retry_other_errors(self):
        error = RuntimeError("permission denied")
        self.use_artifact.side_effect = error
        run = self.wandb.sdk.wandb_run.Run()

        with self.assertRaises(RuntimeError) as result:
            self.run_verifier(lambda: run.use_artifact("artifact:v0"))

        self.assertIs(result.exception, error)
        self.use_artifact.assert_called_once_with(run, "artifact:v0")
        self.assertEqual(self.now, 0)

    def test_artifact_use_stops_waiting_after_thirty_seconds(self):
        error = RuntimeError("failed to find run verify/test-use_artifact")
        self.use_artifact.side_effect = error
        run = self.wandb.sdk.wandb_run.Run()

        with self.assertRaises(RuntimeError) as result:
            self.run_verifier(lambda: run.use_artifact("artifact:v0"))

        self.assertIs(result.exception, error)
        self.assertEqual(self.now, 30)


if __name__ == "__main__":
    unittest.main()
