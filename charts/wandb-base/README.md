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
- `tag`: The image tag
- `pullPolicy`: The image pull policy

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
    # This container uses its own image configuration
    image:
      repository: myapp
      tag: "v1.0.0"
      pullPolicy: Always
  sidecar:
    # This container doesn't specify an image, so it will use the chart-level image
    env:
      SIDECAR_MODE: "true"
```

In this example:
- The `app` container will use the image `myapp:v1.0.0` with pull policy `Always`
- The `sidecar` container will use the chart-level image `nginx:1.21.6` with pull policy `IfNotPresent`

## Common Configuration Options

### Basic Chart Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas for the deployment | `1` |
| `image.repository` | Container image repository | `nginx` |
| `image.tag` | Container image tag | `""` (defaults to chart appVersion) |
| `image.pullPolicy` | Container image pull policy | `IfNotPresent` |
| `nameOverride` | Override the name of the chart | `""` |
| `fullnameOverride` | Override the full name of the chart | `""` |
| `kind` | Type of resource to create (Deployment or StatefulSet) | `Deployment` |

### Pod Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `podAnnotations` | Annotations to add to pods | `{}` |
| `podLabels` | Labels to add to pods | `{}` |
| `podSecurityContext` | Security context for pods | See values.yaml |
| `securityContext` | Default security context for containers | See values.yaml |
| `nodeSelector` | Node selector for pods | `{}` |
| `tolerations` | Tolerations for pods | `[]` |
| `affinity` | Affinity rules for pods | `{}` |
| `topologySpreadConstraints` | Topology spread constraints for pods | See values.yaml |

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

| Parameter | Description | Default |
|-----------|-------------|---------|
| `service.enabled` | Enable service creation | `true` |
| `service.type` | Service type | `ClusterIP` |
| `service.ports` | Service ports | See values.yaml |

### Autoscaling Configuration

The chart supports both Horizontal Pod Autoscaling (HPA) and Vertical Pod Autoscaling (VPA):

```yaml
autoscaling:
  horizontal:
    enabled: true
    minReplicas: 2
    maxReplicas: 10
    targetCPUUtilizationPercentage: 80
  vertical:
    enabled: true
    updateMode: "Auto"
    containerPolicies:
      - containerName: "*"
        controlledResources:
          - memory
          - cpu
```

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