# W&B Operator Helm Chart

This chart provides a comprehensive deployment solution for Weights & Biases (W&B) on Kubernetes. It contains all the required components to get started and can scale to large deployments.

> **IMPORTANT**: The default Helm chart configuration is not intended for production. The default chart creates a proof of concept (PoC) implementation where all Weights & Biases services are deployed in the cluster. For production deployments, all stateful components (MySQL, Redis, Kafka) should be deployed outside the Kubernetes cluster.

For a production deployment, you should have strong working knowledge of Kubernetes. This method of deployment has different management and concepts than traditional deployments.

## Chart Architecture

The W&B Operator Helm chart is made up of multiple subcharts and components, each of which can be installed separately based on your configuration:

### Core Components
- **API**: The W&B API service that handles requests from clients
- **App**: The main W&B application
- **Console**: The W&B console interface
- **Frontend**: The W&B web interface
- **Executor**: Handles execution of background tasks
- **Filestream**: Manages file streaming operations
- **Parquet**: Handles Parquet file format operations
- **Weave**: Provides weave functionality for W&B
- **Glue**: Connects various W&B components together

### Data Storage
- **MySQL**: Database for storing metadata (can be deployed in-cluster or external)
- **Redis**: Cache and message broker (can be deployed in-cluster or external)
- **ClickHouse**: Column-oriented database for analytics (can be deployed in-cluster or external)
- **Kafka**: Message queue for event streaming (can be deployed in-cluster or external)
- **etcd**: Distributed key-value store (used by bufstream)


## Prerequisites

### Kubectl

Install kubectl by following the [Kubernetes documentation](https://kubernetes.io/docs/tasks/tools/). The version you install must be within one minor release of the version running in your cluster.

### Helm

Install Helm v3.5.2 or later by following the [Helm documentation](https://helm.sh/docs/intro/install/).

### Storage Requirements

The chart requires persistent storage for various components. By default, it uses the default storage class in your cluster, but you can specify a different storage class using the `global.storageClass` parameter.

### Database Requirements

#### MySQL

By default, the W&B Server chart includes an in-cluster MySQL deployment that is provided by bitnami/MySQL. This deployment is for trial purposes only and not recommended for use in production.

For production deployments, you should use an external MySQL database. You can configure the chart to use an external MySQL database by setting the appropriate parameters in the `global.mysql` section.

#### Redis

By default, the W&B Server chart includes an in-cluster Redis deployment that is provided by bitnami/Redis. This deployment is for trial purposes only and not recommended for use in production.

For production deployments, you should use an external Redis instance. You can configure the chart to use an external Redis instance by setting the appropriate parameters.

The `external` field should always remain `false`. It is for W&B internal use only.

#### ClickHouse

For analytics functionality, the chart can deploy ClickHouse or use an external ClickHouse instance. For production deployments, an external ClickHouse instance is recommended.

#### Kafka

For event streaming, the chart can deploy Kafka or use an external Kafka cluster. For production deployments, an external Kafka cluster is recommended.

## Configuration

Due to the scope and complexity of this chart, all possible values are not documented in this README. Extensive documentation is available in the values.yaml file.

Because properties are regularly added, updated, or relocated, it is _strongly suggested_ to not "copy and paste" the entire values.yaml file. Please provide Helm only those properties you need, and allow the defaults to be provided by the version of this chart at the time of deployment.

### Global Configuration

The chart provides global configuration options that affect multiple components:

```yaml
global:
  # This should be the fqdn of where your users will be accessing the instance
  host: "http://localhost:8080"
  
  # License information
  license: ""
  licenseSecret:
    name: ""
    key: ""
  
  # Cloud provider (aws, gcp, azure)
  cloudProvider: ""
  
  # Storage class for persistent volumes
  storageClass: ""
  
  # Deployment size (small, medium, large)
  size: "small"
  
  # Global nodeSelector and tolerations applied to all deployments/pods
  nodeSelector: {}
  tolerations: []
  
  # Global priority class applied to all deployments/pods
  priorityClassName: ""
```

### Azure managed storage workload identity

Before setting `global.azureStorageIdentity`, deploy a server build containing
[instance-level Azure identity support and blob-scoped SAS signing](https://github.com/wandb/core/pull/48160).
Check the images running in every storage-consuming workload, including component
image overrides. A chart upgrade or a projected Azure token does not make an older
server use workload identity; it can still sign requests with an empty account key
after the chart removes `AZURE_STORAGE_KEY`.

Provision the instance managed identity, storage permissions, and federated
credentials through Terraform before enabling the chart setting. For an initial
rollout, set `global.azureStorageIdentity.serviceAccount.mode: component` to keep
the existing Kubernetes service accounts. Consolidation with `grouped` is a separate
migration.

Set `global.defaultBucket.azureAuthMethod: workloadIdentity` to select the
deployment identity for the managed bucket. Set it to `accessKey` to use the
storage key while keeping the identity available. When omitted, the chart retains
the previous behavior: a configured global or legacy default-bucket identity
selects workload identity; otherwise it uses the key. A named `global.bucket`
overrides the complete default bucket configuration, including authentication;
its own `azureAuthMethod` selects the method independently.

Inventory optional storage consumers and workloads left over from older chart
releases. If parquet uses the metadata cache, keep
`parquet-metadata-cache.install: true` and configure its service account for Azure
identity too. It can reuse the parquet account when their permissions match.
Check that every replacement pod is ready and every old replica has terminated;
an available old pod can hide a replacement that is failing to start.

Retain the storage key securely during validation so selecting `accessKey` and
supplying the key restores key authentication. Verify actual run-file and artifact uploads
and downloads, and check that server-issued SAS URLs use the intended managed
identity with blob scope (`sr=b`). Pod readiness alone does not validate storage
authentication.

### Global Pod Scheduling

The chart supports global `nodeSelector`, `tolerations`, and `priorityClassName` configuration that applies to **ALL components** (W&B services, databases, monitoring, etc.). This provides centralized control over pod scheduling and priority across your entire W&B deployment.

#### Fallback Configuration Logic:

The scheduling configuration uses **fallback behavior** (not cumulative):

1. **First, check if component-specific config exists** → use that configuration
2. **If not, check if chart-level config exists** → use that configuration  
3. **If neither exists, check if global config exists** → use that configuration
4. **If none exist** → no scheduling constraints are applied

**Important**: Configurations are **NOT merged** - only the highest priority non-empty configuration is used.

#### Universal Scheduling (Recommended for Production Deployments)

Use `global.nodeSelector`, `global.tolerations`, and `global.priorityClassName` for scheduling constraints that should apply to **everything**:

```yaml
# Global fallback - used when components don't have their own config
global:
  nodeSelector:
    environment: production
  tolerations:
  - effect: NoSchedule
    key: dedicated
    operator: Equal
    value: production
  priorityClassName: "wandb-high-priority"
```

#### Component-Specific Overrides

For component-specific scheduling requirements:

```yaml
# Global fallback - used when components don't have their own config
global:
  nodeSelector:
    environment: production
  tolerations:
  - effect: NoSchedule
    key: dedicated
    operator: Equal
    value: production
  priorityClassName: "wandb-high-priority"

# Component-specific config - completely replaces global config for this component
console:
  nodeSelector:
    node-type: management
    # This completely replaces global.nodeSelector for console
  tolerations:
  - effect: NoSchedule
    key: management-only
    operator: Equal
    value: "true"
    # This completely replaces global.tolerations for console
  priorityClassName: "wandb-management-priority"
    # This completely replaces global.priorityClassName for console

# Redis-specific scheduling (for third-party charts)
redis:
  master:
    nodeSelector:
      node-type: database
    tolerations:
    - effect: NoSchedule
      key: database
      operator: Equal
      value: "true"
```

**Result**: 
- Console uses its own scheduling config: `node-type: management` with management-only tolerations and `wandb-management-priority` priority class
- Redis master uses its own scheduling config: `node-type: database`  
- All other W&B components use the global production scheduling fallback including the `wandb-high-priority` priority class
- No configuration merging occurs - each component uses only its most specific available config

### Component-Specific Configuration

Each component can be configured independently. For example, to configure the API component:

```yaml
api:
  enabled: true
  replicaCount: 2
  resources:
    requests:
      cpu: 100m
      memory: 256Mi
    limits:
      cpu: 1000m
      memory: 1Gi
```

### MCP Server

The MCP Server is disabled by default for direct Helm and Self-Managed installs.
Its supported configuration is intentionally small: Helm selects a named server
profile and keeps deployment concerns such as routing and resources separate.

```yaml
mcp-server:
  install: true
  image:
    repository: wandb/mcp-server
    tag: "0.4.0"
    # For an immutable release, set this to sha256: followed by 64 lowercase
    # hexadecimal characters.
    digest: ""
  tools:
    profile: auto # auto | models-only | models-weave
  accessMode: read-write # read-write | read-only
  traceBackend:
    mode: auto # auto | disabled
    url: "" # optional external HTTP(S) origin or /traces URL
  routing:
    internalBaseUrl: "" # derived from the split API or monolith Service
  observability:
    provider: none # none | datadog-agent | otel
    privacy: standard # off | standard | strict
  resources: {}
```

`tools.profile=auto` resolves during chart rendering to `models-only` when no
trace backend is available and `models-weave` otherwise. The pod always receives
the resolved profile, never `auto`. In v0.4 these correspond to exact 17/22
read-write tool manifests (15/20 in read-only mode). Agent, ARIA, and raw GraphQL
profiles cannot be enabled through this chart.

For the v0.4 transition, the existing Managed Spec
`datadog.enabled/mode/env/service/deploymentType` and `privacy.logLevel` fields
remain as a narrow, validated compatibility bridge. They cannot enable direct
forwarding, inject credentials, or override a conflicting non-default typed
provider. New configurations should use `observability` only.

The server-owned `dedicated` workload profile controls limits, admission,
deadlines, sessions, and worker policy. Low-level environment overrides and
opaque `envFrom` sources are rejected. MCP uses the internal ClusterIP for W&B
API calls while `global.host` remains the public URL for user-facing links. It
runs as one steady-state pod without HPA/VPA/KEDA, Kubernetes RBAC, or a mounted
service-account token. Rolling updates retain `maxSurge: 1` for availability,
so two independent process budgets can briefly overlap. Liveness uses
`/mcp/livez`; readiness and the Helm health hook use `/mcp/health` so saturation
does not restart a healthy process. Component-specific `nodeSelector`, `tolerations`, `affinity`, and
`topologySpreadConstraints` remain supported scheduling controls.

Capacity follows `global.size`: `default`, `testing`, and `small` select `small`;
`medium` selects `medium`; `large`, `xlarge`, and `xxlarge` select `large`.
These select server concurrency budgets, not CPU or memory requests. Resource
settings remain explicit deployment controls; changing capacity does not resize
the pod. The numeric defaults stay unchanged pending the release benchmarks.

MCP uses its own ServiceAccount and disables automatic token mounting on both
the account and Pod. Shared Weave/Azure identity selectors are rejected. Generic
environment extensions must have literal names and cannot override the typed
contract or SDK privacy flags, including through container templates. Final
rendered environment entries must be unique. The inherited CA certificate
mounts remain available for private upstream certificates.

Ingress and the health hook follow the actual MCP Service name, including
component name overrides. `mcp-server.service.ports` must contain exactly one
named `http` TCP port from 1 to 65535 with `targetPort: 8080`. For example, a
Service port of 9090 is supported while application and probe ports remain 8080.

## Use External Stateful Data

You can configure the W&B Server Helm chart to point to external stateful storage for items like MySQL, Redis, and Storage.

The following Terraform (IaC) options use this approach:

- [AWS](https://github.com/wandb/terraform-aws-wandb)
- [Google](https://github.com/wandb/terraform-google-wandb)
- [Azure](https://github.com/wandb/terraform-azurerm-wandb)

For production-grade implementation, the appropriate chart parameters should be used to point to prebuilt, externalized state stores.

## Customer-owned OIDC configuration

OIDC follows the same resource/reference pattern as the license. By default,
Helm creates `<release>-oidc-configmap` from `global.auth.oidc.clientId`, `issuer`,
`authMethod`, and the existing CORS inputs. App and API consume it through a
shared reference helper; the API and local ConfigMaps contain no OIDC settings.

To select an external ConfigMap instead, set `global.auth.oidc.oidcConfigMap.name`.
The same helper selects its name, and Helm stops creating the
chart-managed OIDC ConfigMap:

```yaml
global:
  auth:
    oidc:
      oidcConfigMap:
        name: customer-oidc
      oidcSecret:
        name: customer-oidc-secret
        secretKey: OIDC_SECRET
```

Provision the ConfigMap and, if needed, the client Secret in the release
namespace **before** enabling this mode. The chart references these resources
from the app and standalone API; it does not create or update their data.

The chart-generated ConfigMap has the same Helm `keep` policy as the license,
allowing a Helm upgrade to retain it when its name becomes an external
reference. This retention policy does not configure Argo ownership or pruning.

The ConfigMap must contain all four fixed keys below. Only their values vary
between deployments.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: customer-oidc
data:
  OIDC_CLIENT_ID: "existing-client-id"
  OIDC_ISSUER: "https://idp.example.com"
  OIDC_AUTH_METHOD: "pkce"
  GORILLA_CORS_ORIGINS: "https://extra.example.com,https://wandb.example.com,null"
```

`GORILLA_CORS_ORIGINS` is the complete comma-separated list. Preserve existing
`app.extraCors` entries and, while OIDC is enabled, append `global.host` and
the literal `null` origin to match the inline chart behavior. In external mode,
Helm no longer computes this list or renders inline OIDC settings. In inline
mode, extra CORS origins still work with OIDC disabled; when neither is set,
the CORS key is absent and its reference is optional, preserving application
defaults. External references are always required.

Leftover inline values are ignored in external mode; migrate explicit app/API environment overrides
for these variables as well, since explicit environment overrides still win.

Use the existing `oidcSecret` reference for credentials. If the provider does
not require a client secret, leave both `oidcSecret.name` and `oidc.secret`
empty. External configuration cannot be combined with a chart-generated inline
client secret: supply an external Secret reference or remove the unused secret.

For migration:

1. Copy the current effective OIDC settings, CORS origins, and credentials into
   the external resources. Resolve any Terraform or explicit environment
   overrides before enabling customer editing.
2. Enable the references and verify login before removing the migrated settings
   from the user spec. Keep the original values available for rollback.
3. The external owner (for example, Console) updates the ConfigMap/Secret and
   restarts the consuming app/API workloads. Environment references are read
   when a container starts; changing data alone does not restart it.

To disable OIDC while keeping external ownership, retain every ConfigMap key
and clear the client ID, issuer, and auth method. Set the CORS list to the
remaining non-OIDC origins (or an empty string). If a Secret is referenced,
retain it and its configured key, clearing its value when no longer needed.
Missing referenced resources or keys prevent containers from starting.

These external resources must remain outside Helm/Argo ownership of their
mutable data. Switching this chart mode on does not migrate user specs,
implement Console editing, or install restart automation.

## Using External Secrets

The chart supports referencing existing Kubernetes Secrets for sensitive credentials. This allows you to manage secrets externally using tools like External Secrets Operator, Sealed Secrets, or other secret management systems.

### Supported Secret References

The following credentials can be pulled from external Kubernetes Secrets:

| Component | Configuration Path | Secret Fields |
|-----------|-------------------|---------------|
| Component | Configuration Path | Secret Reference Method |
|-----------|-------------------|------------------------|
| **MySQL** | `global.mysql.*` | Each field (host, port, database, user, password) can be a string or a map with `valueFrom` |
| **Redis** | `global.redis.secret` | `secretName`, `secretKey` |
| **Weave Trace ClickHouse** | `global.clickhouse.*` or an enabled `global.olap.weaveTrace.*` profile | `global.weaveTrace.clickhouseSource` defaults to `auto`; each connection field can be a string or a map with `valueFrom` |
| **Kafka** | `global.kafka.passwordSecret` | `name`, `passwordKey` |
| **OIDC** | `global.auth.oidc.oidcSecret` | `name`, `secretKey` |
| **Session signing** | `global.auth.sessionKey`, `global.auth.sessionKeyPrevious` | Literal value or a map with `valueFrom` |
| **SMTP** | `global.email.smtp.*` | Each field (host, port, user, password) can be a string or a map with `valueFrom` |

`global.weaveTrace.clickhouseSource` defaults to `auto`. Once Weave is installed
and its OLAP connection and credentials are provisioned, setting
`global.olap.weaveTrace.enabled: true` selects that profile automatically if
there is no customized `global.clickhouse` configuration and `clickhouse.install`
is false. The stock chart defaults, including the templated bundled hostname,
do not count as a configured legacy connection. Nonempty custom settings,
including host or credential references, retain the legacy connection.

| Source | Enabled OLAP profile | Customized legacy configuration or bundled ClickHouse | Selected connection |
| --- | --- | --- | --- |
| `auto` (default) | Yes | No | OLAP |
| `auto` (default) | Yes | Yes | Legacy |
| `auto` (default) | No | Either | Legacy |
| `legacy` | Either | Either | Legacy |
| `olap` | Yes | Either | OLAP |
| `olap` | No | Either | Render error |

Set `global.weaveTrace.clickhouseSource: olap` explicitly to cut over an existing
legacy installation. An explicit `legacy` value, including a value retained in
an older release or user spec, prevents automatic selection. Unknown source
values fail rendering. These settings select a connection; they do not install
Weave, create database users, or provision Secrets. Configure the Weave-specific
credential references in the OLAP profile before enabling it; missing fields
still inherit from `global.olap.default`.

For a separate migration identity, enable
`global.olap.weaveTrace.migrator` and provide its user and password through
Kubernetes `valueFrom` references. Only the `weave-trace-migrate` init
container receives those credentials. Runtime Weave containers continue to
use `global.olap.weaveTrace.user` and `global.olap.weaveTrace.password`.
During A/B rotation, update the runtime and migrator password references to
the matching slot in the same rollout.

### Example: Using External Secrets with MySQL/ClickHouse/SMTP

For MySQL, ClickHouse, and SMTP, each field can be configured as either a simple value or a Kubernetes secret reference:

```yaml
global:
  email:
    smtp:
      host: "smtp.example.com"
      port: 587
      user: "noreply@example.com"
      password:
        valueFrom:
          secretKeyRef:
            name: "my-smtp-secret"
            key: "password"
  
  mysql:
    host: "mysql.example.com"
    port: 3306
    database: "wandb_local"
    user:
      valueFrom:
        secretKeyRef:
          name: "my-mysql-secret"
          key: "username"
    password:
      valueFrom:
        secretKeyRef:
          name: "my-mysql-secret"
          key: "password"
```

For complete examples with secrets and additional configurations, see:
- Values: [test-configs/operator-wandb/user-defined-secrets.yaml](../../test-configs/operator-wandb/user-defined-secrets.yaml)
- Secrets: [test-configs/additional-resources/user-defined-secrets/](../../test-configs/additional-resources/user-defined-secrets/)

### Session Key Rotation

The chart generates `GORILLA_SESSION_KEY` on first install and retains it in the
release's `gorilla-session-key` Secret. It can rotate that managed key without
invalidating active sessions by using a three-phase workflow, or perform an
explicit emergency hard cutover. External Secret users can force the required
API and app rollouts with `global.auth.sessionKeyRolloutId`.

See [Session Key Rotation](docs/session-key-rotation.md) for the managed
workflow and external Secret examples.

## Chart Relationship

The operator-wandb chart uses the wandb-base chart as a building block for deploying various W&B services. The wandb-base chart provides a consistent deployment pattern for different services, while allowing for service-specific configuration.

## Examples

### Minimal Installation

```bash
helm install wandb ./charts/operator-wandb \
  --set global.host=https://wandb.example.com \
  --set global.license=your-license-key
```

### Production Installation with External Services

```bash
helm install wandb ./charts/operator-wandb \
  --set global.host=https://wandb.example.com \
  --set global.license=your-license-key \
  --set global.mysql.host=mysql.example.com \
  --set global.mysql.user=wandb \
  --set global.mysql.passwordSecret.name=mysql-secret \
  --set redis.install=false \
  --set global.redis.host=redis.example.com
```

## Additional Resources

For more detailed information and advanced configuration options, please refer to the [W&B documentation](https://docs.wandb.ai/).
