"""Check that every MySQL pod gets the Cloud SQL Auth Proxy sidecar.

Run after building the chart dependencies.
"""

from pathlib import Path
import importlib.util
import unittest


HERE = Path(__file__).resolve().parent
_spec = importlib.util.spec_from_file_location(
    "mysql_azure_entra_auth", HERE / "test-mysql-azure-entra-auth.py"
)
entra = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(entra)

SIDECAR = "cloud-sql-proxy"

VALUES = {
    **entra.VALUES,
    "global": {
        **entra.VALUES["global"],
        "mysql": {
            "cloudSqlProxy": {
                "enabled": True,
                "instanceConnectionName": "wandb-project:us-central1:wandb-instance",
            },
            "host": "",
            "port": 3306,
            "database": "wandb",
            "user": "wandb-sa",
            "password": "",
        },
    },
}


class CloudSqlProxySidecarTests(unittest.TestCase):
    def test_every_mysql_pod_has_the_proxy_sidecar(self):
        mysql_pods = {}
        for document in entra.render(VALUES):
            pod = entra.pod_template(document)
            if pod is not None and entra.uses_mysql(pod):
                name = document["metadata"]["name"].removesuffix("-bc")
                key = (document["kind"], name)
                if key in entra.NON_CONNECTING_PODS:
                    continue
                mysql_pods[key] = pod["spec"].get("initContainers") or []

        self.assertLessEqual(entra.EXPECTED_MYSQL_PODS, set(mysql_pods))
        for key, init_containers in sorted(mysql_pods.items()):
            with self.subTest(workload=key):
                first = init_containers[0] if init_containers else {}
                self.assertEqual(first.get("name"), SIDECAR)
                self.assertEqual(first.get("restartPolicy"), "Always")


if __name__ == "__main__":
    unittest.main()
