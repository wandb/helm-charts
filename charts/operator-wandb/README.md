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
```

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

## Use External Stateful Data

You can configure the W&B Server Helm chart to point to external stateful storage for items like MySQL, Redis, and Storage.

The following Terraform (IaC) options use this approach:

- [AWS](https://github.com/wandb/terraform-aws-wandb)
- [Google](https://github.com/wandb/terraform-google-wandb)
- [Azure](https://github.com/wandb/terraform-azurerm-wandb)

For production-grade implementation, the appropriate chart parameters should be used to point to prebuilt, externalized state stores.


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