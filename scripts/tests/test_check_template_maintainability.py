import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


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


if __name__ == "__main__":
    unittest.main()
