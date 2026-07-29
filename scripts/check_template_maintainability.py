#!/usr/bin/env python3
"""Check Helm template source for maintainability gaps not covered by helmfmt.

Re-evaluate these checks when the pinned helmfmt release gains equivalent
functionality; repository-owned rules should be removed when upstream can
enforce them reliably.
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Sequence


TEMPLATE_ACTION = re.compile(r"{{-?\s*(.*?)\s*-?}}", re.DOTALL)
TEMPLATE_COMMENT = re.compile(r"{{-?\s*/\*.*?\*/\s*-?}}", re.DOTALL)
LEFT_CHOMP_PADDING = re.compile(r"(?m)^[ \t]*{{-[ \t]{2,}(?=\S)")
STABLE_SELECTOR = re.compile(
    r"(?:\$[A-Za-z_][A-Za-z0-9_]*|\.[A-Za-z_][A-Za-z0-9_]*)"
    r"(?:\.[A-Za-z_][A-Za-z0-9_]*)*\Z"
)
BLOCK_OPENERS = {"block", "define", "if", "range", "with"}
TEMPLATE_SUFFIXES = {".tpl", ".txt", ".yaml", ".yml"}
MAINTAINED_CHARTS = tuple(
    chart
    for chart in Path(__file__)
    .with_name("maintained_charts.txt")
    .read_text()
    .splitlines()
    if chart
)


@dataclass(frozen=True)
class Action:
    command: str
    start: int
    end: int

    @property
    def keyword(self) -> str:
        return self.command.split(maxsplit=1)[0] if self.command else ""


@dataclass(frozen=True)
class Finding:
    line: int
    message: str


def without_template_comments(source: str) -> str:
    return TEMPLATE_COMMENT.sub(
        lambda match: "".join(
            "\n" if character == "\n" else " " for character in match.group(0)
        ),
        source,
    )


def parse_actions(source: str) -> list[Action]:
    source_without_comments = without_template_comments(source)
    return [
        Action(
            command=" ".join(match.group(1).split()),
            start=match.start(),
            end=match.end(),
        )
        for match in TEMPLATE_ACTION.finditer(source_without_comments)
    ]


def matching_end(
    actions: Sequence[Action], opening_index: int
) -> tuple[int, bool] | None:
    depth = 1
    has_top_level_else = False
    for index in range(opening_index + 1, len(actions)):
        keyword = actions[index].keyword
        if keyword in BLOCK_OPENERS:
            depth += 1
        elif keyword == "end":
            depth -= 1
            if depth == 0:
                return index, has_top_level_else
        elif keyword == "else" and depth == 1:
            has_top_level_else = True
    return None


def if_condition(action: Action) -> str | None:
    if action.keyword != "if":
        return None
    _, separator, condition = action.command.partition(" ")
    return condition if separator and condition else None


def condition_polarity(condition: str) -> tuple[bool, str]:
    if condition.startswith("not "):
        return True, condition.removeprefix("not ").strip()
    return False, condition


def find_complementary_blocks(source: str) -> list[Finding]:
    actions = parse_actions(source)
    findings: list[Finding] = []

    for index, action in enumerate(actions):
        condition = if_condition(action)
        if condition is None:
            continue

        block_end = matching_end(actions, index)
        if block_end is None:
            continue
        end_index, has_else = block_end
        if has_else or end_index + 1 >= len(actions):
            continue

        next_action = actions[end_index + 1]
        if source[actions[end_index].end : next_action.start].strip():
            continue
        next_condition = if_condition(next_action)
        if next_condition is None:
            continue

        negated, expression = condition_polarity(condition)
        next_negated, next_expression = condition_polarity(next_condition)
        if (
            STABLE_SELECTOR.fullmatch(expression)
            and expression == next_expression
            and negated != next_negated
        ):
            findings.append(
                Finding(
                    line=source.count("\n", 0, action.start) + 1,
                    message=(
                        "combine complementary conditions with if/else "
                        f"(condition: {expression})"
                    ),
                )
            )

    return findings


def find_left_chomp_padding(source: str) -> list[Finding]:
    source_without_comments = without_template_comments(source)
    return [
        Finding(
            line=source_without_comments.count("\n", 0, match.start()) + 1,
            message="use one space inside the template action after '{{-'",
        )
        for match in LEFT_CHOMP_PADDING.finditer(source_without_comments)
    ]


def template_files(paths: Iterable[Path]) -> list[Path]:
    files: set[Path] = set()
    for path in paths:
        if path.is_dir():
            files.update(
                candidate
                for candidate in path.rglob("*")
                if candidate.is_file() and candidate.suffix in TEMPLATE_SUFFIXES
            )
        elif path.is_file():
            files.add(path)
    return sorted(files)


def default_paths() -> list[Path]:
    paths = [Path("charts") / chart / "templates" for chart in MAINTAINED_CHARTS]
    return [path for path in paths if path.is_dir()]


def display_path(path: Path) -> str:
    try:
        return str(path.resolve().relative_to(Path.cwd().resolve()))
    except ValueError:
        return path.name


def check(paths: Sequence[Path]) -> int:
    had_finding = False
    for path in template_files(paths):
        try:
            source = path.read_text()
        except (OSError, UnicodeError) as error:
            print(
                f"{display_path(path)}: unable to read template: {error}",
                file=sys.stderr,
            )
            return 2

        for finding in [
            *find_complementary_blocks(source),
            *find_left_chomp_padding(source),
        ]:
            had_finding = True
            print(f"{display_path(path)}:{finding.line}: {finding.message}")
    return 1 if had_finding else 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "paths",
        nargs="*",
        type=Path,
        help=("template files or directories (defaults to maintained chart templates)"),
    )
    arguments = parser.parse_args()
    return check(arguments.paths or default_paths())


if __name__ == "__main__":
    raise SystemExit(main())
