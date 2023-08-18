# Configure chart globals

To reduce configuration duplication when installing our wrapper Helm chart,
several configuration settings are available to be set in the global section of
values.yaml. These global settings are used across several charts, while all
other settings are scoped within their chart. See the Helm documentation on
globals for more information on how the global variables work.

- [Configure chart globals](#configure-chart-globals)
  - [Hosts](#hosts)
  - [Redis](#redis)
  - [MySQL](#mysql)

## Hosts

The W&B Server global host settings are located under the `global.hosts` key.

```yaml
global:
  hosts:
    domain: example.com
```

## Redis

The W&B Server global Redis settings are located under the `global.redis` key.

By default we use an single, non-replicated Redis instance. If desired, a highly
available Redis can be deployed instead. To install an HA Redis cluster one
needs to set redis.cluster.enabled=true when the W&B chart is installed.

```yaml
global:
  redis:
    host: redis.example.com
    serviceName: redis
    port: 6379
    password: "wandb-redis-password"
    scheme:
```

## MySQL

The W&B Server global MySQL settings are located under the `global.mysql` key.

```yaml
global:
  mysql:
    host: mysql.example.com
    port: 5432
    database: wandb
    username: wandb
    password:
      secret: wandb-postgres
      key: wandb-password
      usePlan: false
      plan:
```
