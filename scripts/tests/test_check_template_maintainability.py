import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

from scripts.check_template_maintainability import MAINTAINED_CHARTS


REPO_ROOT = Path(__file__).resolve().parents[2]
CHECKER = REPO_ROOT / "scripts" / "check_template_maintainability.py"


class TemplateMaintainabilityCheckerTest(unittest.TestCase):
    def run_checker(self, source: str) -> subprocess.CompletedProcess[str]:
        with tempfile.TemporaryDirectory() as directory:
            fixture = Path(directory) / "fixture.tpl"
            fixture.write_text(source)
            return subprocess.run(
                [sys.executable, str(CHECKER), str(fixture)],
                cwd=REPO_ROOT,
                check=False,
                capture_output=True,
                text=True,
            )

    def run_default_checker(
        self, fixtures: dict[str, str]
    ) -> subprocess.CompletedProcess[str]:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for relative_path, source in fixtures.items():
                fixture = root / relative_path
                fixture.parent.mkdir(parents=True, exist_ok=True)
                fixture.write_text(source)
            return subprocess.run(
                [sys.executable, str(CHECKER)],
                cwd=root,
                check=False,
                capture_output=True,
                text=True,
            )

    def test_default_scan_covers_only_maintained_chart_templates(self) -> None:
        complementary_blocks = """{{- if not $identity.enabled }}
disabled
{{- end }}
{{- if $identity.enabled }}
enabled
{{- end }}
"""
        fixtures = {
            f"charts/{chart}/templates/fixture.tpl": complementary_blocks
            for chart in MAINTAINED_CHARTS
        }
        fixtures["charts/wandb/templates/fixture.tpl"] = complementary_blocks
        fixtures[
            "charts/operator-wandb/charts/dependency/templates/fixture.tpl"
        ] = complementary_blocks

        result = self.run_default_checker(fixtures)

        self.assertEqual(result.returncode, 1)
        self.assertEqual(
            result.stdout.count("combine complementary conditions with if/else"),
            len(MAINTAINED_CHARTS),
        )
        for chart in MAINTAINED_CHARTS:
            self.assertIn(f"charts/{chart}/templates/fixture.tpl:1:", result.stdout)
        self.assertNotIn("charts/wandb/templates", result.stdout)
        self.assertNotIn("charts/operator-wandb/charts", result.stdout)

    def test_rejects_adjacent_complementary_if_blocks(self) -> None:
        result = self.run_checker(
            """{{- if not $identity.enabled }}
- name: ACCESS_KEY
{{- end }}
{{- if $identity.enabled }}
- name: CLIENT_ID
{{- end }}
"""
        )

        self.assertEqual(result.returncode, 1)
        self.assertIn("fixture.tpl:1:", result.stdout)
        self.assertIn("combine complementary conditions with if/else", result.stdout)
        self.assertEqual(result.stdout.count("combine complementary conditions"), 1)

    def test_accepts_if_else(self) -> None:
        result = self.run_checker(
            """{{- if $identity.enabled }}
- name: CLIENT_ID
{{- else }}
- name: ACCESS_KEY
{{- end }}
"""
        )

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(result.stdout, "")

    def test_accepts_adjacent_blocks_with_different_conditions(self) -> None:
        result = self.run_checker(
            """{{- if not $identity.enabled }}
- name: ACCESS_KEY
{{- end }}
{{- if $identity.clientId }}
- name: CLIENT_ID
{{- end }}
"""
        )

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_ignores_complementary_dynamic_expressions(self) -> None:
        result = self.run_checker(
            """{{- if not (include "identity.enabled" .) }}
- name: ACCESS_KEY
{{- end }}
{{- if (include "identity.enabled" .) }}
- name: CLIENT_ID
{{- end }}
"""
        )

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_matches_across_nested_control_blocks(self) -> None:
        result = self.run_checker(
            """{{- if $identity.enabled }}
{{- if $identity.clientId }}
- name: CLIENT_ID
{{- end }}
{{- end }}
{{- if not $identity.enabled }}
- name: ACCESS_KEY
{{- end }}
"""
        )

        self.assertEqual(result.returncode, 1)
        self.assertEqual(result.stdout.count("combine complementary conditions"), 1)

    def test_does_not_combine_independent_blocks_separated_by_output(self) -> None:
        result = self.run_checker(
            """{{- if $identity.enabled }}
- name: CLIENT_ID
{{- end }}
- name: ALWAYS_PRESENT
{{- if not $identity.enabled }}
- name: ACCESS_KEY
{{- end }}
"""
        )

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_rejects_nested_control_blocks_at_the_parent_indentation(self) -> None:
        result = self.run_checker(
            """{{- if $identity.enabled }}
{{- if $identity.clientId }}
- name: CLIENT_ID
{{- end }}
{{- end }}
"""
        )

        self.assertEqual(result.returncode, 1)
        self.assertIn("indent nested if deeper than its parent", result.stdout)

    def test_rejects_control_boundaries_not_aligned_with_their_block(self) -> None:
        result = self.run_checker(
            """{{- if $identity.enabled }}
  {{- if $identity.clientId }}
- name: CLIENT_ID
{{- else }}
- name: DEFAULT_CLIENT_ID
{{- end }}
{{- end }}
"""
        )

        self.assertEqual(result.returncode, 1)
        self.assertIn("align else with its if", result.stdout)
        self.assertIn("align end with its if", result.stdout)

    def test_accepts_indented_nested_control_flow(self) -> None:
        result = self.run_checker(
            """{{- if $identity.enabled }}
  {{- if $identity.clientId }}
- name: CLIENT_ID
  {{- else }}
- name: DEFAULT_CLIENT_ID
  {{- end }}
{{- end }}
"""
        )

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_ignores_template_actions_inside_comments(self) -> None:
        result = self.run_checker(
            """{{- define "example" -}}
{{- if $identity.enabled }}
  {{- /*
    {{- if $commented.example }}
    {{- end }}
  */}}
{{- end }}
{{- end }}
"""
        )

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
