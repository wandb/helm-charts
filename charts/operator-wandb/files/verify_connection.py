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

    with patch.object(verify, "check_run", check_run):
        cli.verify()


if __name__ == "__main__":
    main()
