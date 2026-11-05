#!/usr/bin/env python3
"""Check that rendered container env $(VAR) references resolve.

Kubernetes expands $(VAR) in an env value only when VAR is defined earlier in
the same container's env (or by envFrom); otherwise the literal text is kept.
Helpers that compose DSNs from other env entries, such as wandb.mysql, depend
on that order, so this check scans the committed chart snapshots for
references that are defined later or not at all.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path
from typing import Iterator, Sequence

import yaml


REFERENCE = re.compile(r"(\$+)\(([A-Za-z_][A-Za-z0-9_.-]*)\)")
DEFAULT_GLOB = "test-configs/operator-wandb/__snapshots__/*.snap"


def references(value: str) -> Iterator[str]:
    for match in REFERENCE.finditer(value):
        # $$(VAR) is an escaped literal.
        if len(match.group(1)) % 2 == 1:
            yield match.group(2)


def pod_specs(node: object) -> Iterator[dict]:
    if isinstance(node, dict):
        if isinstance(node.get("containers"), list):
            yield node
        for child in node.values():
            yield from pod_specs(child)
    elif isinstance(node, list):
        for child in node:
            yield from pod_specs(child)


def container_findings(container: dict) -> Iterator[str]:
    env = container.get("env") or []
    names = [entry.get("name") for entry in env if isinstance(entry, dict)]
    has_env_from = bool(container.get("envFrom"))
    for index, entry in enumerate(env):
        value = entry.get("value") if isinstance(entry, dict) else None
        if not isinstance(value, str):
            continue
        for ref in references(value):
            if ref in names[:index]:
                continue
            if ref in names[index:]:
                yield f"env {entry['name']} references $({ref}) before it is defined"
            elif not has_env_from:
                yield f"env {entry['name']} references undefined $({ref})"


def document_findings(document: dict) -> Iterator[str]:
    kind = document.get("kind", "?")
    name = (document.get("metadata") or {}).get("name", "?")
    for spec in pod_specs(document):
        for key in ("initContainers", "containers"):
            for container in spec.get(key) or []:
                for finding in container_findings(container):
                    yield f"{kind}/{name} {key}[{container.get('name')}]: {finding}"


def file_findings(path: Path) -> Iterator[str]:
    for document in yaml.safe_load_all(path.read_text()):
        if isinstance(document, dict):
            for finding in document_findings(document):
                yield f"{path}: {finding}"


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "paths",
        nargs="*",
        type=Path,
        help=f"rendered manifests to check (default: {DEFAULT_GLOB})",
    )
    args = parser.parse_args(argv)
    paths = args.paths or sorted(Path().glob(DEFAULT_GLOB))
    findings = sorted({f for path in paths for f in file_findings(path)})
    for finding in findings:
        print(finding)
    return 1 if findings else 0


if __name__ == "__main__":
    sys.exit(main())
