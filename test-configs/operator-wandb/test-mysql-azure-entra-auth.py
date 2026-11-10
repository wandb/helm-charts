"""Check that every MySQL pod gets Azure workload identity in Entra ID mode.

Run after building the chart dependencies.
"""

from pathlib import Path
import subprocess
import tempfile
import unittest

import yaml


CHART = Path(__file__).resolve().parents[2] / "charts" / "operator-wandb"
WORKLOAD_IDENTITY_LABEL = "azure.workload.identity/use"
MYSQL_ENV_NAMES = {"GORILLA_METADATA_STORE", "MYSQL_USER"}
# The OpenTelemetry agent receives MySQL host and user as config only. It has no
# password or DSN and never connects to MySQL.
NON_CONNECTING_PODS = {("DaemonSet", "wandb-otel-daemonset")}

MYSQL_WORKLOADS = [
    "api",
    "app",
    "executor",
    "filemeta",
    "filestream",
    "flat-run-fields-updater",
    "glue",
    "history-updater",
    "metric-observer",
    "parquet",
    "parquet-metadata-cache",
    "run-store-accelerator-run-updater",
]

EXPECTED_MYSQL_PODS = {
    *(("Deployment", f"wandb-{name}") for name in MYSQL_WORKLOADS),
    ("CronJob", "wandb-parquet-backfill"),
}

VALUES = {
    "global": {
        "api": {"enabled": True},
        "glue": {"enabled": True},
        "mysql": {
            "azureEntraAuth": True,
            "host": "wandb.mysql.database.azure.com",
            "port": 3306,
            "database": "wandb",
            "user": "wandb-identity",
            "password": "",
        },
    },
    "app": {"initContainers": {"init-db": {"enabled": False}}},
    "prometheus": {"mysql-exporter": {"install": False}},
    **{
        name: {"install": True}
        for name in MYSQL_WORKLOADS
        if name not in ("api", "app", "glue")
    },
}


def render(values):
    with tempfile.NamedTemporaryFile("w", suffix=".yaml") as values_file:
        yaml.safe_dump(values, values_file)
        values_file.flush()
        result = subprocess.run(
            [
                "helm",
                "template",
                "wandb",
                str(CHART),
                "--namespace",
                "default",
                "--values",
                values_file.name,
            ],
            capture_output=True,
            text=True,
        )
    if result.returncode:
        raise AssertionError(f"helm template failed:\n{result.stderr}")
    return [doc for doc in yaml.safe_load_all(result.stdout) if doc]


def pod_template(document):
    spec = document.get("spec") or {}
    if document["kind"] == "CronJob":
        return spec["jobTemplate"]["spec"]["template"]
    if document["kind"] in ("Deployment", "StatefulSet", "DaemonSet", "Job"):
        return spec["template"]
    return None


def uses_mysql(pod):
    spec = pod.get("spec") or {}
    containers = (spec.get("containers") or []) + (spec.get("initContainers") or [])
    return any(
        env.get("name") in MYSQL_ENV_NAMES
        for container in containers
        for env in container.get("env") or []
    )


class AzureEntraWorkloadIdentityTests(unittest.TestCase):
    def test_every_mysql_pod_has_the_workload_identity_label(self):
        mysql_pods = {}
        for document in render(VALUES):
            pod = pod_template(document)
            if pod is not None and uses_mysql(pod):
                # Some Deployments render under a "-bc" name during the app rename.
                name = document["metadata"]["name"].removesuffix("-bc")
                key = (document["kind"], name)
                if key in NON_CONNECTING_PODS:
                    continue
                mysql_pods[key] = (pod.get("metadata") or {}).get("labels") or {}

        self.assertLessEqual(EXPECTED_MYSQL_PODS, set(mysql_pods))
        for key, labels in sorted(mysql_pods.items()):
            with self.subTest(workload=key):
                self.assertEqual(labels.get(WORKLOAD_IDENTITY_LABEL), "true")


if __name__ == "__main__":
    unittest.main()
