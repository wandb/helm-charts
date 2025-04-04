# ClickHouse Chart

This chart deploys ClickHouse for Weights & Biases, optimized for trace storage.

## Architecture

The deployment consists of:
- 3 ClickHouse Keeper nodes (always 3 for high availability)
- Configurable number of ClickHouse server replicas (default: 3, can be set to 1 for development)

## Configuration

| Parameter                            | Description                                                      | Default                        |
| ------------------------------------ | ---------------------------------------------------------------- | ------------------------------ |
| `clickhouse.install`                 | Enable or disable ClickHouse installation                        | `true`                         |
| `clickhouse.replicas`                | Number of ClickHouse server replicas (Keeper will always be 3)   | `3`                            |
| `clickhouse.database`                | Database name for ClickHouse                                     | `weave_trace_db`               |
| `clickhouse.user`                    | User for ClickHouse                                              | `wandb-user`                   |
| `clickhouse.password`                | Password for ClickHouse (will be auto-generated if not provided) | `""`                           |
| `clickhouse.passwordSecret.name`     | Name of existing secret containing the password                  | `""`                           |
| `clickhouse.passwordSecret.key`      | Key in the secret containing the password                        | `CLICKHOUSE_PASSWORD`          |
| `clickhouse.server.httpPort`         | HTTP port for ClickHouse                                         | `8123`                         |
| `clickhouse.server.tcpPort`          | TCP port for ClickHouse                                          | `9000`                         |
| `clickhouse.server_image.repository` | ClickHouse server image repository                               | `clickhouse/clickhouse-server` |
| `clickhouse.server_image.tag`        | ClickHouse server image tag                                      | `24.8.14`                      |
| `clickhouse.keeper_image.repository` | ClickHouse keeper image repository                               | `clickhouse/clickhouse-keeper` |
| `clickhouse.keeper_image.tag`        | ClickHouse keeper image tag                                      | `24.8.14`                      |

### S3 Bucket Configuration

This chart supports two modes for S3 bucket configuration:

#### Single Bucket Mode

In single bucket mode, all ClickHouse replicas use the same S3 bucket with different paths:

| Parameter                           | Description                                     | Default      |
| ----------------------------------- | ----------------------------------------------- | ------------ |
| `clickhouse.bucket.useSingleBucket` | Use a single bucket for all replicas            | `false`      |
| `clickhouse.bucket.endpoint`        | S3 bucket endpoint (required for single bucket) | `""`         |
| `clickhouse.bucket.path`            | Base path prefix for all replicas               | `clickhouse` |

When using single bucket mode, the paths inside your bucket will be structured as follows:

```
your-bucket-name/
├── [path-prefix]/replica-0/
├── [path-prefix]/replica-1/
├── [path-prefix]/replica-2/
```

For example, with `path: "clickhouse-data"`, the actual paths would be:
- ClickHouse Server 0: `s3://your-bucket-name/clickhouse-data/replica-0`
- ClickHouse Server 1: `s3://your-bucket-name/clickhouse-data/replica-1`
- ClickHouse Server 2: `s3://your-bucket-name/clickhouse-data/replica-2`

#### Multiple Bucket Mode

In multiple bucket mode, each ClickHouse replica uses a separate S3 bucket:

| Parameter                           | Description                                   | Default |
| ----------------------------------- | --------------------------------------------- | ------- |
| `clickhouse.bucket.useSingleBucket` | Use a single bucket for all replicas          | `false` |
| `clickhouse.bucket.endpoints`       | List of S3 bucket endpoints (one per replica) | `[]`    |

When using multiple bucket mode, each replica uses its own dedicated bucket:

```
bucket-for-replica-0/  (for ClickHouse Server 0)
bucket-for-replica-1/  (for ClickHouse Server 1)
bucket-for-replica-2/  (for ClickHouse Server 2)
```

The number of endpoints provided must match the number of replicas specified in `clickhouse.replicas`.

### S3 Credentials Configuration

The chart supports three ways to provide S3 credentials:

1. **Instance Metadata** (recommended for cloud environments):

| Parameter                               | Description                           | Default |
| --------------------------------------- | ------------------------------------- | ------- |
| `clickhouse.bucket.useInstanceMetadata` | Use instance metadata for credentials | `false` |

2. **Secret Reference**:

| Parameter                                | Description                               | Default            |
| ---------------------------------------- | ----------------------------------------- | ------------------ |
| `clickhouse.bucket.secret.secretName`    | Name of the secret containing credentials | `wandb-clickhouse` |
| `clickhouse.bucket.secret.accessKeyName` | Key in the secret for access key          | `ACCESS_KEY`       |
| `clickhouse.bucket.secret.secretKeyName` | Key in the secret for secret key          | `SECRET_KEY`       |

3. **Plain Text Credentials** (not recommended for production):

| Parameter                           | Description          | Default |
| ----------------------------------- | -------------------- | ------- |
| `clickhouse.bucket.accessKeyId`     | S3 access key ID     | `""`    |
| `clickhouse.bucket.secretAccessKey` | S3 secret access key | `""`    |

### Cache Configuration

ClickHouse uses local cache to improve performance. The persistent volume will be 10GB larger than the cache size:

| Parameter               | Description                 | Default                     |
| ----------------------- | --------------------------- | --------------------------- |
| `clickhouse.cache.size` | Cache size for ClickHouse   | `20Gi`                      |
| `clickhouse.cache.path` | Cache path in the container | `/var/lib/clickhouse/cache` |

### Persistence Configuration

The chart uses persistent volumes for both ClickHouse server replicas and Keeper nodes:

| Parameter                                   | Description                                                              | Default                         |
| ------------------------------------------- | ------------------------------------------------------------------------ | ------------------------------- |
| `clickhouse.persistence.server.size`        | Size for each ClickHouse server PVC                                      | Auto-calculated from cache size |
| `clickhouse.persistence.server.accessModes` | Access modes for server PVCs                                             | `["ReadWriteOnce"]`             |
| `clickhouse.persistence.keeper.size`        | Size for each ClickHouse Keeper PVC (important for raft quorum recovery) | `10Gi`                          |
| `clickhouse.persistence.keeper.accessModes` | Access modes for Keeper PVCs                                             | `["ReadWriteOnce"]`             |

The Keeper persistence is critical for maintaining the raft quorum and ensuring high availability. It specifically persists:
- Coordination logs: `/var/lib/clickhouse/coordination/log`
- Coordination snapshots: `/var/lib/clickhouse/coordination/snapshots`

These paths are critical for the raft quorum recovery when pods are restarted or rescheduled.

## External ClickHouse Configuration

If you prefer to use an external ClickHouse instance, set `clickhouse.install: false` and configure the external ClickHouse using the `global.clickhouse` settings:

| Parameter                                      | Description                                   | Default               |
| ---------------------------------------------- | --------------------------------------------- | --------------------- |
| `global.clickhouse.host`                       | External ClickHouse host                      | `""`                  |
| `global.clickhouse.port`                       | External ClickHouse port                      | `8123`                |
| `global.clickhouse.database`                   | External ClickHouse database                  | `weave_trace_db`      |
| `global.clickhouse.user`                       | External ClickHouse user                      | `default`             |
| `global.clickhouse.password`                   | External ClickHouse password                  | `""`                  |
| `global.clickhouse.passwordSecret.name`        | Name of the secret containing the password    | `""`                  |
| `global.clickhouse.passwordSecret.passwordKey` | Key in the secret containing the password     | `CLICKHOUSE_PASSWORD` |
| `global.clickhouse.replicated`                 | Whether the external ClickHouse is replicated | `false`               |

## Example Configuration

Below is an example values.yaml for deploying the Weights & Biases Operator with weave-trace and the new ClickHouse chart using a simple configuration:

```yaml
# Deploy weave-trace
weave-trace:
  install: true

# Deploy and configure ClickHouse
clickhouse:
  install: true
  
  # Number of ClickHouse server replicas
  replicas: 3  # Can be set to 1 for development environments
  
  # User and password in clear text (for simplicity)
  user: "wandb"
  password: "your-secure-password"  # In production, consider using passwordSecret
  
  # Database name for weave-trace
  database: "weave_trace_db"
  
  # S3 bucket configuration - single bucket with paths per replica
  bucket:
    useSingleBucket: true
    endpoint: "s3.amazonaws.com/your-bucket-name"
    path: "clickhouse-data"  # Will automatically append /replica-[0-N] to this path
    region: "us-east-1"
    
    # Explicit S3 credentials (for simplicity)
    accessKeyId: "your-access-key"
    secretAccessKey: "your-secret-key"
    # In production, consider using the secret reference:
    # secret:
    #   secretName: "your-s3-credentials-secret"
    #   accessKeyName: "ACCESS_KEY"
    #   secretKeyName: "SECRET_KEY"
    
  # Cache configuration
  cache:
    size: "20Gi"  # PV size will be 30Gi (20Gi + 10Gi)
    
  # Persistence configuration
  persistence:
    # Server persistence (for ClickHouse replicas)
    server:
      accessModes:
        - ReadWriteOnce
    # Keeper persistence (for ClickHouse Keeper nodes)
    keeper:
      size: "10Gi"

### Using an External ClickHouse

Alternatively, if you want to use an existing external ClickHouse instance:

```yaml
# Don't deploy ClickHouse, use external instance
clickhouse:
  install: false

# Deploy weave-trace
weave-trace:
  install: true

# Configure external ClickHouse for weave-trace  
global:
  clickhouse:
    host: "your-external-clickhouse-host.example.com"
    port: 8123
    database: "weave_trace_db"
    user: "wandb"
    password: "your-external-clickhouse-password"
    replicated: true  # Set to true if your external ClickHouse is replicated
```

This configuration will:
1. Deploy only weave-trace without deploying ClickHouse
2. Configure weave-trace to connect to your external ClickHouse instance
3. Use the specified credentials and database for the external connection

### Minimal Development Configuration

For development or testing purposes, you can minimize resources by using a single ClickHouse replica:

```yaml
# Deploy weave-trace
weave-trace:
  install: true

# Deploy ClickHouse with minimal configuration
clickhouse:
  install: true
  
  # Use a single ClickHouse server replica for development
  replicas: 1
  
  # Simple user and password
  user: "wandb"
  password: "dev-password"
  
  # S3 bucket configuration - instance metadata (for cloud environments)
  bucket:
    useSingleBucket: true
    endpoint: "s3.amazonaws.com/dev-bucket"
    path: "clickhouse-dev"
    region: "us-east-1"
    useInstanceMetadata: true  # Use IAM role instead of explicit credentials
    
  # Smaller cache for development
  cache:
    size: "5Gi"  # PV size will be 15Gi (5Gi + 10Gi)
    
  # Smaller keeper persistence for development
  persistence:
    keeper:
      size: "5Gi"
```

This minimal configuration still maintains the 3-node Keeper cluster for high availability (required for ClickHouse coordination) but reduces the number of ClickHouse server replicas to just one, which is sufficient for development and testing.
