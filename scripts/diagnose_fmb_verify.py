"""Temporary FMB CI diagnostic; preserves the original verifier failure."""

import json
import time

import wandb
from wandb.cli.cli import cli


def observe_failed_run(error):
    frame = error.__traceback__
    run = None
    while frame is not None:
        if frame.tb_frame.f_code.co_name == "check_run":
            run = frame.tb_frame.f_locals.get("prev_run")
            break
        frame = frame.tb_next
    if run is None:
        print("FMB_DIAGNOSTIC: no verifier run found", flush=True)
        return

    run_path = "/".join(run.path)
    started = time.monotonic()
    for delay in (0, 1, 2, 7):
        time.sleep(delay)
        # A fresh API avoids reusing the Run object's cached history metadata.
        current = wandb.Api(timeout=10).run(run_path)
        history = current.history_keys
        print(
            "FMB_DIAGNOSTIC " + json.dumps({
                "run_id": current.id,
                "elapsed_seconds": round(time.monotonic() - started, 2),
                "loss_present": "loss" in history.get("keys", {}),
                "loss_previous": history.get("keys", {}).get("loss", {}).get("previousValue"),
                "last_step": history.get("lastStep"),
                "summary_loss": current.summary.get("loss"),
            }),
            flush=True,
        )


if __name__ == "__main__":
    try:
        cli(["verify"], standalone_mode=False)
    except KeyError as error:
        try:
            observe_failed_run(error)
        except Exception as diagnostic_error:
            print("FMB_DIAGNOSTIC failed: " + type(diagnostic_error).__name__, flush=True)
        raise
