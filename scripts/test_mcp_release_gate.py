#!/usr/bin/env python3
"""Validate the immutable MCP image and operator-wandb release contract."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import time
import urllib.request
import uuid
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[1]
CHART = REPO_ROOT / "charts" / "operator-wandb"
CHART_IMAGE_REPOSITORY = "wandb/mcp-server"
SHA256_PATTERN = re.compile(r"sha256:[0-9a-f]{64}")
COMMIT_PATTERN = re.compile(r"[0-9a-f]{40}")
REPOSITORY_PATTERN = re.compile(r"[A-Za-z0-9][A-Za-z0-9._:/-]*")
VERSION_PATTERN = re.compile(r"0\.4\.\d+")


class GateError(RuntimeError):
    """Raised when release evidence does not satisfy the gate."""


def _run(
    command: list[str],
    *,
    check: bool = True,
    timeout: float | None = None,
) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        command,
        cwd=REPO_ROOT,
        check=False,
        capture_output=True,
        text=True,
        timeout=timeout,
    )
    if check and result.returncode:
        rendered = " ".join(command[:3])
        raise GateError(
            f"command failed ({rendered}):\n{result.stdout}\n{result.stderr}"
        )
    return result


def load_candidate(path: Path) -> dict[str, str]:
    try:
        value: Any = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise GateError(f"cannot read release candidate {path}: {error}") from error
    if not isinstance(value, dict):
        raise GateError("release candidate must be a JSON object")

    candidate: dict[str, str] = {}
    for key in (
        "version",
        "public_source_sha",
        "hosted_source_sha",
        "image_repository",
        "image_digest",
    ):
        field = value.get(key)
        if not isinstance(field, str):
            raise GateError(f"release candidate field {key!r} must be a string")
        candidate[key] = field.strip()

    if not VERSION_PATTERN.fullmatch(candidate["version"]):
        raise GateError("version must be a v0.4 patch release such as 0.4.0")
    if not COMMIT_PATTERN.fullmatch(candidate["public_source_sha"]):
        raise GateError("public_source_sha must be an exact 40-character commit SHA")
    if not COMMIT_PATTERN.fullmatch(candidate["hosted_source_sha"]):
        raise GateError("hosted_source_sha must be an exact 40-character commit SHA")
    if not REPOSITORY_PATTERN.fullmatch(candidate["image_repository"]):
        raise GateError("image_repository is empty or invalid")
    if not SHA256_PATTERN.fullmatch(candidate["image_digest"]):
        raise GateError(
            "image_digest must record the exact staging-tested customer-image "
            "sha256 digest"
        )
    return candidate


def render_candidate(
    candidate: dict[str, str],
    *,
    include_runtime_resources: bool = False,
    use_digest: bool = True,
) -> str:
    digest = candidate["image_digest"] or f"sha256:{'0' * 64}"
    image_repository = candidate["image_repository"]
    if image_repository == CHART_IMAGE_REPOSITORY:
        repository_prefix = ""
    elif image_repository.endswith(f"/{CHART_IMAGE_REPOSITORY}"):
        repository_prefix = image_repository[: -len(CHART_IMAGE_REPOSITORY) - 1]
    else:
        raise GateError(
            "published image repository must resolve from the chart's "
            f"{CHART_IMAGE_REPOSITORY!r} repository using global.repositoryPrefix"
        )

    command = [
        "helm",
        "template",
        "mcp-release",
        str(CHART),
        "--namespace",
        "mcp-release",
        "--set",
        "mcp-server.install=true",
        "--set",
        "global.api.enabled=true",
        "--set-string",
        "global.host=https://customer.wandb.io",
    ]
    if use_digest:
        command.extend(("--set-string", f"mcp-server.image.digest={digest}"))
    templates = ["charts/mcp-server/templates/deployment.yaml"]
    if include_runtime_resources:
        templates.extend(
            (
                "charts/mcp-server/templates/serviceaccount.yaml",
                "charts/mcp-server/templates/service.yaml",
                "templates/certs.yaml",
            )
        )
    for template in templates:
        command.extend(("--show-only", template))
    if repository_prefix:
        command.extend(
            (
                "--set-string",
                f"global.repositoryPrefix={repository_prefix}",
            )
        )
    result = _run(command)
    manifest = result.stdout
    if use_digest:
        expected_image = f'{candidate["image_repository"]}@{digest}'
    else:
        expected_image = (
            f'{candidate["image_repository"]}:{candidate["version"]}'
        )
    if f'image: "{expected_image}"' not in manifest:
        raise GateError(f"chart did not render the exact image {expected_image}")

    expected_values = {
        "WANDB_BASE_URL": "https://customer.wandb.io",
        "WANDB_INTERNAL_BASE_URL": "http://mcp-release-api:8081",
        "MCP_HOSTED_MODE": "true",
        "MCP_ADMISSION_CONTROL_ENABLED": "true",
        "MCP_TOOL_TIMEOUT_SECONDS": "30",
        "MCP_WANDB_REQUEST_TIMEOUT_SECONDS": "20",
        "WANDB_MCP_READ_ONLY": "false",
        "WANDB_MCP_ENABLE_RAW_GRAPHQL": "false",
        "WANDB_MCP_ENABLE_WEAVE_AGENT_TOOLS": "false",
        "UVICORN_WORKERS": "1",
    }
    for name, expected in expected_values.items():
        pattern = re.compile(
            rf"(?m)^\s*- name:\s*{re.escape(name)}\s*$\n"
            rf"^\s+value:\s*[\"']?{re.escape(expected)}[\"']?\s*$"
        )
        if not pattern.search(manifest):
            raise GateError(f"rendered MCP environment is missing {name}={expected}")

    forbidden = (
        "GLOBAL_ADMIN_API_KEY",
        "GORILLA_INSECURE_ALLOW_API_KEY_ADMIN_ACCESS",
        "GORILLA_STATSIG_KEY",
        "GORILLA_MCP_",
    )
    for value in forbidden:
        if value in manifest:
            raise GateError(f"forbidden server setting reached the MCP pod: {value}")
    if not re.search(r"(?m)^spec:\s*$\n^\s+replicas:\s+1\s*$", manifest):
        raise GateError("MCP release must render exactly one replica")
    return manifest


def verify_image_provenance(candidate: dict[str, str]) -> str:
    image = f"{candidate['image_repository']}@{candidate['image_digest']}"
    tag = f"{candidate['image_repository']}:{candidate['version']}"
    inspection = _run(
        ["docker", "buildx", "imagetools", "inspect", tag], timeout=120
    ).stdout
    match = re.search(r"(?m)^Digest:\s*(sha256:[0-9a-f]{64})\s*$", inspection)
    if match is None:
        raise GateError(f"could not resolve an immutable digest for public tag {tag}")
    if match.group(1) != candidate["image_digest"]:
        raise GateError(
            f"public tag {tag} resolves to {match.group(1)}, expected "
            f"{candidate['image_digest']}"
        )
    _run(["docker", "pull", image], timeout=300)
    probe = r"""
import importlib.metadata
import json
import os

distribution = importlib.metadata.distribution("wandb-mcp-server")
actual_version = distribution.version
if actual_version != os.environ["EXPECTED_VERSION"]:
    raise SystemExit(f"version mismatch: {actual_version}")
direct_url_text = distribution.read_text("direct_url.json")
if not direct_url_text:
    raise SystemExit("wandb-mcp-server direct_url.json is missing")
direct_url = json.loads(direct_url_text)
actual_sha = direct_url.get("vcs_info", {}).get("commit_id")
if actual_sha != os.environ["EXPECTED_SOURCE_SHA"]:
    raise SystemExit(f"source SHA mismatch: {actual_sha}")
print(json.dumps({"version": actual_version, "public_source_sha": actual_sha}))
"""
    result = _run(
        [
            "docker",
            "run",
            "--rm",
            "--entrypoint",
            "python",
            "-e",
            f"EXPECTED_VERSION={candidate['version']}",
            "-e",
            f"EXPECTED_SOURCE_SHA={candidate['public_source_sha']}",
            image,
            "-c",
            probe,
        ],
        timeout=120,
    )
    return result.stdout.strip()


def verify_runtime_health(candidate: dict[str, str]) -> None:
    image = f"{candidate['image_repository']}@{candidate['image_digest']}"
    container = f"mcp-release-gate-{uuid.uuid4().hex[:12]}"
    run = _run(
        [
            "docker",
            "run",
            "--detach",
            "--rm",
            "--name",
            container,
            "--publish",
            "127.0.0.1::8080",
            "-e",
            "WANDB_BASE_URL=https://customer.wandb.io",
            "-e",
            "WANDB_INTERNAL_BASE_URL=http://mcp-release-api:8081",
            "-e",
            "MCP_AUTH_DISABLED=false",
            "-e",
            "MCP_HOSTED_MODE=true",
            "-e",
            "MCP_ADMISSION_CONTROL_ENABLED=true",
            "-e",
            "MCP_ADMISSION_ACTOR_CAPACITY=4",
            "-e",
            "MCP_ADMISSION_PROCESS_CAPACITY=4",
            "-e",
            "MCP_TOOL_TIMEOUT_SECONDS=30",
            "-e",
            "MCP_WANDB_REQUEST_TIMEOUT_SECONDS=20",
            "-e",
            "WANDB_MCP_READ_ONLY=false",
            "-e",
            "WANDB_MCP_ENABLE_RAW_GRAPHQL=false",
            "-e",
            "WANDB_MCP_ENABLE_WEAVE_AGENT_TOOLS=false",
            "-e",
            "WANDB_MCP_ENABLE_WEAVE_TOOLS=false",
            "-e",
            "MCP_WORKLOAD_PROFILE=dedicated",
            "-e",
            "MCP_DEPLOYMENT_TYPE=self-managed",
            "-e",
            "MCP_LOG_PRIVACY_LEVEL=standard",
            "-e",
            "UVICORN_WORKERS=1",
            "-e",
            "UVICORN_LIMIT_CONCURRENCY=32",
            "-e",
            "MCP_ANALYTICS_DISABLED=true",
            "-e",
            "MCP_SEGMENT_FORWARD=false",
            image,
        ],
        timeout=120,
    )
    if not run.stdout.strip():
        raise GateError("Docker did not return a container id")

    try:
        port = _run(["docker", "port", container, "8080/tcp"]).stdout.strip()
        match = re.search(r":(\d+)$", port)
        if match is None:
            raise GateError(f"could not determine MCP container port from {port!r}")
        url = f"http://127.0.0.1:{match.group(1)}/mcp/health"
        deadline = time.monotonic() + 60
        last_error = "health endpoint did not respond"
        while time.monotonic() < deadline:
            try:
                with urllib.request.urlopen(url, timeout=2) as response:
                    if 200 <= response.status < 300:
                        return
                    last_error = f"health returned HTTP {response.status}"
            except OSError as error:
                last_error = str(error)
            time.sleep(0.5)
        logs = _run(
            ["docker", "logs", "--tail", "200", container], check=False
        )
        raise GateError(
            f"MCP image failed /mcp/health: {last_error}\n"
            f"{logs.stdout}\n{logs.stderr}"
        )
    finally:
        _run(["docker", "rm", "--force", container], check=False)


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--candidate",
        type=Path,
        default=REPO_ROOT / "release-candidates" / "mcp-v0.4.0.json",
    )
    parser.add_argument(
        "--render-only",
        action="store_true",
        help="validate candidate metadata and Helm rendering without pulling an image",
    )
    parser.add_argument(
        "--manifest-output",
        type=Path,
        help="write the validated minimal MCP Kubernetes manifest to this path",
    )
    return parser.parse_args()


def main() -> int:
    args = _parse_args()
    try:
        candidate = load_candidate(args.candidate.resolve())
        render_candidate(candidate, use_digest=False)
        manifest = render_candidate(
            candidate, include_runtime_resources=args.manifest_output is not None
        )
        if args.manifest_output is not None:
            args.manifest_output.write_text(manifest, encoding="utf-8")
        if args.render_only:
            print("MCP release candidate metadata and immutable render contract pass")
            return 0
        provenance = verify_image_provenance(candidate)
        verify_runtime_health(candidate)
    except (GateError, OSError, subprocess.TimeoutExpired) as error:
        print(f"MCP v0.4 release gate failed: {error}", file=sys.stderr)
        return 1
    print(f"MCP v0.4 release gate passed: {provenance}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
