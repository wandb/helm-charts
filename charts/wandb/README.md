# W&B Server Helm Chart

This chart contains all the required components to get started and can scale to
large deployments.

The default Helm chart configuration is intended for PoCs and in cases where components cannot be provisioned outside of kubernetes.

> For a production deployment, you should have strong working knowledge of Kubernetes. This method of deployment has different management, observability,
> and administrative requirements than traditional deployments.

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

By default, the W&B Server container includes an embeded Redis installation.
Although supported, we don't recommend the use in production.
For production, we comend set the `redis` configuration.

Valid configuration for external Redis are:

- `redis: "redis://<HOST>:<PORT>"`
- `redis: "redis://<USER>:<PASSWORD>@<HOST>:<PORT>"`
- `redis: "redis://<USER>:<PASSWORD>@<HOST>:<PORT>?tls=true"`

Or via command line using `--set redis=<REDIS CONFIG>`

## Use extneral stateful data

You can configure the W&B Server Helm chart to point to external stateful
storage for items like MySQL, Redis, and Storage.

The following Terraform (IaC) options use this approach.

- [AWS](https://github.com/wandb/terraform-aws-wandb)
- [Google](https://github.com/wandb/terraform-google-wandb)
- [Azure](https://github.com/wandb/terraform-azurerm-wandb)

For production-grade implementation, the appropriate chart parameters should be
used to point to prebuilt, externalized state stores.

### LDAP

The LDAP TLS cert configuration requires a config map pre-created with the certificate content.

To create the config map you can use the following command:

```
 kubectl -n wandb-helm create configmap ldap-tls-cert --from-file=certificate.crt
```

And use the config map in the `values.yaml` like the example below

```
ldap:
  enabled: true
  [...]
  # Enable LDAP TLS
  tls: true
  # ConfigMap name and key with CA certificate for LDAP server
  tlsCert:
    configMap:
      name: "ldap-tls-cert"
      key: "certificate.crt"
```
