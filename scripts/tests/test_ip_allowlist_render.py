"""Check warning text with Helm because helm-unittest discards YAML comments."""

import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


CHART = Path(__file__).resolve().parents[2] / "charts" / "operator-wandb"


@unittest.skipUnless(shutil.which("helm"), "Helm is required for render checks")
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
                    check=True,
                )
                warning = (
                    "# WARNING: global.ipAllowList is disabled; configured systemCIDRs "
                    "and userCIDRs are not enforced. Enable global.ipAllowList.enabled "
                    "to use them, or remove the CIDRs."
                )
                self.assertEqual(result.stdout.count(warning), int(expect_warning))
                self.assertNotIn("kind: Middleware", result.stdout)
