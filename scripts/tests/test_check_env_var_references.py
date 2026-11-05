import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
CHECKER = REPO_ROOT / "scripts" / "check_env_var_references.py"

DEPLOYMENT = """\
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
spec:
  template:
    spec:
      {key}:
      - name: api
{container}
"""


def manifest(env: str, key: str = "containers", extra: str = "") -> str:
    container = "        env:\n" + env + extra
    return DEPLOYMENT.format(key=key, container=container)


class EnvVarReferenceCheckerTest(unittest.TestCase):
    def run_checker(self, source: str) -> subprocess.CompletedProcess[str]:
        with tempfile.TemporaryDirectory() as directory:
            fixture = Path(directory) / "fixture.snap"
            fixture.write_text(source)
            return subprocess.run(
                [sys.executable, str(CHECKER), str(fixture)],
                cwd=REPO_ROOT,
                check=False,
                capture_output=True,
                text=True,
            )

    def test_accepts_reference_defined_earlier(self):
        result = self.run_checker(
            manifest(
                "        - name: MYSQL_HOST\n          value: db\n"
                "        - name: MYSQL\n          value: mysql://$(MYSQL_HOST)\n"
            )
        )
        self.assertEqual(result.returncode, 0, result.stdout)

    def test_rejects_reference_defined_later(self):
        result = self.run_checker(
            manifest(
                "        - name: MYSQL\n          value: mysql://$(MYSQL_HOST)\n"
                "        - name: MYSQL_HOST\n          value: db\n"
            )
        )
        self.assertEqual(result.returncode, 1)
        self.assertIn(
            "Deployment/api containers[api]: env MYSQL references $(MYSQL_HOST) before it is defined",
            result.stdout,
        )

    def test_rejects_undefined_reference_in_init_container(self):
        result = self.run_checker(
            manifest(
                "        - name: LIVE\n          value: $(GORILLA_HISTORY_STORAGE_ENGINE_ADDRESS)\n",
                key="initContainers",
            )
            + "      containers: []\n"
        )
        self.assertEqual(result.returncode, 1)
        self.assertIn(
            "initContainers[api]: env LIVE references undefined $(GORILLA_HISTORY_STORAGE_ENGINE_ADDRESS)",
            result.stdout,
        )

    def test_allows_undefined_reference_with_env_from(self):
        result = self.run_checker(
            manifest(
                "        - name: MYSQL\n          value: mysql://$(MYSQL_HOST)\n",
                extra="        envFrom:\n        - configMapRef:\n            name: mysql\n",
            )
        )
        self.assertEqual(result.returncode, 0, result.stdout)

    def test_ignores_escaped_reference(self):
        result = self.run_checker(
            manifest("        - name: LITERAL\n          value: $$(NOT_A_VAR)\n")
        )
        self.assertEqual(result.returncode, 0, result.stdout)

    def test_repository_snapshots_pass(self):
        result = subprocess.run(
            [sys.executable, str(CHECKER)],
            cwd=REPO_ROOT,
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, result.stdout)


if __name__ == "__main__":
    unittest.main()
