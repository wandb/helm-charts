# W&B Server Helm Chart

This chart contains all the required components to get started and can scale to
large deployments.

> The default Helm chart configuration is not intended for production. The
> default chart creates a proof of concept (PoC) implementation where all
> Weights & Biases services are deployed in the cluster. For production
> deployments, all stateful Weights & Biases components should be deployed
> outside the Kubernetes cluster.

For a production deployment, you should have strong working knowledge of
Kubernetes. This method of deployment has different management, observability,
and concepts than traditional deployments.

The W&B Server Helm chart is made up of multiple subcharts, each of which can be
installed separately.

## Prerequisites

### Kubectl

Install kubectl by following the Kubernetes documentation. The version you
install must be within one minor release of the version running in your cluster

### Helm

Install Helm v3.5.2 or later by following the Helm documentation.

### MySQL

By default, the W&B Server chart includes an in-cluster MySQL deployment that is
provided by bitnami/MySQL. This deployment is for trial purposes only and not
recommended for use in production.

### Redis

By default, the W&B Server chart includes an in-cluster Redis deployment that is
provided by bitnami/Redis. This deployment is for trial purposes only and not
recommended for use in production.

## Use extneral stateful data

You can configure the W&B Server Helm chart to point to external stateful
storage for items like MySQL, Redis, and Storage.

The following Terraform (IaC) options use this approach.

- [AWS](https://github.com/wandb/terraform-aws-wandb)
- [Google](https://github.com/wandb/terraform-google-wandb)
- [Azure](https://github.com/wandb/terraform-azurerm-wandb)

For production-grade implementation, the appropriate chart parameters should be
used to point to prebuilt, externalized state stores.
