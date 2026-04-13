# Staff Engineer Update: helm-charts (MCP Server Subchart)

**Date:** March 27, 2026 | **Author:** Anish Shah | **Status:** Pre-release chart published, awaiting QA validation

## Summary

PR #571 adds the W&B MCP Server as an optional subchart of `operator-wandb` for dedicated and on-prem deployments. The chart follows the same `wandb-base` alias pattern used by `weave-trace`, `console`, and other services. A pre-release chart version (`0.42.0-PR571-c86689bf`) has been published to `charts.wandb.ai` and is ready for single-namespace QA testing. All 7 CI failures on the PR are pre-existing and affect other unrelated PRs identically.

## Cross-Repo Context

This repo is the final step before customer clusters. It consumes artifacts from two upstream repos:

- **wandb-mcp-server-test** (upstream) -- publishes `wandb/mcp-server:<tag>` to Docker Hub, which this chart references in `values.yaml` as the default image
- **wandb-mcp-server** (source) -- the Python code that runs inside the container

The W&B **operator** watches `WeightsAndBiases` Custom Resources in each cluster. The `spec.chart.version` field determines which chart version to deploy, and `spec.values` passes configuration like `mcp-server.install: true`.

---

## PR

| PR | Title | State | Diff | Reviewers |
|----|-------|-------|------|-----------|
| [#571](https://github.com/wandb/helm-charts/pull/571) | feat(MCP-32): Add MCP Server subchart for dedicated deployments | OPEN | +7917/-38 | danielpanzella (Commented), coderabbitai (Commented) |

---

## What It Adds

| Aspect | Detail |
|--------|--------|
| Enable | `mcp-server.install: true` (off by default) |
| Image | `wandb/mcp-server:0.2.0` (chart default; will bump to `0.3.0` post-promotion) |
| Resources | 500m CPU / 1Gi RAM request; 2 CPU / 4Gi RAM limit |
| Ingress | `/mcp` path on nginx, proxied to `mcp-server:8080` |
| Auth | Bearer `<wandb-api-key>` (same as hosted); future OAuth 2.1 via `MCP_AUTH_MODE` env var |
| Dependency | Requires `weave-trace.install: true` for auto-wiring `WF_TRACE_SERVER_URL`, OR manual URL override |
| Observability | Datadog + OTEL scaffolding (disabled by default; requires image >= 0.3.0) |
| Helm test | `test-mcp.yaml` -- busybox wget to `/health` |
| Fail-fast | `_mcp.tpl` blocks install if weave-trace is not installed and no `WF_TRACE_SERVER_URL` is provided |
| Rate limiting | 60/min per key, 1000/min global (configured via env vars) |

Customer enablement: a customer only needs to add `mcp-server.install: true` to their values. The MCP server becomes accessible at `https://<wandb-instance>/mcp`.

---

## Pre-Release Chart

The branch was rebased on `origin/main`, resolving 3 merge conflicts:
- `Chart.yaml` version (`0.41.2` branch vs `0.41.3` main -> bumped to `0.42.0`)
- 2 snapshot files (regenerated via `./snapshots.sh`)

All 34 snapshot tests pass locally.

The `pr-release.yaml` CI workflow produced: **`operator-wandb-0.42.0-PR571-c86689bf`** on `charts.wandb.ai`.

---

## QA Deployment

The `WeightsAndBiases` CR is namespaced (`scope: Namespaced` in the CRD). Applying the override below targets **only** the chosen QA namespace. No other environment is affected.

```yaml
apiVersion: apps.wandb.com/v1
kind: WeightsAndBiases
metadata:
  name: wandb
spec:
  chart:
    url: https://charts.wandb.ai
    name: operator-wandb
    version: "0.42.0-PR571-c86689bf"
  values:
    mcp-server:
      install: true
    weave-trace:
      install: true
```

After applying, verify with:

```bash
kubectl get pods -l app.kubernetes.io/name=mcp-server
curl -s https://<QA_HOST>/mcp/health
```

---

## CI Status

7 failures on PR #571. **None are caused by our changes.**

| Failed Job | Cause | Pre-existing? |
|------------|-------|---------------|
| fmb (v1.30.10, v1.31.6, v1.32.2) | Keycloak startup probe timeout | Yes -- fails on PRs #577, #578, #579 |
| runs-v2-bufstream (v1.30.10, v1.31.6, v1.32.2) | etcd/bufstream readiness timeout | Yes -- same PRs |
| Snapshot testing | Helm version mismatch CI vs local | Yes -- also fails on unrelated PR #579 |

All MCP-specific test configs (`mcp-server.yaml`, `mcp-server.snap`) pass in the test matrix.

---

## Connection to Validated Server Branch

This helm chart is now backed by a staging-deployed and eval-validated server branch:

- **Staging revision**: `wandb-mcp-server-staging-00024-4fs` (from `feat/api-efficiency-audit`, commit `c298021`)
- **Staging results**: 8 tools registered, 0 errors in GCP logs, 100% tool success rate
- **WBAF eval results**: 7/7 mcp-ci (mean 0.978), 6/6 mcp-v030-specific (mean 0.965)
- **Weave traces**: [a-sh0ts/mcp-api-efficiency-audit](https://wandb.ai/a-sh0ts/mcp-api-efficiency-audit/weave)

The helm chart will route traffic to this same server code once the Docker image is published and deployed via the operator.

---

## Next Steps

1. **QA cluster access**: Apply the CR above to a single QA namespace
2. **Verify** `/mcp` ingress returns healthy and tools are callable via Bearer auth
3. After v0.3.0 image is published: **update** `values.yaml` default tag from `"0.2.0"` to `"0.3.0"`, regenerate snapshots
4. **Merge PR #571** to main (triggers `release.yaml` -> final `operator-wandb-0.42.0` without PR suffix)
5. Remove the QA pre-release chart version pin (or let it float to the released version)
