#!/usr/bin/env python3
"""Check Helm template source for maintainability problems."""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Sequence


TEMPLATE_ACTION = re.compile(r"{{-?\s*(.*?)\s*-?}}", re.DOTALL)
TEMPLATE_COMMENT = re.compile(r"{{-?\s*/\*.*?\*/\s*-?}}", re.DOTALL)
STABLE_SELECTOR = re.compile(
    r"(?:\$[A-Za-z_][A-Za-z0-9_]*|\.[A-Za-z_][A-Za-z0-9_]*)"
    r"(?:\.[A-Za-z_][A-Za-z0-9_]*)*\Z"
)
BLOCK_OPENERS = {"block", "define", "if", "range", "with"}
CONTROL_OPENERS = {"if", "range", "with"}
TEMPLATE_SUFFIXES = {".tpl", ".txt", ".yaml", ".yml"}
MAINTAINED_CHARTS = (
    "operator",
    "operator-wandb",
    "orchestrator",
    "wandb-base",
    "lumen",
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


def parse_actions(source: str) -> list[Action]:
    source_without_comments = TEMPLATE_COMMENT.sub(
        lambda match: "".join(
            "\n" if character == "\n" else " " for character in match.group(0)
        ),
        source,
    )
    return [
        Action(
            command=" ".join(match.group(1).split()),
            start=match.start(),
            end=match.end(),
        )
        for match in TEMPLATE_ACTION.finditer(source_without_comments)
    ]


def matching_end(actions: Sequence[Action], opening_index: int) -> tuple[int, bool] | None:
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


def standalone_indentation(source: str, action: Action) -> int | None:
    line_start = source.rfind("\n", 0, action.start) + 1
    line_end = source.find("\n", action.end)
    if line_end == -1:
        line_end = len(source)
    before = source[line_start : action.start]
    after = source[action.end : line_end]
    if before.strip() or after.strip():
        return None
    return len(before.expandtabs(2))


def find_control_indentation(source: str) -> list[Finding]:
    stack: list[tuple[str, int | None]] = []
    findings: list[Finding] = []

    for action in parse_actions(source):
        keyword = action.keyword
        indentation = standalone_indentation(source, action)
        line = source.count("\n", 0, action.start) + 1

        if keyword == "end":
            if not stack:
                continue
            opener, opener_indentation = stack.pop()
            if (
                indentation is not None
                and opener_indentation is not None
                and indentation != opener_indentation
            ):
                findings.append(
                    Finding(
                        line=line,
                        message=f"align end with its {opener}",
                    )
                )
            continue

        if keyword == "else":
            if stack:
                opener, opener_indentation = stack[-1]
                if (
                    indentation is not None
                    and opener_indentation is not None
                    and indentation != opener_indentation
                ):
                    findings.append(
                        Finding(
                            line=line,
                            message=f"align else with its {opener}",
                        )
                    )
            continue

        if keyword not in BLOCK_OPENERS:
            continue

        if keyword in CONTROL_OPENERS and indentation is not None:
            parent = next(
                (
                    (parent_keyword, parent_indentation)
                    for parent_keyword, parent_indentation in reversed(stack)
                    if parent_keyword in CONTROL_OPENERS
                    and parent_indentation is not None
                ),
                None,
            )
            if parent is not None and indentation <= parent[1]:
                findings.append(
                    Finding(
                        line=line,
                        message=f"indent nested {keyword} deeper than its parent",
                    )
                )

        stack.append((keyword, indentation))

    return findings


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
            print(f"{display_path(path)}: unable to read template: {error}", file=sys.stderr)
            return 2

        for finding in [
            *find_complementary_blocks(source),
            *find_control_indentation(source),
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
        help=(
            "template files or directories "
            "(defaults to maintained chart templates)"
        ),
    )
    arguments = parser.parse_args()
    return check(arguments.paths or default_paths())


if __name__ == "__main__":
    raise SystemExit(main())
