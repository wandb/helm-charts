# W&B Reference Architecture Requirements

## Overview
This document outlines the reference architecture requirements for deploying Weights & Biases (W&B) on Kubernetes using the operator-wandb helm chart.

## Deployment Patterns

### 1. Development/PoC Deployment
**Use Case**: Testing, development, small teams (< 10 users)
**Pattern**: All-in-cluster deployment with bundled data stores

```yaml
apiVersion: apps.wandb.com/v1
kind: WeightsAndBiases
metadata:
  name: wandb-dev
  namespace: wandb
spec:
  values:
    global:
      host: "https://wandb-dev.company.com"
      license: "your-license-key"
      size: "small"
      storageClass: "gp2"
    
    # Enable core components
    api:
      enabled: true
      replicaCount: 1
    app:
      install: true
      replicaCount: 1
    frontend:
      install: true
      replicaCount: 1
    console:
      install: true
      replicaCount: 1
    
    # Use in-cluster data stores (NOT for production)
    mysql:
      install: true
    redis:
      install: true
    clickhouse:
      install: true
```

### 2. Production Deployment
**Use Case**: Production workloads, enterprise teams (> 50 users)
**Pattern**: External managed data stores with high availability

```yaml
apiVersion: apps.wandb.com/v1
kind: WeightsAndBiases
metadata:
  name: wandb-prod
  namespace: wandb
spec:
  values:
    global:
      host: "https://wandb.company.com"
      license: "your-production-license"
      size: "large"
      cloudProvider: "aws"  # or "gcp", "azure"
      storageClass: "gp3"
      
      # External MySQL (RDS/Cloud SQL/Azure Database)
      mysql:
        host: "wandb-mysql.cluster-xxx.us-west-2.rds.amazonaws.com"
        port: 3306
        database: "wandb_prod"
        user: "wandb"
        passwordSecret:
          name: "mysql-credentials"
          passwordKey: "MYSQL_PASSWORD"
      
      # External Redis (ElastiCache/Cloud Memorystore)
      redis:
        host: "wandb-redis.cluster.cache.amazonaws.com"
        port: 6379
        passwordSecret:
          name: "redis-credentials"
          passwordKey: "REDIS_PASSWORD"
      
      # External ClickHouse
      clickhouse:
        host: "clickhouse.company.com"
        port: 8123
        database: "weave_trace_db"
        user: "wandb"
        passwordSecret:
          name: "clickhouse-credentials"
          passwordKey: "CLICKHOUSE_PASSWORD"
    
    # Core application components - highly available
    api:
      enabled: true
      replicaCount: 3
      resources:
        requests:
          cpu: 500m
          memory: 1Gi
        limits:
          cpu: 2000m
          memory: 4Gi
    
    app:
      install: true
      replicaCount: 3
      resources:
        requests:
          cpu: 200m
          memory: 512Mi
        limits:
          cpu: 1000m
          memory: 2Gi
    
    frontend:
      install: true
      replicaCount: 2
      resources:
        requests:
          cpu: 100m
          memory: 256Mi
        limits:
          cpu: 500m
          memory: 1Gi
    
    console:
      install: true
      replicaCount: 2
    
    executor:
      install: true
      replicaCount: 2
    
    # Weave components for ML workflows
    weave:
      install: true
      replicaCount: 2
    weave-trace:
      install: true
      replicaCount: 1
    weave-trace-worker:
      install: true
      replicaCount: 2
    
    # File handling
    filestream:
      install: true
      replicaCount: 2
    parquet:
      install: true
      replicaCount: 1
    
    # Disable in-cluster data stores
    mysql:
      install: false
    redis:
      install: false
    clickhouse:
      install: false
    kafka:
      install: false
    
    # Enable monitoring
    prometheus:
      install: true
    otel:
      install: true
```

## Infrastructure Requirements

### Kubernetes Cluster Requirements
- **Kubernetes Version**: 1.20+
- **Helm Version**: 3.5.2+
- **Storage**: Dynamic provisioning with persistent volumes
- **Ingress Controller**: NGINX, ALB, or similar for external access
- **Network**: Pod-to-pod communication, external connectivity for data stores

### Sizing Guidelines

#### Small (< 50 users, light usage)
- **Nodes**: 3 nodes (4 vCPU, 16GB RAM each)
- **Storage**: 500GB persistent storage
- **External Services**:
  - MySQL: db.t3.medium (2 vCPU, 4GB RAM)
  - Redis: cache.t3.micro (2 vCPU, 1GB RAM)
  - Object Storage: 1TB

#### Medium (50-200 users, moderate usage)
- **Nodes**: 5 nodes (8 vCPU, 32GB RAM each)
- **Storage**: 2TB persistent storage
- **External Services**:
  - MySQL: db.t3.large (2 vCPU, 8GB RAM) with read replicas
  - Redis: cache.t3.medium (2 vCPU, 6.1GB RAM)
  - ClickHouse: 3-node cluster (4 vCPU, 16GB RAM each)
  - Object Storage: 10TB

#### Large (200+ users, heavy usage)
- **Nodes**: 10+ nodes (16 vCPU, 64GB RAM each)
- **Storage**: 10TB+ persistent storage
- **External Services**:
  - MySQL: db.r5.xlarge (4 vCPU, 32GB RAM) with multi-AZ
  - Redis: cache.r5.large (2 vCPU, 13GB RAM) with clustering
  - ClickHouse: 5+ node cluster (8 vCPU, 32GB RAM each)
  - Kafka: 3+ broker cluster for event streaming
  - Object Storage: 100TB+

## External Services Architecture

### Required External Services (Production)

#### Database Layer
```yaml
# MySQL - Primary metadata store
global:
  mysql:
    host: "wandb-mysql.cluster-xxx.region.rds.amazonaws.com"
    port: 3306
    database: "wandb_prod"
    user: "wandb"
    passwordSecret:
      name: "mysql-secret"
      passwordKey: "password"

# Redis - Caching and session store  
  redis:
    host: "wandb-redis.cluster.region.cache.amazonaws.com"
    port: 6379
    passwordSecret:
      name: "redis-secret"
      passwordKey: "password"

# ClickHouse - Analytics and trace storage
  clickhouse:
    host: "clickhouse.company.com"
    port: 8123
    database: "weave_trace_db"
    user: "wandb"
    passwordSecret:
      name: "clickhouse-secret"
      passwordKey: "password"
```

#### Storage Layer
```yaml
# Object Storage for artifacts
global:
  defaultBucket:
    provider: "s3"  # or "gcs", "az"
    name: "wandb-artifacts-prod"
    region: "us-west-2"
    kmsKey: "arn:aws:kms:us-west-2:account:key/key-id"
  
  bucket:
    secret:
      secretName: "s3-credentials"
      accessKeyName: "ACCESS_KEY"
      secretKeyName: "SECRET_KEY"
```

#### Message Queue (Optional - for large deployments)
```yaml
global:
  kafka:
    brokerHost: "wandb-kafka.company.com"
    brokerPort: 9092
    user: "wandb"
    passwordSecret:
      name: "kafka-credentials"
      passwordKey: "client-passwords"
```

## Component Architecture

### Core Application Services
- **API**: Main REST API endpoint (3+ replicas for HA)
- **App**: Core application logic (3+ replicas for HA)
- **Frontend**: Web UI (2+ replicas for HA)
- **Console**: Admin interface (2+ replicas for HA)

### Background Processing
- **Executor**: Background job processing (2+ replicas)
- **Filestream**: File upload/download handling (2+ replicas)
- **Parquet**: Data format processing (1+ replica)

### ML Workflow Components (Weave)
- **Weave**: Core ML workflow engine (2+ replicas)
- **Weave-trace**: Trace collection (1+ replica)
- **Weave-trace-worker**: Trace processing workers (2+ replicas)

### Infrastructure Components
- **Glue**: Service interconnection (1+ replica)
- **NGINX**: Load balancing and routing (2+ replicas)
- **Prometheus**: Metrics collection
- **OTEL**: Observability and tracing

## Security Requirements

### Network Security
- TLS termination at ingress
- Internal service-to-service encryption
- Network policies for pod isolation
- VPC/subnet isolation for external services

### Authentication & Authorization
- OIDC/SAML integration for SSO
- RBAC for operator permissions
- Service account management
- Secret management for credentials

### Data Security
- Encryption at rest for all data stores
- Encryption in transit between services
- KMS integration for artifact encryption
- Regular security updates and patching

## Monitoring & Observability

### Metrics
- Prometheus for metrics collection
- Custom metrics for W&B-specific operations
- Resource utilization monitoring
- Application performance monitoring

### Logging
- Centralized logging (ELK/EFK stack)
- Log aggregation from all components
- Audit logging for compliance

### Tracing
- OTEL for distributed tracing
- End-to-end request tracing
- Performance bottleneck identification

## Backup & Disaster Recovery

### Database Backups
- Automated MySQL backups (daily + point-in-time recovery)
- Redis persistence and backups
- ClickHouse data replication

### Application Data
- Object storage cross-region replication
- Configuration backup (secrets, configmaps)
- Helm chart version management

### Recovery Procedures
- RTO: < 4 hours for critical services
- RPO: < 1 hour for data loss
- Multi-region deployment for DR

## Cost Optimization

### Resource Rightsizing
- Use HPA (Horizontal Pod Autoscaler) for dynamic scaling
- VPA (Vertical Pod Autoscaler) for resource optimization
- Node autoscaling for cluster efficiency

### External Service Optimization
- Reserved instances for predictable workloads
- Spot instances for non-critical components
- Storage tiering for long-term artifacts

## Implementation Checklist

### Pre-deployment
- [ ] Kubernetes cluster provisioned and configured
- [ ] External data stores provisioned (MySQL, Redis, ClickHouse)
- [ ] Object storage bucket created with proper IAM
- [ ] DNS and TLS certificates configured
- [ ] Monitoring infrastructure in place

### Deployment
- [ ] Install W&B operator
- [ ] Create namespace and RBAC
- [ ] Deploy secrets for external services
- [ ] Apply WeightsAndBiases custom resource
- [ ] Verify all pods are running and healthy

### Post-deployment
- [ ] Configure ingress and load balancing
- [ ] Set up monitoring dashboards
- [ ] Configure alerting rules
- [ ] Perform end-to-end testing
- [ ] Document runbooks and procedures

## Scaling Considerations

### Horizontal Scaling
- API, App, Frontend: Scale based on CPU/memory utilization
- Executor: Scale based on job queue depth
- Weave components: Scale based on ML workload volume

### Vertical Scaling
- Database connections and memory for high-throughput components
- Storage IOPS for file-intensive operations
- Network bandwidth for large artifact uploads

### External Service Scaling
- MySQL read replicas for read-heavy workloads
- Redis clustering for large cache requirements
- ClickHouse sharding for analytics queries
- CDN for static asset delivery