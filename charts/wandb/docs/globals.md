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
needs to set redis.cluster.enabled=true when the GitLab chart is installed.

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
