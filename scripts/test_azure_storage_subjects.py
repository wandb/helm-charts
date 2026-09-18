#!/usr/bin/env python3
"""Render the Azure federation contract, including optional storage consumers.

Run after `helm cascade build charts/operator-wandb` with PyYAML installed.
The explicit subject set is intentional: adding a service must not silently
add a customer federation prerequisite. New ordinary workers use the existing
storage account; changes to the separate privileged identities need review.
"""

from pathlib import Path
import subprocess
import tempfile
import unittest

import yaml


ROOT = Path(__file__).resolve().parent.parent
CHART = ROOT / "charts/operator-wandb"
FIXTURE = CHART / "tests/fixtures/azure_storage_consolidated.yaml"
SHARED_ACCOUNT = "wandb-bucket-access"
STORAGE_ACCOUNTS = {
    SHARED_ACCOUNT,
    "wandb-app",
    "wandb-api",
    "wandb-console",
    "wandb-glue",
    "wandb-metric-observer",
    "wandb-settings-migration-job",
    "wandb-weave-trace",
    "lumen",
}


def set_value(values, path, value):
    keys = path.split(".")
    for key in keys[:-1]:
        values = values.setdefault(key, {})
    values[keys[-1]] = value


def all_consumers():
    values = yaml.safe_load(FIXTURE.read_text())
    defaults = yaml.safe_load((CHART / "values.yaml").read_text())
    chart = yaml.safe_load((CHART / "Chart.yaml").read_text())
    for dependency in chart["dependencies"]:
        alias = dependency.get("alias", dependency["name"])
        component = defaults.get(alias, {})
        labels = component.get("podLabels", {})
        if "azure.workload.identity/use" in labels:
            # Discover consumers from chart metadata, so newly added aliases
            # participate without extending a second component list here.
            condition = dependency["condition"].split(",")[-1]
            set_value(values, condition, True)
    values["global"]["weave-trace"] = {"fileStorage": {"useDefaultBucket": True}}
    return values


def render(chart, values, release="wandb"):
    with tempfile.NamedTemporaryFile(mode="w", suffix=".yaml") as fixture:
        yaml.safe_dump(values, fixture)
        fixture.flush()
        result = subprocess.run(
            ["helm", "template", release, str(chart), "--namespace", "storage-test",
             "--values", fixture.name],
            check=True, capture_output=True, text=True,
        )
    return [doc for doc in yaml.safe_load_all(result.stdout) if doc]


def pod_template(resource):
    kind = resource["kind"]
    if kind == "CronJob":
        return resource["spec"]["jobTemplate"]["spec"]["template"]
    if kind in {"Deployment", "StatefulSet", "DaemonSet", "Job"}:
        return resource["spec"]["template"]
    if kind == "Pod":
        return resource
    return None


class AzureStorageSubjects(unittest.TestCase):
    def assert_subject_contract(self, values):
        resources = render(CHART, values)
        accounts = set()
        for resource in resources:
            template = pod_template(resource)
            if template and str(template.get("metadata", {}).get("labels", {}).get(
                "azure.workload.identity/use", "false"
            )).lower() == "true":
                account = template["spec"].get("serviceAccountName", "default")
                self.assertIn(account, STORAGE_ACCOUNTS, resource["metadata"]["name"])
                accounts.add(account)
            if resource["kind"] in {"RoleBinding", "ClusterRoleBinding"}:
                for subject in resource.get("subjects", []):
                    self.assertNotEqual(subject.get("name"), SHARED_ACCOUNT,
                                        resource["metadata"]["name"])
        # All optional consumers are enabled, so dropping an entire identity
        # group must not make the subset check pass accidentally.
        self.assertEqual(accounts, STORAGE_ACCOUNTS)
        shared = [r for r in resources if r["kind"] == "ServiceAccount"
                  and r["metadata"]["name"] == SHARED_ACCOUNT]
        self.assertEqual(len(shared), 1)
        self.assertEqual(shared[0]["metadata"]["annotations"][
            "azure.workload.identity/client-id"], "deployment-client")

    def test_default_bucket_subjects(self):
        values = all_consumers()
        values["global"]["bucket"]["name"] = None
        self.assert_subject_contract(values)

    def test_customer_bucket_subjects(self):
        self.assert_subject_contract(all_consumers())

    def test_consolidation_requires_deployment_identity(self):
        values = yaml.safe_load(FIXTURE.read_text())
        values["global"]["azureStorageIdentity"].update(tenantId=None, clientId=None)
        with self.assertRaises(subprocess.CalledProcessError) as failure:
            render(CHART, values)
        self.assertIn(
            "consolidated Azure storage accounts require global.azureStorageIdentity.tenantId and clientId",
            failure.exception.stderr,
        )

    def test_bundled_bufstream_keeps_its_node_reader_identity(self):
        # Managed Bufstream is deployed separately with internal storage. The
        # optional bundled chart is not a customer BYOB federation prerequisite.
        values = yaml.safe_load(FIXTURE.read_text())
        values["global"]["bucket"]["name"] = None
        values["bufstream"] = {"install": True, "discoverZoneFromNode": True}
        resources = render(CHART, values)
        deployment = next(r for r in resources if r["kind"] in {"Deployment", "StatefulSet"}
                          and r["metadata"]["name"] == "bufstream")
        self.assertEqual(deployment["spec"]["template"]["spec"][
            "serviceAccountName"], "bufstream-service-account")
        bindings = [r for r in resources if r["kind"] == "ClusterRoleBinding"
                    and any(s.get("name") == "bufstream-service-account"
                            for s in r.get("subjects", []))]
        self.assertEqual(len(bindings), 1)

    def test_new_worker_uses_existing_subject(self):
        values = yaml.safe_load(FIXTURE.read_text())
        values["podLabels"] = {"azure.workload.identity/use": "true"}
        values["fullnameOverride"] = "a-new-storage-worker"
        resources = render(ROOT / "charts/wandb-base", values, "new-worker")
        deployments = [r for r in resources if r["kind"] == "Deployment"]
        self.assertEqual(len(deployments), 1)
        self.assertEqual(deployments[0]["spec"]["template"]["spec"][
            "serviceAccountName"], SHARED_ACCOUNT)
        self.assertFalse(any(r["kind"] == "ServiceAccount" for r in resources))

    def test_worker_without_wif_keeps_its_identity(self):
        values = yaml.safe_load(FIXTURE.read_text())
        values["podLabels"] = {"azure.workload.identity/use": "false"}
        values["fullnameOverride"] = "non-storage-worker"
        resources = render(ROOT / "charts/wandb-base", values)
        deployment = next(r for r in resources if r["kind"] == "Deployment")
        self.assertEqual(deployment["spec"]["template"]["spec"][
            "serviceAccountName"], "non-storage-worker")


if __name__ == "__main__":
    unittest.main()
