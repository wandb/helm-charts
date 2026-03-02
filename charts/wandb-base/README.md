# Weights & Biases Base Helm Chart

This chart provides a base template for creating Weights & Biases Kubernetes resources. It serves as a foundation for other W&B charts and can be used to deploy custom W&B components.

## Overview

The wandb-base chart provides a flexible framework for deploying various Kubernetes resources including:

- Deployments
- StatefulSets
- Jobs
- CronJobs
- Services
- Ingress

The chart is designed to be highly configurable while providing sensible defaults. It supports a wide range of Kubernetes features including pod security contexts, resource management, autoscaling, and more.

## Configuration Precedence

One of the key features of this chart is its hierarchical configuration system. Many values can be set at multiple levels, with a clear precedence order. Understanding this precedence is crucial for effective configuration.

### Environment Variables

Environment variables can be defined at multiple levels, with the following precedence (highest to lowest):

1. Container-specific environment variables (`containers.<container-name>.env`)
2. Sizing-based environment variables (`sizing.<size>.env`)
3. Chart-level environment variables (`env`)
4. Legacy environment variables (`extraEnv`)
5. Global environment variables (`global.env`)
6. Legacy global environment variables (`global.extraEnv`)

Example:

```yaml
# Global environment variables (lowest precedence)
global:
  env:
    LOG_LEVEL: "info"

# Chart-level environment variables
env:
  LOG_LEVEL: "debug"
  MAX_CONNECTIONS: "100"

# Container-specific environment variables (highest precedence)
containers:
  app:
    env:
      LOG_LEVEL: "trace"
```

In this example, the `LOG_LEVEL` for the `app` container would be set to `trace`.

Additionally, environment variables can be sourced from ConfigMaps and Secrets using the `envFrom` field:

```yaml
envFrom:
  app-config: "configMapRef"
  app-secrets: "secretRef"
```

### Volumes

Volumes can be defined at multiple levels and are combined by name. The chart uses the pod- or chart-level volume when a name collides with a global volume.

Global volumes are useful when a parent chart needs to attach shared volumes across multiple subcharts. You can also use templated volumes via `volumesTpls` and `global.volumesTpls`.

Example:

```yaml
global:
  volumes:
    - name: shared-config
      configMap:
        name: shared-config

volumes:
  - name: data
    emptyDir: {}
  - name: shared-config
    configMap:
      name: chart-specific-config
```

In this example, the `shared-config` volume from `volumes` overrides the global definition.

### Pod Resources

Resource requests and limits can be defined at multiple levels, with the following precedence (highest to lowest):

1. Container-specific resources (`containers.<container-name>.resources`)
2. Sizing-based resources (`sizing.<size>.resources`)
3. Chart-level resources (`resources`)

Important notes about resource configuration:

- The configurations are merged, so the actual resulting configuration can be a combination of values set at different levels. For example, if container-specific configuration defines CPU requests but not memory limits, the memory limits might be inherited from sizing-based or chart-level resources.
- In multi-container pods, if no container-level resources are set, all containers in the pod will get the same resource requests and limits (inherited from sizing or chart-level). This is likely not what you want, as different containers often have different resource needs. Always specify container-specific resources for multi-container pods.

Example:

```yaml
# Chart-level resources (lowest precedence)
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 200m
    memory: 256Mi

# Sizing-based resources
sizing:
  production:
    resources:
      requests:
        cpu: 500m
        memory: 512Mi
      limits:
        cpu: 1000m
        memory: 1Gi

# Container-specific resources (highest precedence)
containers:
  app:
    resources:
      requests:
        cpu: 750m
        memory: 768Mi
      # Note: no limits defined at container level
```

In this example, if `size: "production"` is set and we have a partial container-specific configuration, the resulting merged configuration would be:

```yaml
# Resulting merged configuration for the 'app' container
resources:
  requests:
    cpu: 750m        # From container-specific (highest precedence)
    memory: 768Mi    # From container-specific (highest precedence)
  limits:
    cpu: 1000m       # Inherited from sizing-based resources
    memory: 1Gi      # Inherited from sizing-based resources
```

### Security Contexts

Security contexts can be defined at multiple levels:

1. **Pod Security Context**: Applied to all containers in the pod
   - Defined in `podSecurityContext`

2. **Container Security Context**: Applied to specific containers
   - Container-specific: `containers.<container-name>.securityContext` (highest precedence)
   - Default container security context: `securityContext` (lowest precedence)

Example:

```yaml
# Pod-level security context (applies to all containers)
podSecurityContext:
  runAsNonRoot: true
  runAsUser: 999
  fsGroup: 0

# Default container security context
securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true

# Container-specific security context
containers:
  app:
    securityContext:
      readOnlyRootFilesystem: false
```

In this example:
- All containers will run as user 999 (from pod security context)
- The `app` container will have `readOnlyRootFilesystem: false` (overriding the default)
- All other containers will have `readOnlyRootFilesystem: true` (from default security context)

### Container Images

Container images can be defined at multiple levels, with the following precedence (highest to lowest):

1. Container-specific image configuration (`containers.<container-name>.image`)
2. Chart-level image configuration (`image`)

The image configuration at each level includes:
- `repository`: The image repository
- `tag`: The image tag (optional)
- `digest`: The image digest for immutable image references (optional)
- `pullPolicy`: The image pull policy

**Image Reference Precedence:** When both `digest` and `tag` are provided, `digest` takes precedence for enhanced security and immutability. If neither is provided, the image defaults to `:latest`.

When a container doesn't specify its own image configuration, it inherits the chart-level image configuration. This allows you to set a default image for all containers while still being able to override it for specific containers.

Example:

```yaml
# Chart-level image configuration (applies to all containers without specific image settings)
image:
  repository: nginx
  tag: "1.21.6"
  pullPolicy: IfNotPresent

# Container-specific image configurations
containers:
  app:
    # This container uses digest for immutable reference (most secure)
    image:
      repository: myapp
      digest: "sha256:abc123def456..."  # digest takes precedence over tag
      tag: "v1.0.0"                    # ignored when digest is provided
      pullPolicy: Always
  worker:
    # This container uses a specific tag
    image:
      repository: worker
      tag: "v2.1.0"
      pullPolicy: IfNotPresent
  sidecar:
    # This container doesn't specify an image, so it will use the chart-level image
    env:
      SIDECAR_MODE: "true"
  monitor:
    # This container has empty tag/digest, so it defaults to :latest
    image:
      repository: monitor
      # tag: ""    # empty - will default to :latest
      # digest: "" # empty - will default to :latest
```

In this example:
- The `app` container will use the digest `myapp@sha256:abc123def456...` (digest takes precedence)
- The `worker` container will use the tag `worker:v2.1.0`
- The `sidecar` container will use the chart-level image `nginx:1.21.6` with pull policy `IfNotPresent`
- The `monitor` container will default to `monitor:latest` (fallback when both tag and digest are empty)

### Global Common Labels and Annotations

The chart supports a comprehensive labeling and annotation system with `global.common` values that apply to **ALL resources** (deployments, jobs, services, ingress, etc.). This provides a single place to configure labels and annotations for your entire application.

#### Configuration Levels (highest to lowest precedence):

1. **Resource-specific** (`deployment.labels`, `service.annotations`, etc.)
2. **Global resource-specific** (`global.deployment.labels`, `global.service.annotations`, etc.)  
3. **Local common** (`common.labels`, `common.annotations`)
4. **Global common** (`global.common.labels`, `global.common.annotations`)

#### Universal Labels and Annotations (Recommended)

Use `global.common` for labels/annotations that should apply to **everything**:

```yaml
# These labels/annotations will be applied to ALL resources
global:
  common:
    labels:
      environment: "production"
      team: "platform"
      app.kubernetes.io/part-of: "wandb"
    annotations:
      argocd.argoproj.io/managed-by: "argocd"
      prometheus.io/scrape: "true"

# Local common labels for this specific chart instance
common:
  labels:
    chart-instance: "api-server"
  annotations:
    deployed-by: "helm"
```

#### Resource-Specific Overrides

For resource-specific customization:

```yaml
# Global settings for all deployments
global:
  deployment:
    labels:
      workload-type: "deployment"
    annotations:
      deployment.kubernetes.io/strategy: "rolling"

# Local deployment settings for this chart
deployment:
  labels:
    component: "api"
  annotations:
    deployment.kubernetes.io/revision-policy: "manual"

# StatefulSet-specific settings
global:
  statefulset:
    labels:
      persistence: "enabled"
    annotations:
      statefulset.kubernetes.io/pod-management-policy: "parallel"
```

#### Complete Example

```yaml
# Applied to ALL resources (deployments, jobs, services, ingress, etc.)
global:
  common:
    labels:
      app.kubernetes.io/part-of: "wandb-platform"
      environment: "production"
      managed-by: "platform-team"
    annotations:
      monitoring.example.com/scrape: "true"
      argocd.argoproj.io/instance: "wandb-prod"

# Applied to specific resource types
global:
  deployment:
    labels:
      workload-type: "deployment"
    annotations:
      deployment.kubernetes.io/managed-by: "argocd"

# Local chart overrides
deployment:
  labels:
    component: "api-server"
  annotations:
    deployment.kubernetes.io/restart-policy: "always"
```

**Result**: Every resource gets the common labels/annotations, plus any resource-specific ones, with proper precedence handling.

### Global Pod Scheduling

The chart supports global `nodeSelector`, `tolerations`, and `priorityClassName` configuration that applies to **ALL pods** (deployments, jobs, cronjobs, etc.). This provides centralized control over pod scheduling constraints and priority while allowing for component-specific overrides.

#### Fallback Configuration Logic:

The scheduling configuration uses **fallback behavior** (not cumulative):

1. **First, check if pod-specific config exists** → use that configuration
2. **If not, check if chart-level config exists** → use that configuration  
3. **If neither exists, check if global config exists** → use that configuration
4. **If none exist** → no scheduling constraints are applied

**Important**: Configurations are **NOT merged** - only the highest priority non-empty configuration is used.

#### Universal Scheduling (Recommended for Production/Dedicated Nodes)

Use `global.nodeSelector`, `global.tolerations`, and `global.priorityClassName` for scheduling constraints that should apply to **all pods**:

```yaml
# Global configuration - applies to all pods that don't have more specific config
global:
  nodeSelector:
    environment: production
  tolerations:
  - effect: NoSchedule
    key: dedicated
    operator: Equal
    value: production
  priorityClassName: "high-priority"

# Chart-level configuration - overrides global for this chart only
nodeSelector:
  workload-type: api-server
  # This completely replaces the global nodeSelector
  # (no merging with global.nodeSelector)
priorityClassName: "api-priority"
  # This completely replaces the global priorityClassName
```

#### Component-Specific Overrides

For pod-specific scheduling requirements:

```yaml
# Global settings - used as fallback when no more specific config exists
global:
  nodeSelector:
    environment: production
  tolerations:
  - effect: NoSchedule
    key: dedicated
    operator: Equal
    value: production
  priorityClassName: "high-priority"

# Chart-level settings - completely override global settings
nodeSelector:
  workload-type: backend
  # The global nodeSelector is ignored for this chart
priorityClassName: "backend-priority"
  # The global priorityClassName is ignored for this chart

# Pod-specific overrides - completely override chart-level and global settings
jobs:
  migration:
    nodeSelector:
      workload-type: database-maintenance
      # All global and chart-level nodeSelector config is ignored for this job
    tolerations:
    - effect: NoSchedule
      key: maintenance
      operator: Equal
      value: "true"
      # All global and chart-level tolerations are ignored for this job
    priorityClassName: "maintenance-priority"
      # All global and chart-level priorityClassName is ignored for this job
```

#### Complete Example

```yaml
# Global fallback - used when no more specific config exists
global:
  nodeSelector:
    environment: production
    kubernetes.io/arch: amd64
  tolerations:
  - effect: NoSchedule
    key: dedicated
    operator: Equal
    value: production
  priorityClassName: "production-priority"

# Chart-level config - completely replaces global config for this chart
nodeSelector:
  component: api-server
priorityClassName: "api-server-priority"

# Pod-specific config - completely replaces chart-level and global config
jobs:
  backup:
    nodeSelector:
      workload-type: maintenance
    priorityClassName: "maintenance-priority"
    # No tolerations defined, so no tolerations are applied (not even global ones)
```

**Result**: 
- Most pods in this chart use `nodeSelector: {component: api-server}` and `priorityClassName: "api-server-priority"` (chart-level config)
- The backup job uses `nodeSelector: {workload-type: maintenance}`, `priorityClassName: "maintenance-priority"`, and no tolerations
- Other charts without their own configuration would use the global production configuration

## Common Configuration Options

### Basic Chart Configuration

| Parameter          | Description                                            | Default                             |
| ------------------ | ------------------------------------------------------ | ----------------------------------- |
| `replicaCount`     | Number of replicas for the deployment                  | `1`                                 |
| `image.repository` | Container image repository                             | `nginx`                             |
| `image.tag`        | Container image tag                                    | `""` (defaults to chart appVersion) |
| `image.pullPolicy` | Container image pull policy                            | `IfNotPresent`                      |
| `nameOverride`     | Override the name of the chart                         | `""`                                |
| `fullnameOverride` | Override the full name of the chart                    | `""`                                |
| `kind`             | Type of resource to create (Deployment or StatefulSet) | `Deployment`                        |

### Pod Configuration

| Parameter                   | Description                             | Default         |
| --------------------------- | --------------------------------------- | --------------- |
| `podAnnotations`            | Annotations to add to pods              | `{}`            |
| `podLabels`                 | Labels to add to pods                   | `{}`            |
| `podSecurityContext`        | Security context for pods               | See values.yaml |
| `securityContext`           | Default security context for containers | See values.yaml |
| `nodeSelector`              | Node selector for pods                  | `{}`            |
| `tolerations`               | Tolerations for pods                    | `[]`            |
| `priorityClassName`         | Priority class for pods                 | `""`            |
| `affinity`                  | Affinity rules for pods                 | `{}`            |
| `topologySpreadConstraints` | Topology spread constraints for pods    | See values.yaml |

### Container Configuration

Containers are defined in the `containers` section of the values file. Each container can have its own configuration:

```yaml
containers:
  app:
    image:
      repository: myapp
      tag: v1.0.0
    command: ["./start.sh"]
    args: ["--config", "/etc/config/config.yaml"]
    env:
      LOG_LEVEL: "debug"
    ports:
      - containerPort: 8080
        name: http
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
    volumeMounts:
      - name: config
        mountPath: /etc/config
```

### Service Configuration

| Parameter         | Description             | Default         |
| ----------------- | ----------------------- | --------------- |
| `service.enabled` | Enable service creation | `true`          |
| `service.type`    | Service type            | `ClusterIP`     |
| `service.ports`   | Service ports           | See values.yaml |

### Autoscaling Configuration

The chart supports three types of autoscaling:
1. **Horizontal Pod Autoscaling (HPA)** - Standard CPU/memory-based scaling
2. **Vertical Pod Autoscaling (VPA)** - Automatic resource request/limit adjustment
3. **KEDA** - Event-driven autoscaling based on external metrics

#### Horizontal Pod Autoscaler (HPA)

Standard Kubernetes HPA for CPU and memory-based autoscaling:

```yaml
autoscaling:
  horizontal:
    enabled: true
    minReplicas: 2
    maxReplicas: 10
    targetCPUUtilizationPercentage: 80
    targetMemoryUtilizationPercentage: 80
```

#### Vertical Pod Autoscaler (VPA)

Automatically adjusts resource requests and limits:

```yaml
autoscaling:
  vertical:
    enabled: true
    updateMode: "Auto"
    containerPolicies:
      - containerName: "*"
        controlledResources:
          - memory
          - cpu
```

#### KEDA (Event-Driven Autoscaling)

**Important:** KEDA and HPA are mutually exclusive. When KEDA is enabled, it manages its own HPA internally and the chart will not create a separate HPA resource.

KEDA enables autoscaling based on external metrics and events such as:
- Message queue depth (Kafka, RabbitMQ, SQS, etc.)
- Database query results (PostgreSQL, MySQL, etc.)
- Custom metrics (Prometheus, Datadog, etc.)
- Cloud provider metrics (AWS CloudWatch, Azure Monitor, GCP Pub/Sub, etc.)
- HTTP requests, cron schedules, and many more

**Basic KEDA Configuration:**

```yaml
autoscaling:
  keda:
    enabled: true
    minReplicaCount: 1
    maxReplicaCount: 10
    pollingInterval: 30        # How often to check triggers (seconds)
    cooldownPeriod: 300        # Wait time before scaling to zero (seconds)
    triggers:
      - type: prometheus
        metadata:
          serverAddress: http://prometheus:9090
          metricName: http_requests_total
          threshold: "100"
          query: sum(rate(http_requests_total[2m]))
```

**Example: Kafka-Based Autoscaling**

Scale a consumer based on Kafka lag:

```yaml
autoscaling:
  keda:
    enabled: true
    minReplicaCount: 2
    maxReplicaCount: 20
    pollingInterval: 15
    triggers:
      - type: kafka
        metadata:
          bootstrapServers: kafka.default.svc.cluster.local:9092
          consumerGroup: my-consumer-group
          topic: my-topic
          lagThreshold: "10"
          offsetResetPolicy: latest
```

**Example: Redis Queue Autoscaling**

Scale based on Redis list length:

```yaml
autoscaling:
  keda:
    enabled: true
    minReplicaCount: 1
    maxReplicaCount: 15
    idleReplicaCount: 0        # Scale to zero when no items
    cooldownPeriod: 300
    triggers:
      - type: redis
        metadata:
          address: redis.default.svc.cluster.local:6379
          listName: task-queue
          listLength: "5"       # Scale up when more than 5 items
          databaseIndex: "0"
```

**Example: Multiple Triggers**

Scale based on multiple conditions:

```yaml
autoscaling:
  keda:
    enabled: true
    minReplicaCount: 2
    maxReplicaCount: 30
    triggers:
      # Scale on Kafka lag
      - type: kafka
        metadata:
          bootstrapServers: kafka:9092
          consumerGroup: my-group
          topic: events
          lagThreshold: "50"
      # Also scale on CPU when Kafka is caught up
      - type: cpu
        metricType: Utilization
        metadata:
          value: "80"
```

**Advanced KEDA Configuration:**

```yaml
autoscaling:
  keda:
    enabled: true
    minReplicaCount: 2
    maxReplicaCount: 50
    pollingInterval: 30
    cooldownPeriod: 300
    # Fallback configuration if scaler fails
    fallback:
      failureThreshold: 3
      replicas: 10
    # Advanced HPA behavior customization
    advanced:
      horizontalPodAutoscalerConfig:
        behavior:
          scaleDown:
            stabilizationWindowSeconds: 300
            policies:
              - type: Percent
                value: 50
                periodSeconds: 60
          scaleUp:
            stabilizationWindowSeconds: 0
            policies:
              - type: Percent
                value: 100
                periodSeconds: 30
              - type: Pods
                value: 4
                periodSeconds: 30
            selectPolicy: Max
    triggers:
      - type: prometheus
        metadata:
          serverAddress: http://prometheus:9090
          query: sum(rate(worker_tasks_total[2m]))
          threshold: "100"
```

**KEDA in Sizing Configuration:**

KEDA configuration can be included in sizing definitions for environment-specific autoscaling:

```yaml
size: "production"

sizing:
  production:
    resources:
      requests:
        cpu: 500m
        memory: 1Gi
    autoscaling:
      keda:
        enabled: true
        minReplicaCount: 5
        maxReplicaCount: 50
        pollingInterval: 15
        triggers:
          - type: kafka
            metadata:
              bootstrapServers: kafka.prod.svc.cluster.local:9092
              consumerGroup: prod-workers
              topic: production-events
              lagThreshold: "100"
```

For more information on KEDA triggers and configuration options, see the [KEDA documentation](https://keda.sh/docs/latest/scalers/).

### Sizing Configuration

The chart supports defining different "t-shirt" sizes for deployments, which can be used to configure resources, environment variables, and autoscaling for different environments:

```yaml
sizing:
  small:
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
    env:
      MAX_CONNECTIONS: "100"
  medium:
    resources:
      requests:
        cpu: 500m
        memory: 512Mi
    env:
      MAX_CONNECTIONS: "500"
```

To use a specific size, set the `size` parameter:

```yaml
size: "medium"
```

## Examples

### Basic Deployment

```yaml
replicaCount: 2
image:
  repository: myapp
  tag: v1.0.0

containers:
  app:
    ports:
      - containerPort: 8080
        name: http
    env:
      LOG_LEVEL: "info"
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
```

### Deployment with Multiple Containers

```yaml
containers:
  app:
    image:
      repository: myapp
      tag: v1.0.0
    ports:
      - containerPort: 8080
        name: http
  sidecar:
    image:
      repository: sidecar
      tag: v1.0.0
    env:
      MAIN_APP_PORT: "8080"
```

### Job Configuration

```yaml
kind: Job
jobs:
  database-migration:
    containers:
      migration:
        command: ["./migrate.sh"]
        env:
          DATABASE_URL: "postgresql://user:password@db:5432/mydb"
```

## Additional Resources

For more information on Kubernetes concepts used in this chart:

- [Pods](https://kubernetes.io/docs/concepts/workloads/pods/)
- [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
- [Jobs](https://kubernetes.io/docs/concepts/workloads/controllers/job/)
- [CronJobs](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/)
- [Services](https://kubernetes.io/docs/concepts/services-networking/service/)
- [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Pod Security Context](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)
- [Resource Management](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
- [Horizontal Pod Autoscaling](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [Vertical Pod Autoscaling](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler)
- [KEDA (Kubernetes Event Driven Autoscaling)](https://keda.sh/)
