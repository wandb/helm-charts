# MCP Server Deployment and Release Handoff

The W&B MCP Server is an optional component of `operator-wandb`. Enable it only
after the MCP image and chart combination has passed the public release checks
and a Dedicated staging installation has exercised that exact image digest.

This guide covers the chart boundary. Source qualification, image publication,
and the public release evidence are owned by the
[W&B MCP Server release](https://github.com/wandb/wandb-mcp-server/releases)
that supplies the image.

## Configure the Deployment

Pin the MCP image by digest. Keep the release tag as metadata; when `digest` is
set, `wandb-base` renders the container as `repository@digest`.

```yaml
mcp-server:
  install: true
  image:
    repository: wandb/mcp-server
    tag: "<version>"
    digest: "sha256:<verified-digest>"
```

Do not use `latest` or republish a release tag to point at another image. Record
the digest in the release handoff and verify it again after every registry copy.

The chart deliberately uses conservative Dedicated defaults:

| Setting | Default | Reason |
| --- | --- | --- |
| `WANDB_MCP_READ_ONLY` | `false` | Preserve the reviewed MCP write tools. |
| `WANDB_MCP_ENABLE_RAW_GRAPHQL` | `false` | Exclude caller-supplied GraphQL. |
| `WANDB_MCP_ENABLE_WEAVE_AGENT_TOOLS` | `false` | Keep hosted Agent functionality out of Dedicated. |
| `WANDB_MCP_ENABLE_ARIA_TOOLS` | `false` | Require an explicit, separately validated ARIA opt-in. |
| `mcp-server.weave.tools` | `auto` | Expose classic Weave tools only when a trace backend exists. |
| `MCP_RATE_LIMIT_ENABLED` | `true` | Bound request volume per key and process. |
| `MCP_ADMISSION_CONTROL_ENABLED` | `true` | Bound concurrent MCP work. |
| replicas/workers | one/one | Keep the process-local admission budget deterministic. |

The chart rejects raw GraphQL and Weave Agent enablement for Dedicated. ARIA can
be enabled only through `mcp-server.env` with an explicitly approved HTTPS
`WB_AGENT_BASE_URL`. See the comments and validation rules in
[`values.yaml`](../values.yaml) before using that opt-in.

## Keep W&B API Traffic Inside the Cluster

`WANDB_BASE_URL` is chart-managed from `global.host`. It remains the public URL
used for user-visible links and client-facing behavior.

The chart separately sets `WANDB_INTERNAL_BASE_URL` for server-side W&B API
traffic:

| Topology | Generated internal URL |
| --- | --- |
| Split API (`global.api.enabled=true`) | `http://<release>-api:8081` |
| Monolith | `http://<release>-app:8080` |

Namespace-local service discovery keeps MCP requests on the cluster network.
The chart fails rendering instead of guessing when the selected Service is
disabled or when its name or port is customized. For an external or otherwise
nonstandard topology, supply the actual in-cluster endpoint explicitly:

```yaml
mcp-server:
  install: true
  env:
    WANDB_INTERNAL_BASE_URL: "http://wandb-api.internal:8081"
```

Do not replace `global.host` with the internal endpoint. That would leak an
internal address into links returned to users.

Before installation, render the exact values and inspect the MCP image and
routing variables:

```bash
helm dependency build charts/operator-wandb
helm lint charts/operator-wandb --values mcp-values.yaml
helm template <release> charts/operator-wandb \
  --values mcp-values.yaml \
  --set-string license=render-only-placeholder > /tmp/operator-wandb.yaml

yq 'select(.kind == "Deployment")
  | select(.metadata.labels."app.kubernetes.io/name" == "mcp-server")
  | .spec.template.spec.containers[]
  | select(.name == "mcp-server")
  | {"image": .image, "env": .env}' /tmp/operator-wandb.yaml
```

The rendered image must use the approved digest. `WANDB_BASE_URL` must be
public, while `WANDB_INTERNAL_BASE_URL` must match the installed API topology.
Rendered manifests must not contain an administrative W&B API key or Gorilla
server-only settings in the MCP container.

## Validate Install and Upgrade

Use a non-customer Dedicated staging installation first. Preserve the current
Helm revision, values, chart version, and running MCP image digest as rollback
evidence.

1. Run chart dependency build, lint, unit tests, schema/render tests, and the
   repository Kubernetes-version matrix on the exact chart commit.
2. Install or upgrade with the reviewed values and wait for the rollout:

   ```bash
   helm upgrade --install <release> charts/operator-wandb \
     --namespace <namespace> \
     --values deployment-values.yaml \
     --atomic --wait

   kubectl --namespace <namespace> rollout status deployment \
     --selector app.kubernetes.io/name=mcp-server
   ```

3. Verify the running image ID resolves to the approved digest:

   ```bash
   kubectl --namespace <namespace> get pods \
     --selector app.kubernetes.io/name=mcp-server \
     --output jsonpath='{range .items[*]}{.metadata.name}{"\t"}{range .status.containerStatuses[*]}{.name}{"="}{.imageID}{"\n"}{end}{end}'
   ```

4. Confirm readiness, authentication rejection, supported MCP initialization,
   the exact expected tool manifest, and representative authenticated reads.
   Exercise write tools only in a dedicated fixture and delete their output.
5. Verify both active and exported run-history reads, including metrics logged
   at different cadences and ranged requests.
6. Confirm W&B API calls reach the internal ClusterIP Service and do not reach
   the public load balancer. Confirm returned links still use `global.host`.
7. Inspect responses, logs, and telemetry for credentials and internal service
   names. Any leak or unexpected 5xx response blocks the release.

Do not infer MCP correctness from a successful Kubernetes rollout alone. Attach
the protocol, functional, network-routing, and privacy evidence to the release
handoff.

## Roll Back

Roll back by Helm revision or by applying the previously recorded immutable
image digest. Never move a release tag to an older image.

```bash
helm history <release> --namespace <namespace>
helm rollback <release> <previous-revision> \
  --namespace <namespace> \
  --wait
```

After rollback, verify the complete prior values, running image ID, rollout
health, authentication, MCP initialization, representative reads, and internal
routing. A successful `helm rollback` command is not sufficient evidence by
itself.

## Release Handoff

The chart PR should link one sanitized handoff containing:

- Public MCP GitHub Release and signed source tag.
- Public source commit and immutable image digest.
- Chart commit and chart version.
- Render, lint, unit, schema, snapshot, and Kubernetes-matrix results.
- Dedicated install, upgrade, functional, routing, privacy, and rollback
  results for that exact digest.
- Expected feature profile and exact observed tool manifest.
- Known limitations and the previous chart revision/digest used for rollback.

Keep credentials, customer names, resource identifiers, private service URLs,
and raw request or response bodies out of the handoff. Merge or publish the
chart only after the Dedicated evidence is complete and the independently
published image digest matches the reviewed value.
