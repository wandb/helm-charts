#!/usr/bin/env python3
"""Format maintained Helm templates with helmfmt while preserving block comments.

helmfmt v0.5.0 flattens relative indentation inside multiline template comments
and adds spaces to blank comment lines. Remove this protection when a pinned
helmfmt release preserves structured comments itself.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from collections.abc import Callable
from dataclasses import dataclass
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parent.parent
MAINTAINED_CHARTS_FILE = Path(__file__).with_name("maintained_charts.txt")
TEMPLATE_SUFFIXES = {".tpl", ".yaml", ".yml"}
TEMPLATE_COMMENT = re.compile(r"{{-?\s*/\*.*?\*/\s*-?}}", re.DOTALL)
COMMENT_TOKEN_PREFIX = "HELMFMT_PRESERVE_COMMENT_"


@dataclass(frozen=True)
class ProtectedComment:
    token: str
    source: str


def protect_multiline_comments(source: str) -> tuple[str, list[ProtectedComment]]:
    comments: list[ProtectedComment] = []

    def protect(match: re.Match[str]) -> str:
        comment = match.group(0)
        line_start = source.rfind("\n", 0, match.start()) + 1
        line_end = source.find("\n", match.end())
        if line_end == -1:
            line_end = len(source)

        if (
            "\n" not in comment
            or source[line_start : match.start()].strip()
            or source[match.end() : line_end].strip()
        ):
            return comment

        indentation = source[line_start : match.start()]
        comment_lines = comment.splitlines()
        relative_comment_lines = [comment_lines[0]]
        for line in comment_lines[1:]:
            if line.lstrip().startswith("*/"):
                relative_comment_lines.append(line.lstrip())
            elif indentation and line.startswith(indentation):
                relative_comment_lines.append(line[len(indentation) :])
            else:
                relative_comment_lines.append(line)

        token = f"{{{{/* {COMMENT_TOKEN_PREFIX}{len(comments)} */}}}}"
        comments.append(
            ProtectedComment(
                token=token,
                source="\n".join(relative_comment_lines),
            )
        )
        return token

    return TEMPLATE_COMMENT.sub(protect, source), comments


def restore_multiline_comments(
    formatted_source: str, comments: list[ProtectedComment]
) -> str:
    for comment in comments:
        token_start = formatted_source.find(comment.token)
        if token_start == -1:
            raise ValueError(f"helmfmt removed protected comment {comment.token}")

        line_start = formatted_source.rfind("\n", 0, token_start) + 1
        indentation = formatted_source[line_start:token_start]
        if indentation.strip():
            raise ValueError(f"helmfmt moved protected comment {comment.token}")

        comment_lines = comment.source.splitlines()
        restored_lines = [comment_lines[0]]
        restored_lines.extend(
            f"{indentation}{line.rstrip()}" if line.strip() else ""
            for line in comment_lines[1:]
        )
        restored = "\n".join(restored_lines)
        formatted_source = (
            formatted_source[:token_start]
            + restored
            + formatted_source[token_start + len(comment.token) :]
        )

    return formatted_source


def format_source(source: str, formatter: Callable[[str], str]) -> str:
    protected_source, comments = protect_multiline_comments(source)
    return restore_multiline_comments(formatter(protected_source), comments)


def run_helmfmt(source: str) -> str:
    result = subprocess.run(
        ["helmfmt", "--stdout"],
        cwd=REPO_ROOT,
        input=source,
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or "helmfmt failed")
    return result.stdout


def template_files() -> list[Path]:
    charts = [
        chart for chart in MAINTAINED_CHARTS_FILE.read_text().splitlines() if chart
    ]
    return sorted(
        path
        for chart in charts
        for path in (REPO_ROOT / "charts" / chart / "templates").rglob("*")
        if path.is_file() and path.suffix in TEMPLATE_SUFFIXES
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check",
        action="store_true",
        help="report files that need formatting without changing them",
    )
    arguments = parser.parse_args()

    unformatted = 0
    try:
        for path in template_files():
            source = path.read_text()
            formatted = format_source(source, run_helmfmt)
            if formatted == source:
                continue

            relative_path = path.relative_to(REPO_ROOT)
            if arguments.check:
                unformatted += 1
                print(f"[UNFORMATTED] {relative_path}")
            else:
                path.write_text(formatted)
                print(f"[UPDATED] {relative_path}")
    except (OSError, UnicodeError, RuntimeError, ValueError) as error:
        print(f"template formatting failed: {error}", file=sys.stderr)
        return 2

    return 1 if unformatted else 0


if __name__ == "__main__":
    raise SystemExit(main())
