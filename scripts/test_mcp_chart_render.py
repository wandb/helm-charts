#!/usr/bin/env python3
"""Focused render tests for operator-wandb's MCP deployment contract."""

from __future__ import annotations

import re
import subprocess
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
CHART = REPO_ROOT / "charts" / "operator-wandb"
MCP_DEPLOYMENT = "charts/mcp-server/templates/deployment.yaml"
PUBLIC_URL = "https://customer.wandb.io"


def _render(
    *,
    release: str = "routing-test",
    namespace: str = "customer-wandb",
    values: dict[str, str | bool | int] | None = None,
    mcp_only: bool = True,
) -> subprocess.CompletedProcess[str]:
    command = [
        "helm",
        "template",
        release,
        str(CHART),
        "--namespace",
        namespace,
    ]
    for name, value in (values or {}).items():
        flag = "--set" if isinstance(value, (bool, int)) else "--set-string"
        rendered = str(value).lower() if isinstance(value, bool) else str(value)
        command.extend((flag, f"{name}={rendered}"))
    if mcp_only:
        command.extend(("--show-only", MCP_DEPLOYMENT))
    return subprocess.run(
        command,
        cwd=REPO_ROOT,
        check=False,
        capture_output=True,
        text=True,
    )


def _values(**overrides: str | bool | int) -> dict[str, str | bool | int]:
    values: dict[str, str | bool | int] = {
        "mcp-server.install": True,
        "global.host": PUBLIC_URL,
    }
    values.update(overrides)
    return values


def _env(manifest: str, name: str) -> str:
    match = re.search(
        rf"(?m)^\s*- name:\s*{re.escape(name)}\s*$\n^\s+value:\s*(.+?)\s*$",
        manifest,
    )
    if match is None:
        raise AssertionError(f"missing {name} in rendered MCP environment")
    return match.group(1).strip().strip("\"'")


def _has_resource(manifest: str, kind: str, name: str) -> bool:
    return any(
        re.search(rf"(?m)^kind:\s*{re.escape(kind)}\s*$", document)
        and re.search(rf"(?m)^  name:\s*{re.escape(name)}\s*$", document)
        for document in manifest.split("\n---")
    )


class McpChartRenderTest(unittest.TestCase):
    def assert_success(self, result: subprocess.CompletedProcess[str]) -> str:
        self.assertEqual(result.returncode, 0, result.stderr)
        return result.stdout

    def test_internal_url_matches_the_active_topology(self) -> None:
        cases = (
            (True, "customer-a", "dedicated-prod", "api", 8081),
            (False, "customer-b", "self-managed", "app", 8080),
        )
        for split_api, release, namespace, service, port in cases:
            with self.subTest(split_api=split_api):
                values = _values(**{"global.api.enabled": split_api})
                manifest = self.assert_success(
                    _render(release=release, namespace=namespace, values=values)
                )
                self.assertEqual(_env(manifest, "WANDB_BASE_URL"), PUBLIC_URL)
                self.assertEqual(
                    _env(manifest, "WANDB_INTERNAL_BASE_URL"),
                    f"http://{release}-{service}:{port}",
                )
                complete = self.assert_success(
                    _render(
                        release=release,
                        namespace=namespace,
                        values=values,
                        mcp_only=False,
                    )
                )
                self.assertTrue(
                    _has_resource(complete, "Service", f"{release}-{service}")
                )

    def test_explicit_internal_url_overrides_both_topologies(self) -> None:
        override = "http://external-api.platform.svc.cluster.local:9090"
        for split_api in (False, True):
            manifest = self.assert_success(
                _render(
                    values=_values(
                        **{
                            "global.api.enabled": split_api,
                            "mcp-server.env.WANDB_INTERNAL_BASE_URL": override,
                        }
                    )
                )
            )
            self.assertEqual(_env(manifest, "WANDB_INTERNAL_BASE_URL"), override)
            self.assertEqual(manifest.count("name: WANDB_INTERNAL_BASE_URL"), 1)

    def test_nonstandard_backends_require_an_explicit_url(self) -> None:
        cases: tuple[dict[str, str | bool | int], ...] = (
            {"global.api.enabled": True, "api.service.enabled": False},
            {"global.api.enabled": True, "api.service.name": "custom-api"},
            {"global.api.enabled": True, "api.nameOverride": "custom-api"},
            {"global.api.enabled": True, "api.fullnameOverride": "custom-api"},
            {"global.api.enabled": True, "api.service.ports[0].port": 9081},
            {"global.api.enabled": False, "app.install": False},
            {"global.api.enabled": False, "app.service.enabled": False},
            {"global.api.enabled": False, "app.service.name": "custom-app"},
            {"global.api.enabled": False, "app.nameOverride": "custom-app"},
            {"global.api.enabled": False, "app.fullnameOverride": "custom-app"},
            {"global.api.enabled": False, "app.service.ports[0].port": 9080},
        )
        override = "http://custom-backend.platform.svc.cluster.local:9090"
        for values in cases:
            with self.subTest(values=values, override=False):
                result = _render(values=_values(**values))
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("WANDB_INTERNAL_BASE_URL is required", result.stderr)
            with self.subTest(values=values, override=True):
                manifest = self.assert_success(
                    _render(
                        values=_values(
                            **{
                                **values,
                                "mcp-server.env.WANDB_INTERNAL_BASE_URL": override,
                            }
                        )
                    )
                )
                self.assertEqual(_env(manifest, "WANDB_INTERNAL_BASE_URL"), override)

    def test_mcp_validation_is_scoped_to_enabled_mcp(self) -> None:
        disabled = _render(
            values={
                "mcp-server.install": False,
                "mcp-server.performance.profile": "invalid",
                "mcp-server.env.MCP_WORKLOAD_PROFILE": "invalid",
                "mcp-server.env.WANDB_INTERNAL_BASE_URL": "",
            },
            mcp_only=False,
        )
        self.assertNotIn("/charts/mcp-server/", self.assert_success(disabled))

        enabled = _render(
            values=_values(**{"mcp-server.env.WANDB_INTERNAL_BASE_URL": ""})
        )
        self.assertNotEqual(enabled.returncode, 0)
        self.assertIn("must be non-empty", enabled.stderr)

    def test_size_profiles_render_bounded_runtime_settings(self) -> None:
        capacities = {
            None: ("4", "4"),
            "small": ("4", "4"),
            "medium": ("4", "8"),
            "large": ("8", "16"),
            "xlarge": ("8", "16"),
            "xxlarge": ("8", "16"),
        }
        for size, expected in capacities.items():
            values = _values(**{"global.api.enabled": True})
            if size is not None:
                values["global.size"] = size
            manifest = self.assert_success(_render(values=values))
            self.assertEqual(_env(manifest, "MCP_ADMISSION_ACTOR_CAPACITY"), expected[0])
            self.assertEqual(_env(manifest, "MCP_ADMISSION_PROCESS_CAPACITY"), expected[1])

        expected_environment = {
            "MCP_ADMISSION_CONTROL_ENABLED": "true",
            "MCP_TOOL_TIMEOUT_SECONDS": "30",
            "MCP_WANDB_REQUEST_TIMEOUT_SECONDS": "20",
            "UVICORN_WORKERS": "1",
            "WANDB_MCP_ENABLE_RAW_GRAPHQL": "false",
        }
        for name, value in expected_environment.items():
            self.assertEqual(_env(manifest, name), value)
        self.assertRegex(manifest, r"(?m)^spec:\n  replicas: 1$")
        self.assertNotIn("GORILLA_MCP_", manifest)

    def test_mcp_environment_is_least_privilege_and_health_path_is_valid(self) -> None:
        values = _values(**{"global.api.enabled": True})
        deployment = self.assert_success(_render(values=values))
        for forbidden in (
            "GLOBAL_ADMIN_API_KEY",
            "GORILLA_INSECURE_ALLOW_API_KEY_ADMIN_ACCESS",
            "GORILLA_STATSIG_KEY",
        ):
            self.assertNotRegex(deployment, rf"(?m)^\s*- name: {forbidden}$")

        manifest = self.assert_success(
            _render(
                values=values,
                mcp_only=False,
            )
        )
        self.assertIn("http://routing-test-mcp-server:8080/mcp/health", manifest)
        self.assertNotIn("http://routing-test-mcp-server:8080/health", manifest)


if __name__ == "__main__":
    unittest.main(verbosity=2)
