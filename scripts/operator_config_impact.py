#!/usr/bin/env python3
"""Detect semantic render changes for an operator-wandb test fixture.

This is intentionally stricter than a path filter: shared templates can alter an
OLAP deployment without touching an OLAP-named file.  The script renders the
base and head charts with the same fixture and Kubernetes versions, normalizes
only known Helm-generated values, and exits like ``diff``:

* 0: every normalized render is identical
* 1: at least one normalized render changed
* 2: the comparison could not be completed
"""

from __future__ import annotations

import argparse
import base64
import binascii
import difflib
import re
import subprocess
import sys
from pathlib import Path

from normalize_snapshot_chart_versions import normalize as normalize_chart_labels


DEFAULT_KUBERNETES_VERSIONS = ("1.34.8", "1.35.5", "1.36.1")
RELEASE_NAME = "impact"
NAMESPACE = "impact"
GENERATED_SESSION_SECRET = f"{RELEASE_NAME}-gorilla-session-key"
SESSION_KEY_LINE = re.compile(
    r'(?m)^(\s*GORILLA_SESSION_KEY:\s*)["\']?(?P<value>[A-Za-z0-9+/]+={0,2})["\']?\s*$'
)


class ImpactError(RuntimeError):
    """Raised when a render cannot be compared safely."""


def _render(
    repository: Path,
    configuration: str,
    kubernetes_version: str,
) -> str:
    chart = repository / "charts" / "operator-wandb"
    values = (
        repository
        / "test-configs"
        / "operator-wandb"
        / f"{configuration}.yaml"
    )
    if not chart.is_dir():
        raise ImpactError(f"operator-wandb chart not found in {repository}")
    if not values.is_file():
        raise ImpactError(f"configuration not found: {values}")

    command = [
        "helm",
        "template",
        RELEASE_NAME,
        str(chart),
        "--namespace",
        NAMESPACE,
        "--values",
        str(values),
        "--kube-version",
        kubernetes_version,
        "--include-crds",
        "--set-string",
        "global.mysql.passwordSecret.name=impact-mysql",
        "--set-string",
        "global.license=impact-license",
    ]
    result = subprocess.run(
        command,
        cwd=repository,
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode:
        raise ImpactError(
            f"render failed for {repository} on Kubernetes "
            f"{kubernetes_version}:\n{result.stderr}"
        )
    return result.stdout


def _normalize_generated_session_key(manifest: str) -> str:
    """Normalize only the random data in the generated session Secret."""

    normalized_documents: list[str] = []
    found_secrets = 0
    for document in manifest.split("\n---"):
        is_secret = re.search(r"(?m)^kind:\s*Secret\s*$", document)
        has_expected_name = re.search(
            rf"(?m)^\s*name:\s*{re.escape(GENERATED_SESSION_SECRET)}\s*$",
            document,
        )
        if is_secret and has_expected_name:
            match = SESSION_KEY_LINE.search(document)
            if match is None:
                raise ImpactError(
                    "expected one Base64 GORILLA_SESSION_KEY in "
                    f"Secret/{GENERATED_SESSION_SECRET}"
                )
            try:
                decoded = base64.b64decode(match.group("value"), validate=True)
            except (binascii.Error, ValueError) as error:
                raise ImpactError(
                    f"invalid generated GORILLA_SESSION_KEY: {error}"
                ) from error
            if len(decoded) != 32:
                raise ImpactError(
                    "generated GORILLA_SESSION_KEY must decode to exactly 32 bytes"
                )
            updated, replacements = SESSION_KEY_LINE.subn(
                r"\1<generated>", document
            )
            if replacements != 1:
                raise ImpactError(
                    "expected exactly one generated GORILLA_SESSION_KEY in "
                    f"Secret/{GENERATED_SESSION_SECRET}, found {replacements}"
                )
            document = updated
            found_secrets += 1
        normalized_documents.append(document)

    if found_secrets != 1:
        raise ImpactError(
            f"expected exactly one generated Secret/{GENERATED_SESSION_SECRET}, "
            f"found {found_secrets}"
        )
    return "\n---".join(normalized_documents)


def normalize_render(manifest: str) -> str:
    """Remove only known non-semantic values from a Helm render."""

    return _normalize_generated_session_key(normalize_chart_labels(manifest))


def compare(
    base_repository: Path,
    head_repository: Path,
    configuration: str,
    kubernetes_versions: tuple[str, ...],
) -> list[str]:
    """Return bounded unified diffs for Kubernetes versions that changed."""

    changes: list[str] = []
    for version in kubernetes_versions:
        base = normalize_render(_render(base_repository, configuration, version))
        head = normalize_render(_render(head_repository, configuration, version))
        if base == head:
            continue
        diff = difflib.unified_diff(
            base.splitlines(),
            head.splitlines(),
            fromfile=f"base/{configuration}@{version}",
            tofile=f"head/{configuration}@{version}",
            lineterm="",
            n=3,
        )
        # Keep Actions logs useful even if an accidental change is very large.
        changes.extend(list(diff)[:400])
    return changes


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base-repository", type=Path, required=True)
    parser.add_argument("--head-repository", type=Path, required=True)
    parser.add_argument("--configuration", required=True)
    parser.add_argument(
        "--kubernetes-version",
        action="append",
        dest="kubernetes_versions",
        help="repeat to compare multiple Kubernetes versions",
    )
    return parser.parse_args()


def main() -> int:
    args = _parse_args()
    versions = tuple(args.kubernetes_versions or DEFAULT_KUBERNETES_VERSIONS)
    try:
        changes = compare(
            args.base_repository.resolve(),
            args.head_repository.resolve(),
            args.configuration,
            versions,
        )
    except (ImpactError, OSError) as error:
        print(f"operator configuration impact check failed: {error}", file=sys.stderr)
        return 2

    if changes:
        print("\n".join(changes))
        return 1
    print(
        f"{args.configuration} is semantically unchanged on "
        f"{', '.join(versions)}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
