"""Keep the SDK verifier's assertions while allowing asynchronous metric visibility."""

import json
import time
from unittest.mock import patch


def wait_for_run_metrics(run, timeout=30):
    deadline = time.monotonic() + timeout
    expected = {"loss": 0.1, "dict.val1": 1.0, "dict.val2": 2}
    while True:
        history = run.history_keys or {}
        keys = history.get("keys", {})
        values = {
            key: keys.get(key, {}).get("previousValue") for key in expected
        }
        summary_loss = run.summary_metrics.get("loss")
        if values == expected and history.get("lastStep") == 11 and summary_loss == 0.1:
            return
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            raise TimeoutError("Verifier metrics did not converge: " + json.dumps({
                "run": run.id,
                "last_step": history.get("lastStep"),
                "metric_values": values,
                "summary_loss": summary_loss,
            }))
        time.sleep(min(1, remaining))
        run.load(force=True)


def main():
    import wandb
    from wandb.cli import cli
    from wandb.sdk.verify import verify

    # SDK 0.30.0 reads these metrics immediately after finish. The run store is
    # asynchronous; refresh that same run before the SDK's unchanged assertions.
    # Keep the SDK pin in test-connection.yaml aligned with this compatibility shim.
    original_check_run = verify.check_run
    expected_run_id = verify.nice_id("check_run")

    class VerifyApi(wandb.Api):
        def run(self, *args, **kwargs):
            run = super().run(*args, **kwargs)
            if run.id == expected_run_id:
                wait_for_run_metrics(run)
            return run

    def check_run(api):
        with patch.object(wandb, "Api", VerifyApi):
            return original_check_run(api)

    # Current local servers reject a repeated sweep parameter set.
    # verify() requests 10 runs from a 9-point random sweep, so the agent
    # waits on a heartbeat that never returns a run. One trial still
    # creates the sweep and executes the agent.
    original_agent = wandb.agent

    def agent(*args, **kwargs):
        kwargs["count"] = 1
        return original_agent(*args, **kwargs)

    # FMB publishes run updates through the pubsub emulator. UseArtifact reads
    # the run immediately, before that update is visible.
    original_use_artifact = wandb.sdk.wandb_run.Run.use_artifact

    def use_artifact(run, *args, **kwargs):
        deadline = time.monotonic() + 30
        while True:
            try:
                return original_use_artifact(run, *args, **kwargs)
            except Exception as exc:
                if "failed to find run" not in str(exc) or time.monotonic() >= deadline:
                    raise
                time.sleep(1)

    with (
        patch.object(verify, "check_run", check_run),
        patch.object(wandb, "agent", agent),
        patch.object(wandb.sdk.wandb_run.Run, "use_artifact", use_artifact),
    ):
        cli.verify()


if __name__ == "__main__":
    main()
