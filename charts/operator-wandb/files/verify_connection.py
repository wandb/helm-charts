"""Run the SDK verifier and retain same-run metadata when it fails."""

import json
from itertools import islice
import subprocess
import time


def diagnose_run():
    import wandb

    api = wandb.Api(timeout=10)
    runs = api.runs(f"{api.default_entity}/verify", order="-created_at", per_page=10)
    run = next((run for run in islice(runs, 10) if run.id.endswith("-check_run")), None)
    if run is None:
        print("No verifier metric run found", flush=True)
        return
    run = api.run(f"{api.default_entity}/verify/{run.id}")
    started = time.monotonic()
    for attempt in range(11):
        run.load(force=True)
        history = run.history_keys or {}
        keys = history.get("keys", {})
        print(json.dumps({
            "run": run.id,
            "elapsed_seconds": round(time.monotonic() - started, 2),
            "state": run.state,
            "last_step": history.get("lastStep"),
            "metric_values": {
                key: keys.get(key, {}).get("previousValue")
                for key in ("loss", "dict.val1", "dict.val2")
            },
            "summary_loss": run.summary.get("loss"),
        }), flush=True)
        if attempt < 10:
            time.sleep(2)


def main():
    result = subprocess.run(["wandb", "verify"], check=False)
    if result.returncode:
        try:
            diagnose_run()
        except Exception as error:
            print(f"Verifier diagnostics failed: {type(error).__name__}: {error}", flush=True)
    # Diagnostics must never turn a failed verifier into a passing Helm test.
    return result.returncode


if __name__ == "__main__":
    raise SystemExit(main())
