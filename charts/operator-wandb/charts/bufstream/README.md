## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| adminTLS | object | `{}` | adminTLS contains TLS configuration for Admin Server. |
| bufstream.controlServerService.annotations | object | `{}` | Kubernetes Service annotations. |
| bufstream.controlServerService.enabled | bool | `false` | Whether to create a Kubernetes Headless Service for the Bufstream Control Server (inter-agent RPC server using the Connect protocol). |
| bufstream.deployment.affinity | object | `{}` | Bufstream Deployment Affinity. |
| bufstream.deployment.args | list | `[]` | Bufstream Deployment args to be appended. |
| bufstream.deployment.autoscaling.behavior | object | `{}` | [Horizontal Pod Autoscaler behavior.](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/#configurable-scaling-behavior) |
| bufstream.deployment.autoscaling.enabled | bool | `false` | Whether to enable the horizontal pod autoscaler. |
| bufstream.deployment.autoscaling.maxReplicas | int | `18` | Maximum number of autoscaler allowed replicas. |
| bufstream.deployment.autoscaling.minReplicas | int | `6` | Minimum number of autoscaler allowed replicas. |
| bufstream.deployment.autoscaling.targetCPU | string | `"50"` | Target CPU threshold for managing replica count. |
| bufstream.deployment.autoscaling.targetMemory | string | `""` | Target memory threshold for managing replica count. |
| bufstream.deployment.command | list | `["/usr/local/bin/bufstream"]` | Bufstream Deployment command. |
| bufstream.deployment.extraContainerPorts | object | `{}` | Bufstream Deployment Extra container ports for the bufstream container. |
| bufstream.deployment.extraContainers | list | `[]` | Bufstream Deployment additional containers to run besides the bufstream container. |
| bufstream.deployment.extraEnv | list | `[]` | Bufstream Deployment Extra environment variables for the bufstream container. |
| bufstream.deployment.extraVolumeMounts | list | `[]` | Bufstream Deployment Extra volume mounts for the bufstream container. |
| bufstream.deployment.extraVolumes | list | `[]` | Bufstream Deployment Extra volumes. |
| bufstream.deployment.kind | string | `"StatefulSet"` | Bufstream Deployment kind. Supports [Deployment, StatefulSet] |
| bufstream.deployment.livenessProbe.failureThreshold | int | `3` | Bufstream Deployment Liveness Probe Maximum failure threshold. |
| bufstream.deployment.livenessProbe.timeoutSeconds | int | `5` | Bufstream Deployment Liveness Probe timeout. |
| bufstream.deployment.nodeSelector | object | `{}` | Bufstream Deployment Node selector. |
| bufstream.deployment.podAnnotations | object | `{}` | Bufstream Deployment Pod annotations. |
| bufstream.deployment.podLabels | object | `{}` | Bufstream Deployment Pod labels. |
| bufstream.deployment.podManagementPolicy | string | `"Parallel"` | Bufstream Deployment pod management policy to use when StatefulSet kind is used. |
| bufstream.deployment.readinessProbe.failureThreshold | int | `3` | Bufstream Deployment Readiness Probe Maximum failure threshold. |
| bufstream.deployment.readinessProbe.timeoutSeconds | int | `5` | Bufstream Deployment Readiness Probe timeout. |
| bufstream.deployment.replicaCount | int | `3` | Bufstream Deployment replica count. |
| bufstream.deployment.resources.limits.cpu | string | `""` | Bufstream Deployment Resource request CPU. |
| bufstream.deployment.resources.limits.memory | string | `"8Gi"` | Bufstream Deployment Resource limits memory. |
| bufstream.deployment.resources.requests.cpu | int | `2` | Bufstream Deployment Resource request CPU. |
| bufstream.deployment.resources.requests.memory | string | `"8Gi"` | Bufstream Deployment Resource request memory. |
| bufstream.deployment.selectorLabels | object | `{}` | Bufstream Deployment Selector labels. |
| bufstream.deployment.serviceName | string | `""` | Bufstream Deployment service name to link for per pod DNS registration when StatefulSet kind is used. |
| bufstream.deployment.shareProcessNamespace | bool | `false` | Bufstream Deployment setting for sharing the process namespace. |
| bufstream.deployment.startupProbe.failureThreshold | int | `3` | Bufstream Deployment Liveness Probe Configuration |
| bufstream.deployment.terminationGracePeriodSeconds | int | `420` | Bufstream Deployment termination grace period. |
| bufstream.deployment.tolerations | list | `[]` | Bufstream Deployment Tolerations. |
| bufstream.image.pullPolicy | string | `"IfNotPresent"` | Bufstream Deployment container image pull policy. |
| bufstream.image.repository | string | `"us-docker.pkg.dev/buf-images-1/bufstream-public/images/bufstream"` | Bufstream Deployment container image repository. |
| bufstream.image.tag | string | `"0.3.5"` | Overrides the image tag whose default is the chart version. |
| bufstream.podDisruptionBudget.enabled | bool | `false` | Whether to enable pod disruption budget. |
| bufstream.podDisruptionBudget.maxUnavailable | string | `""` | Number of pods that are unavailable after eviction as number or percentage (eg.: 50%). Has higher precedence over `minAvailable` |
| bufstream.podDisruptionBudget.minAvailable | string | `""` (defaults to 0 if not specified) | Number of pods that are available after eviction as number or percentage (eg.: 50%). |
| bufstream.service.annotations | object | `{}` | Kubernetes Service annotations. |
| bufstream.service.enabled | bool | `true` | Whether to create a Kubernetes Service for this bufstream deployment. |
| bufstream.service.type | string | `"ClusterIP"` | Kubernetes Service type. |
| bufstream.serviceAccount.annotations | object | `{}` | Kubernetes Service Account annotations. |
| bufstream.serviceAccount.create | bool | `true` | Whether to create a Kubernetes Service Account for this bufstream deployment. |
| bufstream.serviceAccount.name | string | `"bufstream-service-account"` | Kubernetes Service Account name. |
| cluster | string | `"bufstream"` | The name of the cluster. Used by bufstream to identify itself. |
| configOverrides | object | `{}` | Bufstream configuration overrides. Any value here will be set directly on the bufstream config.yaml, taking precedence over any other helm defined values. |
| connectTLS | object | `{"client":{},"server":{}}` | connectTLS contains TLS configuration for Control Server which is used for inter-agent communication using Connect protocol. |
| connectTLS.client | object | `{}` | Client contains client side TLS configuration to connect to the Control Server. |
| connectTLS.server | object | `{}` | Server contains server side TLS configuration. |
| dataEnforcement | object | `{}` | Configuration for data enforcement via schemas of records flowing in and out of the agent. |
| discoverZoneFromNode | bool | `false` | When true it enables additional permissions so Bufstream can get the zone via the Kubernetes API server by reading the zone topology label of the node the bufstream pod is running on. Bufstream won't attempt to do the discovery if the zone option is false. |
| extraObjects | list | `[]` | Extra Kubernetes objects to install as part of this chart. |
| imagePullSecrets | list | `[]` | Reference to one or more secrets to be used when pulling images. For more information, see [Pull an Image from a Private Registry](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/). |
| kafka.address | object | `{"host":"0.0.0.0","port":9092}` | The address the Kafka server should listen on. This defaults to 0.0.0.0 (any) and 9092 port. |
| kafka.exactLogOffsets | bool | `false` | If exact log hwm and start offsets should be computed when fetching records. |
| kafka.exactLogSizes | bool | `true` | If exact log sizes should be fetched when listing sizes for all topics/partitions. |
| kafka.fetchEager | bool | `true` | If a fetch should return as soon as any records are available. |
| kafka.fetchSync | bool | `true` | If fetches from different readers should be synchronized to improve cache hit rates. |
| kafka.groupConsumerSessionTimeout | string | `"45s"` | The default group consumer session timeout. |
| kafka.groupConsumerSessionTimeoutMax | string | `"60s"` | The maximum group consumer session timeout. |
| kafka.groupConsumerSessionTimeoutMin | string | `"10s"` | The minimum group consumer session timeout. |
| kafka.idleTimeout | int | `0` | How long a Kafka connection can be idle before being closed by the server. If set a value less than or equal to zero, the timeout will be disabled. |
| kafka.numPartitions | int | `1` | The default number of partitions to use for a new topic. |
| kafka.partitionBalanceStrategy | string | `"BALANCE_STRATEGY_PARTITION"` | How to balance topic/partitions across bufstream nodes. One of: ["BALANCE_STRATEGY_UNSPECIFIED", "BALANCE_STRATEGY_PARTITION", "BALANCE_STRATEGY_HOST", "BALANCE_STRATEGY_CLIENT_ID"] |
| kafka.produceConcurrent | bool | `true` | If records from a producer to different topic/partitions may be sequenced concurrently instead of serially. |
| kafka.publicAddress | object | `{host: "<service>.<namespace>.svc.cluster.local", port: 9092}` | The public address clients should use to connect to the Kafka server. This defaults to the K8S service DNS and 9092 port. |
| kafka.requestBufferSize | int | `5` | The number of kafka request to unmarshal and buffer before processing. |
| kafka.tlsCertificateSecrets | list | `[]` | Kubernetes secrets containing a `tls.crt` and `tls.key` (as the secret keys, see https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets) to present to the client. The first certificate compatible with the client's requirements is selected automatically. |
| kafka.tlsClientAuth | string | `"NO_CERT"` | Declare the policy the server will follow for mutual TLS (mTLS). Supported values are [NO_CERT, REQUEST_CERT, REQUIRE_CERT, VERIFY_CERT_IF_GIVEN, REQUIRE_AND_VERIFY_CERT]. Only supported when using tlsCertificateSecret. |
| kafka.tlsClientCasSecret | string | `""` | Kubernetes secret containing a `tls.crt` (as the secret key) PEM-encoded certificate authorities used by the server to validate the client certificates. This field cannot be empty if tlsClientAuth is set for client performing verification. Only supported when using tlsCertificateSecret. |
| kafka.zoneBalanceStrategy | string | `"BALANCE_STRATEGY_PARTITION"` | How to balance clients across zones, when client does not specify a zone. One of: ["BALANCE_STRATEGY_UNSPECIFIED", "BALANCE_STRATEGY_PARTITION", "BALANCE_STRATEGY_HOST", "BALANCE_STRATEGY_CLIENT_ID"] |
| metadata.etcd.addresses | list | `[]` | Etcd addresses to connect to. |
| metadata.etcd.tls | object | `{}` | TLS client configuration for bufstream to connect to etcd. |
| metadata.use | string | `"etcd"` | Which metadata storage that bufstream is using. Currently, only `etcd` is supported. |
| nameOverride | string | `""` | Overrides .Chart.Name throughout the chart. |
| namespaceCreate | bool | `false` | Whether to create the namespace where resources are located. |
| namespaceOverride | string | `""` | Will be used as the namespace for all resources instead of .Release.namespace if set |
| observability.exporter.address | string | `""` | Open Telemetry base endpoint to push metrics and traces. The value has a host and an optional port. It should not include the URL path, such as "/v1/traces" or the scheme. This can be overriden by metrics.address or tracing.address. |
| observability.exporter.insecure | bool | `false` | Whether to disable TLS for the exporter's HTTP connection. This can be overriden by metrics.insecure or tracing.insecure. |
| observability.logLevel | string | `"INFO"` | Log level to use. |
| observability.metrics.address | string | `""` | The endpoint the exporter connects to. The value has a host and an optional port. It should not include the URL path, such as "/v1/metrics" or the scheme. Specify path and insecure instead. |
| observability.metrics.aggregation.consumerGroups | bool | `false` |  |
| observability.metrics.aggregation.partitions | bool | `false` |  |
| observability.metrics.aggregation.topics | bool | `false` |  |
| observability.metrics.exporter | string | `""` | Open Telemetry exporter. Supports [NONE, STDOUT, HTTP, HTTPS, PROMETHEUS]. Deprecated: use exporterType instead. |
| observability.metrics.exporterType | string | `"NONE"` | Open Telemetry exporter. Supports [NONE, STDOUT, OTLP_GRPC, OTLP_HTTP, PROMETHEUS] |
| observability.metrics.insecure | bool | `false` | Whether to disable TLS. This can only be specified for OTLP_HTTP exporter type. |
| observability.metrics.otlpTemporalityPreference | string | `""` |  |
| observability.metrics.path | string | `""` |  |
| observability.otlpEndpoint | string | `""` | Open Telemetry base endpoint to push metrics and traces to. Deprecated: use exporter.address and exporter.insecure instead. |
| observability.sensitiveInformationRedaction | string | `"NONE"` | Redact sensitive information such as topic names, before adding to to metrics, traces and logs. Supports [NONE, OPAQUE] |
| observability.tracing.address | string | `""` | The endpoint the exporter connects to. The value has a host and an optional port. It should not include the URL path, such as "/v1/traces" or the scheme. Specify path and insecure instead. |
| observability.tracing.exporter | string | `""` | Open Telemetry exporter. Supports [NONE, STDOUT, HTTP, HTTPS]. Deprecated: use exporterType instead. |
| observability.tracing.exporterType | string | `"NONE"` | Open Telemetry exporter. Supports [NONE, STDOUT, OTLP_GRPC, OTLP_HTTP] |
| observability.tracing.insecure | bool | `false` | Whether to disable TLS. This can only be specified for OTLP_HTTP exporter type. |
| observability.tracing.path | string | `""` |  |
| observability.tracing.traceRatio | float | `0.1` | Trace sample ratio. |
| storage.gcs.bucket | string | `""` | GCS bucket name. |
| storage.gcs.prefix | string | `""` | GCS prefix to use for all stored files. |
| storage.gcs.secretName | string | `""` | Kubernetes secret containing a `credentials.json` (as the secret key) service account key to use instead of the metadata server. |
| storage.s3.accessKeyId | string | `""` | S3 Access Key ID to use instead of the metadata server. |
| storage.s3.bucket | string | `""` | S3 bucket name. |
| storage.s3.forcePathStyle | bool | `false` | S3 Force Path Style setting. See https://docs.aws.amazon.com/sdk-for-java/latest/developer-guide/examples-s3.html. |
| storage.s3.prefix | string | `""` | S3 prefix to use for all stored files. |
| storage.s3.region | string | `""` | S3 bucket region. |
| storage.s3.secretName | string | `""` | Kubernetes secret containing a `secret_access_key` (as the secret key) to use instead of the metadata server. |
| storage.use | string | `"s3"` | Which object storage that bufstream is using. Currently, `gcs` and `s3` are supported. |
| zone | string | `""` | The zone location of brokers, e.g., the datacenter/availability zone where the agent is running. If not given, bustream will try to infer this from node metadata. This is currently for bufstream internal functionality, and does not control cloud providers such as GCP directly. |
