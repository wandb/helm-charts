import subprocess
import sys
import textwrap
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
NORMALIZER = REPO_ROOT / "scripts" / "normalize_snapshot_chart_versions.py"


class SnapshotChartVersionNormalizerTest(unittest.TestCase):
    def normalize(self, manifest: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(NORMALIZER)],
            cwd=REPO_ROOT,
            input=textwrap.dedent(manifest),
            check=False,
            capture_output=True,
            text=True,
        )

    def test_normalizes_chart_labels_in_metadata_paths(self) -> None:
        manifest = """\
            apiVersion: apps/v1
            kind: Deployment
            metadata:
              name: root
              labels:
                helm.sh/chart: root-1.2.3
            spec:
              template:
                metadata:
                  labels:
                    helm.sh/chart: dependency-4.5.6
            ---
            apiVersion: batch/v1
            kind: CronJob
            metadata:
              name: scheduled
            spec:
              jobTemplate:
                spec:
                  template:
                    metadata:
                      labels:
                        helm.sh/chart: dependency-4.5.6
        """
        expected = """\
            apiVersion: apps/v1
            kind: Deployment
            metadata:
              name: root
              labels:
                helm.sh/chart: '###CHART_VERSION###'
            spec:
              template:
                metadata:
                  labels:
                    helm.sh/chart: '###CHART_VERSION###'
            ---
            apiVersion: batch/v1
            kind: CronJob
            metadata:
              name: scheduled
            spec:
              jobTemplate:
                spec:
                  template:
                    metadata:
                      labels:
                        helm.sh/chart: '###CHART_VERSION###'
        """

        result = self.normalize(manifest)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, textwrap.dedent(expected))

    def test_preserves_selector_values(self) -> None:
        manifest = """\
            apiVersion: apps/v1
            kind: StatefulSet
            metadata:
              name: database
            spec:
              selector:
                matchLabels:
                  helm.sh/chart: database-1.2.3
              template:
                metadata:
                  labels:
                    helm.sh/chart: database-1.2.3
                    app.kubernetes.io/name: database
        """
        expected = """\
            apiVersion: apps/v1
            kind: StatefulSet
            metadata:
              name: database
            spec:
              selector:
                matchLabels:
                  helm.sh/chart: database-1.2.3
              template:
                metadata:
                  labels:
                    helm.sh/chart: '###CHART_VERSION###'
                    app.kubernetes.io/name: database
        """

        result = self.normalize(manifest)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, textwrap.dedent(expected))

    def test_does_not_create_missing_labels(self) -> None:
        manifest = """\
            apiVersion: v1
            kind: Service
            metadata:
              name: database
            spec:
              selector:
                helm.sh/chart: database-1.2.3
        """

        result = self.normalize(manifest)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, textwrap.dedent(manifest))

    def test_ignores_embedded_yaml_in_block_scalars(self) -> None:
        manifest = """\
            apiVersion: v1
            kind: ConfigMap
            metadata:
              name: embedded
              labels:
                helm.sh/chart: root-1.2.3
            data:
              manifest.yaml: |
                metadata:
                  labels:
                    helm.sh/chart: embedded-9.9.9
        """
        expected = """\
            apiVersion: v1
            kind: ConfigMap
            metadata:
              name: embedded
              labels:
                helm.sh/chart: '###CHART_VERSION###'
            data:
              manifest.yaml: |
                metadata:
                  labels:
                    helm.sh/chart: embedded-9.9.9
        """

        result = self.normalize(manifest)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, textwrap.dedent(expected))


if __name__ == "__main__":
    unittest.main()
