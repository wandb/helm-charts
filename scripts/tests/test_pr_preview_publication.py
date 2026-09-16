import unittest
from pathlib import Path


WORKFLOW = Path(__file__).resolve().parents[2] / ".github/workflows/pr-release.yaml"


class PrPreviewPublicationTest(unittest.TestCase):
    def test_preview_targets_only_main_and_the_mcp_stack_base(self) -> None:
        workflow = WORKFLOW.read_text(encoding="utf-8")
        trigger = workflow.split("\non:\n", 1)[1].split("\njobs:\n", 1)[0]
        lines = [
            line.strip()
            for line in trigger.splitlines()
            if line.strip() and not line.lstrip().startswith("#")
        ]
        self.assertEqual(
            lines,
            [
                "pull_request:",
                "branches:",
                "- main",
                "- codex/mcp-chart-env-isolation",
            ],
        )


if __name__ == "__main__":
    unittest.main()
