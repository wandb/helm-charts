# ClickHouse Chart

This chart deploys ClickHouse for Weights & Biases, optimized for trace storage.

## Architecture

The deployment consists of:
- 3 ClickHouse Keeper nodes (always 3 for high availability)
- Configurable number of ClickHouse server replicas (default: 3, can be set to 1 for development)

## Integration with Weights & Biases

This chart is part of the Weights & Biases Operator and is integrated with Weave Trace. It can be used in two ways:

1. **Deployed by the Operator (`clickhouse.install: true`)**: 
   - The chart deploys a complete ClickHouse installation
   - All configuration is managed by this chart
   - Weave Trace connects to this internal ClickHouse

2. **External ClickHouse (`clickhouse.install: false`)**: 
   - No ClickHouse components are deployed
   - Weave Trace connects to an external ClickHouse using `global.clickhouse` settings
   - S3 bucket configuration in this chart is ignored

## Configuration

| Parameter                 | Description                          | Default                        |
| ------------------------- | ------------------------------------ | ------------------------------ |
| `replicas`                | Number of ClickHouse server replicas | `3`                            |
| `server_image.repository` | ClickHouse server image repository   | `clickhouse/clickhouse-server` |
| `server_image.tag`        | ClickHouse server image tag          | `24.8.14`                      |
| `keeper_image.repository` | ClickHouse keeper image repository   | `clickhouse/clickhouse-keeper` |
| `keeper_image.tag`        | ClickHouse keeper image tag          | `24.8.14`                      |
| `server.tcpPort`          | TCP port for ClickHouse              | `9000`                         |
| `server.intrsrvhttpPort`  | Interserver HTTP port                | `9009`                         |
| `cache.size`              | Cache size for ClickHouse            | `20Gi`                         |
| `cache.path`              | Cache path within container          | `/var/lib/clickhouse/cache`    |

### S3 Bucket Configuration

The S3 bucket configuration is only used when the chart deploys ClickHouse (`clickhouse.install: true`). It is ignored when using an external ClickHouse.

#### Path Style vs Virtual Hosted Style

The chart supports both path-style and virtual hosted-style S3 URLs:

| Parameter             | Description                                      | Default |
| --------------------- | ------------------------------------------------ | ------- |
| `bucket.usePathStyle` | Use path-style S3 URLs instead of virtual hosted | `true`  |

Format endpoints according to the style you choose:
- Path-style: `https://s3-endpoint.example.com/bucket-name`
- Virtual hosted-style: `https://bucket-name.s3-endpoint.example.com`

#### Single vs Multiple Bucket Modes

You can configure ClickHouse to use a single bucket for all replicas or separate buckets for each replica:

##### Single Bucket Mode

In single bucket mode, all ClickHouse replicas use the same bucket with different paths:

| Parameter                | Description                          | Default      |
| ------------------------ | ------------------------------------ | ------------ |
| `bucket.useSingleBucket` | Use a single bucket for all replicas | `false`      |
| `bucket.endpoint`        | S3 bucket endpoint with bucket name  | `""`         |
| `bucket.path`            | Base path prefix for replicas        | `clickhouse` |

The resulting path structure will be:
```
bucket/
├── clickhouse/
    ├── replica-0/
    ├── replica-1/
    ├── replica-2/
```

##### Multiple Bucket Mode

In multiple bucket mode, each ClickHouse replica uses a separate bucket:

| Parameter                | Description                          | Default |
| ------------------------ | ------------------------------------ | ------- |
| `bucket.useSingleBucket` | Use a single bucket for all replicas | `false` |
| `bucket.endpoints`       | List of S3 bucket endpoints          | `[]`    |

The number of endpoints must match the number of replicas. Each endpoint can use:
- Simple string (uses global credentials): `"https://s3.example.com/bucket1"`
- Object with custom credentials:
  ```yaml
  - url: "https://s3.example.com/bucket2"
    accessKeyId: "key2"
    secretAccessKey: "secret2"
  ```
  or
  ```yaml
  - url: "https://s3.example.com/bucket3"
    secretName: "bucket3-secret"
    accessKeyName: "ACCESS_KEY"
    secretKeyName: "SECRET_KEY"
  ```

### S3 Credentials

| Parameter                     | Description                           | Default      |
| ----------------------------- | ------------------------------------- | ------------ |
| `bucket.useInstanceMetadata`  | Use instance metadata for credentials | `false`      |
| `bucket.accessKeyId`          | S3 access key ID                      | `""`         |
| `bucket.secretAccessKey`      | S3 secret access key                  | `""`         |
| `bucket.secret.secretName`    | Name of the secret for credentials    | `""`         |
| `bucket.secret.accessKeyName` | Key in the secret for access key      | `ACCESS_KEY` |
| `bucket.secret.secretKeyName` | Key in the secret for secret key      | `SECRET_KEY` |

The chart will try credentials in this order:
1. Instance metadata (if `useInstanceMetadata: true`)
2. Explicitly provided credentials
3. Secret reference

### Persistence Configuration

The chart uses persistent volumes for both ClickHouse server replicas and Keeper nodes:

| Parameter                        | Description                  | Default                         |
| -------------------------------- | ---------------------------- | ------------------------------- |
| `persistence.server.size`        | Size for each server PVC     | Auto-calculated from cache size |
| `persistence.server.accessModes` | Access modes for server PVCs | `["ReadWriteOnce"]`             |
| `persistence.keeper.size`        | Size for each Keeper PVC     | `10Gi`                          |
| `persistence.keeper.accessModes` | Access modes for Keeper PVCs | `["ReadWriteOnce"]`             |

## Example Configurations

### Basic Configuration

```yaml
clickhouse:
  install: true
  replicas: 3
  bucket:
    useSingleBucket: true
    usePathStyle: true
    endpoint: "https://s3.amazonaws.com/your-bucket-name"
    path: "clickhouse-data"
    region: "us-east-1"
    useInstanceMetadata: true
```

### Multi-Bucket with Different Credentials

```yaml
clickhouse:
  install: true
  replicas: 3
  bucket:
    useSingleBucket: false
    usePathStyle: true
    region: "us-east-1"
    endpoints:
      - url: "https://s3.example.com/dept1-bucket"
        accessKeyId: "dept1-access-key"
        secretAccessKey: "dept1-secret-key"
      - url: "https://s3.example.com/dept2-bucket"
        secretName: "dept2-credentials"
      - url: "https://s3.example.com/dept3-bucket"
        useInstanceMetadata: true
```

### Development Configuration

```yaml
clickhouse:
  install: true
  replicas: 1  # Single replica for development
  bucket:
    useSingleBucket: true
    endpoint: "https://minio.example.com/dev-bucket"
    path: "clickhouse-dev"
    region: "us-east-1"
    accessKeyId: "dev-key"
    secretAccessKey: "dev-secret"
  cache:
    size: "5Gi"
  persistence:
    keeper:
      size: "5Gi"
```
