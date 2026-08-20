import json
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
SCHEMA_PATH = REPO_ROOT / "charts" / "operator-wandb" / "values.schema.json"


class OperatorMcpSchemaTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.schema = json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))
        cls.mcp = cls.schema["properties"]["mcp-server"]["properties"]

    def test_dedicated_tool_profiles_are_exact(self) -> None:
        self.assertEqual(
            self.mcp["tools"]["properties"]["profile"]["enum"],
            ["auto", "models-only", "models-weave"],
        )

    def test_access_and_observability_are_typed(self) -> None:
        self.assertEqual(
            self.mcp["accessMode"]["enum"],
            ["read-write", "read-only"],
        )
        self.assertEqual(
            self.mcp["observability"]["properties"]["provider"]["enum"],
            ["none", "datadog-agent", "otel"],
        )

    def test_image_digest_is_immutable_sha256_or_unset(self) -> None:
        self.assertEqual(
            self.mcp["image"]["properties"]["digest"]["pattern"],
            "^(|sha256:[a-f0-9]{64})$",
        )


if __name__ == "__main__":
    unittest.main()
