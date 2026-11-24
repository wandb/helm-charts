#!/usr/bin/env python3
"""Exercise real Helm dependency selection, including removal of all Pulse resources."""

from pathlib import Path
import subprocess


ROOT = Path(__file__).resolve().parents[2]
CHART = ROOT / "charts/operator-wandb"
SOURCE = "# Source: operator-wandb/charts/agent-pulse/"


def render(*settings: str) -> subprocess.CompletedProcess[str]:
    command = ["helm", "template", "customer-a", str(CHART), "--namespace", "default"]
    for setting in settings:
        command.extend(["--set", setting])
    return subprocess.run(command, text=True, capture_output=True)


for settings in (
    (),
    ("agent-lens.install=false",),
    ("agent-lens.install=true", "agent-pulse.install=false"),
    ("agent-lens.install=false", "agent-pulse.install=false"),
):
    result = render(*settings)
    assert result.returncode == 0, result.stderr
    assert SOURCE not in result.stdout, settings

result = render(
    "agent-lens.install=true",
    "agent-pulse.image.tag=test-release",
    "agent-pulse.connectionSecret=lens-connections",
)
assert result.returncode == 0, result.stderr
for template in ("deployment.yaml", "service.yaml", "serviceaccount.yaml", "pdb.yaml"):
    assert f"{SOURCE}templates/{template}" in result.stdout, template

# Helm uses the first matching condition, rather than AND-ing conditions.
# Reject per-service opt-ins so they cannot override the Lens master switch.
for enabled in ("true", "false"):
    result = render(f"agent-lens.install={enabled}", "agent-pulse.install=true")
    assert result.returncode != 0, "per-service opt-in must be rejected"
    assert "must be false" in result.stderr, result.stderr

print("Agent Lens master switch, Pulse opt-out and opt-in rejection passed")
