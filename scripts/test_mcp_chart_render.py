#!/usr/bin/env python3
"""Focused render tests for operator-wandb's MCP deployment contract."""

from __future__ import annotations

import re
import subprocess
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
CHART = REPO_ROOT / "charts" / "operator-wandb"
MCP_DEPLOYMENT_TEMPLATE = "charts/mcp-server/templates/deployment.yaml"
PUBLIC_BASE_URL = "https://customer.wandb.io"


def _helm_template(
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
        if isinstance(value, (bool, int)):
            command.extend(("--set", f"{name}={str(value).lower()}"))
        else:
            command.extend(("--set-string", f"{name}={value}"))
    if mcp_only:
        command.extend(("--show-only", MCP_DEPLOYMENT_TEMPLATE))
    return subprocess.run(
        command,
        cwd=REPO_ROOT,
        check=False,
        capture_output=True,
        text=True,
    )


def _mcp_values(**overrides: str | bool | int) -> dict[str, str | bool | int]:
    values: dict[str, str | bool | int] = {
        "mcp-server.install": True,
        "global.host": PUBLIC_BASE_URL,
    }
    values.update(overrides)
    return values


def _env_value(manifest: str, name: str) -> str:
    match = re.search(
        rf"(?m)^\s*- name:\s*{re.escape(name)}\s*$\n^\s+value:\s*(.+?)\s*$",
        manifest,
    )
    if match is None:
        raise AssertionError(f"missing {name} in rendered MCP environment")
    return match.group(1).strip().strip('"\'')


def _has_resource(manifest: str, kind: str, name: str) -> bool:
    return any(
        re.search(rf"(?m)^kind:\s*{re.escape(kind)}\s*$", document)
        and re.search(rf"(?m)^  name:\s*{re.escape(name)}\s*$", document)
        for document in manifest.split("\n---")
    )


class McpChartRenderTest(unittest.TestCase):
    maxDiff = None

    def assert_render_succeeds(
        self, result: subprocess.CompletedProcess[str]
    ) -> str:
        self.assertEqual(result.returncode, 0, result.stderr)
        return result.stdout

    def test_split_api_uses_namespace_local_api_service(self) -> None:
        manifest = self.assert_render_succeeds(
            _helm_template(
                release="customer-a",
                namespace="dedicated-prod",
                values=_mcp_values(**{"global.api.enabled": True}),
            )
        )

        self.assertEqual(_env_value(manifest, "WANDB_BASE_URL"), PUBLIC_BASE_URL)
        self.assertEqual(
            _env_value(manifest, "WANDB_INTERNAL_BASE_URL"),
            "http://customer-a-api:8081",
        )
        # The short Service name is intentionally namespace-local. Rendering in
        # a non-default namespace must not bake a namespace into the URL.
        self.assertNotIn(
            "dedicated-prod", _env_value(manifest, "WANDB_INTERNAL_BASE_URL")
        )
        complete_manifest = self.assert_render_succeeds(
            _helm_template(
                release="customer-a",
                namespace="dedicated-prod",
                values=_mcp_values(**{"global.api.enabled": True}),
                mcp_only=False,
            )
        )
        self.assertTrue(
            _has_resource(complete_manifest, "Service", "customer-a-api")
        )

    def test_monolith_uses_namespace_local_app_service(self) -> None:
        manifest = self.assert_render_succeeds(
            _helm_template(
                release="customer-b",
                namespace="self-managed",
                values=_mcp_values(**{"global.api.enabled": False}),
            )
        )

        self.assertEqual(_env_value(manifest, "WANDB_BASE_URL"), PUBLIC_BASE_URL)
        self.assertEqual(
            _env_value(manifest, "WANDB_INTERNAL_BASE_URL"),
            "http://customer-b-app:8080",
        )
        complete_manifest = self.assert_render_succeeds(
            _helm_template(
                release="customer-b",
                namespace="self-managed",
                values=_mcp_values(**{"global.api.enabled": False}),
                mcp_only=False,
            )
        )
        self.assertTrue(
            _has_resource(complete_manifest, "Service", "customer-b-app")
        )

    def test_explicit_internal_url_overrides_both_topologies(self) -> None:
        override = "http://external-api.platform.svc.cluster.local:9090"
        for split_api in (False, True):
            with self.subTest(split_api=split_api):
                manifest = self.assert_render_succeeds(
                    _helm_template(
                        values=_mcp_values(
                            **{
                                "global.api.enabled": split_api,
                                "mcp-server.env.WANDB_INTERNAL_BASE_URL": override,
                            }
                        )
                    )
                )
                self.assertEqual(
                    _env_value(manifest, "WANDB_INTERNAL_BASE_URL"), override
                )
                self.assertEqual(manifest.count("name: WANDB_INTERNAL_BASE_URL"), 1)

    def test_custom_backend_service_settings_require_explicit_url(self) -> None:
        cases: tuple[tuple[str, dict[str, str | bool | int], str], ...] = (
            (
                "split service name",
                {
                    "global.api.enabled": True,
                    "api.service.name": "custom-api-service",
                },
                "api naming or the http Service port is overridden",
            ),
            (
                "split name override",
                {
                    "global.api.enabled": True,
                    "api.nameOverride": "custom-api",
                },
                "api naming or the http Service port is overridden",
            ),
            (
                "split fullname override",
                {
                    "global.api.enabled": True,
                    "api.fullnameOverride": "custom-api-fullname",
                },
                "api naming or the http Service port is overridden",
            ),
            (
                "split service port",
                {
                    "global.api.enabled": True,
                    "api.service.ports[0].port": 9081,
                },
                "api naming or the http Service port is overridden",
            ),
            (
                "monolith service name",
                {
                    "global.api.enabled": False,
                    "app.service.name": "custom-app-service",
                },
                "app naming or the app Service port is overridden",
            ),
            (
                "monolith name override",
                {
                    "global.api.enabled": False,
                    "app.nameOverride": "custom-app",
                },
                "app naming or the app Service port is overridden",
            ),
            (
                "monolith fullname override",
                {
                    "global.api.enabled": False,
                    "app.fullnameOverride": "custom-app-fullname",
                },
                "app naming or the app Service port is overridden",
            ),
            (
                "monolith service port",
                {
                    "global.api.enabled": False,
                    "app.service.ports[0].port": 9080,
                },
                "app naming or the app Service port is overridden",
            ),
        )
        explicit_url = "http://custom-backend.platform.svc.cluster.local:9090"
        for label, values, expected_error in cases:
            with self.subTest(label=label, explicit_override=False):
                result = _helm_template(values=_mcp_values(**values))
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(expected_error, result.stderr)

            with self.subTest(label=label, explicit_override=True):
                values_with_override = {
                    **values,
                    "mcp-server.env.WANDB_INTERNAL_BASE_URL": explicit_url,
                }
                manifest = self.assert_render_succeeds(
                    _helm_template(values=_mcp_values(**values_with_override))
                )
                self.assertEqual(
                    _env_value(manifest, "WANDB_INTERNAL_BASE_URL"), explicit_url
                )

    def test_nonstandard_topology_requires_an_explicit_internal_url(self) -> None:
        cases = (
            (
                {
                    "global.api.enabled": True,
                    "api.service.enabled": False,
                },
                "global.api.enabled=true and api.service.enabled=false",
            ),
            (
                {
                    "global.api.enabled": False,
                    "app.service.enabled": False,
                },
                "monolith app Service is disabled",
            ),
            (
                {
                    "global.api.enabled": False,
                    "app.install": False,
                },
                "monolith app Service is disabled",
            ),
        )
        for values, expected_error in cases:
            with self.subTest(values=values):
                result = _helm_template(values=_mcp_values(**values))
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(expected_error, result.stderr)

                values["mcp-server.env.WANDB_INTERNAL_BASE_URL"] = (
                    "http://custom-api:8080"
                )
                self.assert_render_succeeds(
                    _helm_template(values=_mcp_values(**values))
                )

    def test_mcp_validation_is_inert_when_mcp_is_disabled(self) -> None:
        result = _helm_template(
            values={
                "mcp-server.install": False,
                "mcp-server.performance.profile": "invalid",
                "mcp-server.env.MCP_WORKLOAD_PROFILE": "invalid",
                "mcp-server.env.WANDB_INTERNAL_BASE_URL": "",
            },
            mcp_only=False,
        )
        manifest = self.assert_render_succeeds(result)
        self.assertNotIn("/charts/mcp-server/", manifest)

    def test_empty_internal_url_is_rejected_when_mcp_is_enabled(self) -> None:
        result = _helm_template(
            values=_mcp_values(
                **{"mcp-server.env.WANDB_INTERNAL_BASE_URL": ""}
            )
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(
            "mcp-server.env.WANDB_INTERNAL_BASE_URL must be non-empty",
            result.stderr,
        )

    def test_every_size_renders_the_expected_admission_budget(self) -> None:
        expectations = {
            None: ("4", "4"),
            "small": ("4", "4"),
            "medium": ("4", "8"),
            "large": ("8", "16"),
            "xlarge": ("8", "16"),
            "xxlarge": ("8", "16"),
        }
        for size, (actor_capacity, process_capacity) in expectations.items():
            with self.subTest(size=size or "default"):
                values = _mcp_values(**{"global.api.enabled": True})
                if size is not None:
                    values["global.size"] = size
                manifest = self.assert_render_succeeds(
                    _helm_template(values=values)
                )
                self.assertEqual(
                    _env_value(manifest, "MCP_ADMISSION_ACTOR_CAPACITY"),
                    actor_capacity,
                )
                self.assertEqual(
                    _env_value(manifest, "MCP_ADMISSION_PROCESS_CAPACITY"),
                    process_capacity,
                )

    def test_conservative_runtime_defaults_remain_explicit(self) -> None:
        manifest = self.assert_render_succeeds(
            _helm_template(values=_mcp_values(**{"global.api.enabled": True}))
        )
        expected_environment = {
            "MCP_ADMISSION_CONTROL_ENABLED": "true",
            "MCP_TOOL_TIMEOUT_SECONDS": "30",
            "MCP_WANDB_REQUEST_TIMEOUT_SECONDS": "20",
            "UVICORN_WORKERS": "1",
            "WANDB_MCP_ENABLE_RAW_GRAPHQL": "false",
        }
        for name, value in expected_environment.items():
            with self.subTest(name=name):
                self.assertEqual(_env_value(manifest, name), value)
        self.assertRegex(manifest, r"(?m)^spec:\n  replicas: 1$")
        self.assertNotIn("GORILLA_MCP_", manifest)


if __name__ == "__main__":
    unittest.main(verbosity=2)
