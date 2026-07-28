#!/usr/bin/env python3
"""Normalize non-semantic Helm chart-version labels in rendered manifests."""

from __future__ import annotations

import re
import sys


PLACEHOLDER = "'###CHART_VERSION###'"
CHART_LABEL = "helm.sh/chart"
SELECTOR_KEYS = {"selector", "matchLabels"}

MAPPING_ENTRY = re.compile(
    r"""^(?P<indent> *)(?P<sequence>-\s+)?"""
    r"""(?P<key>'[^']*'|"[^"]*"|[^:#][^:]*?)"""
    r"""(?P<separator>:\s*)(?P<rest>.*)$"""
)
BLOCK_SCALAR = re.compile(
    r"^[>|](?:[1-9][+-]?|[+-][1-9]?)?(?:\s+#.*)?$"
)
INLINE_COMMENT = re.compile(r"(?P<comment>\s+#.*)$")


def unquote_key(key: str) -> str:
    if len(key) >= 2 and key[0] == key[-1] and key[0] in {"'", '"'}:
        return key[1:-1]
    return key


def is_chart_metadata_path(path: tuple[str, ...]) -> bool:
    return (
        path[-3:] == ("metadata", "labels", CHART_LABEL)
        and not SELECTOR_KEYS.intersection(path[:-3])
    )


def normalize(manifest: str) -> str:
    output: list[str] = []
    containers: list[tuple[int, str]] = []
    block_scalar_indent: int | None = None

    for line in manifest.splitlines(keepends=True):
        body = line.rstrip("\r\n")
        newline = line[len(body) :]
        indent = len(body) - len(body.lstrip(" "))

        if block_scalar_indent is not None:
            if not body.strip() or indent > block_scalar_indent:
                output.append(line)
                continue
            block_scalar_indent = None

        if body.strip() in {"---", "..."}:
            containers.clear()
            output.append(line)
            continue

        entry = MAPPING_ENTRY.match(body)
        if entry is None:
            output.append(line)
            continue

        key = unquote_key(entry.group("key"))
        while containers and containers[-1][0] >= indent:
            containers.pop()
        path = tuple(container_key for _, container_key in containers) + (key,)

        if is_chart_metadata_path(path):
            comment_match = INLINE_COMMENT.search(entry.group("rest"))
            comment = comment_match.group("comment") if comment_match else ""
            prefix = body[: entry.start("separator")]
            output.append(f"{prefix}: {PLACEHOLDER}{comment}{newline}")
            continue

        value = entry.group("rest").strip()
        if BLOCK_SCALAR.fullmatch(value):
            block_scalar_indent = indent
        elif not value or value.startswith("#"):
            containers.append((indent, key))

        output.append(line)

    return "".join(output)


def main() -> None:
    sys.stdout.write(normalize(sys.stdin.read()))


if __name__ == "__main__":
    main()
