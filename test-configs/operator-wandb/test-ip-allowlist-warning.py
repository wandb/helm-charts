"""Check raw Helm warning comments after building the chart dependencies.

helm-unittest discards YAML comments, so these checks render the chart directly.
"""

import json
from pathlib import Path
import subprocess
import tempfile
import unittest


CHART = Path(__file__).resolve().parents[2] / "charts" / "operator-wandb"


class IPAllowListWarningTests(unittest.TestCase):
    def test_disabled_policy_warning_in_rendered_yaml(self):
        cases = [
            ({}, False),
            ({"systemCIDRs": ["10.0.0.0/8"]}, True),
            ({"userCIDRs": ["2001:db8::/32"]}, True),
            (
                {
                    "enabled": False,
                    "systemCIDRs": ["10.0.0.0/8"],
                    "userCIDRs": ["2001:db8::/32"],
                },
                True,
            ),
            ({"enabled": True, "userCIDRs": ["192.0.2.0/24"]}, False),
        ]
        for policy, expect_warning in cases:
            with self.subTest(policy=policy), tempfile.TemporaryDirectory() as tmp:
                values = Path(tmp) / "values.json"
                values.write_text(json.dumps({"global": {"ipAllowList": policy}}))
                result = subprocess.run(
                    ["helm", "template", "warning-test", str(CHART), "-f", str(values)],
                    capture_output=True,
                    text=True,
                    check=False,
                )
                self.assertEqual(
                    result.returncode, 0, f"helm template failed:\n{result.stderr}"
                )
                warning = (
                    "# WARNING: global.ipAllowList is disabled; configured systemCIDRs "
                    "and userCIDRs are not enforced. Enable global.ipAllowList.enabled "
                    "to use them, or remove the CIDRs."
                )
                self.assertEqual(result.stdout.count(warning), int(expect_warning))
                self.assertNotIn("kind: Middleware", result.stdout)


if __name__ == "__main__":
    unittest.main()
