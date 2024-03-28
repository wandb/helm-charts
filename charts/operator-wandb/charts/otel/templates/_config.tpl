{{- define "otel.config" -}}
{{- $data := deepCopy .Values.config }}
{{- $config := .Values.config }}
{{- $config = mustMergeOverwrite (include "otel.hostMetricsReceiver" . | fromYaml) $config }}
{{- $config = mustMergeOverwrite (include "otel.logsCollectionReceiver" . | fromYaml) $config }}
{{- $config = mustMergeOverwrite (include "otel.kubeletMetricsReceiver" . | fromYaml) $config }}
{{- $config = mustMergeOverwrite (include "otel.kubernetesEventReceiver" . | fromYaml) $config }}
{{- $config = mustMergeOverwrite (include "otel.kubernetesClusterReceiver" . | fromYaml) $config }}
{{- $config = mustMergeOverwrite (include "otel.otlpReceiver" . | fromYaml) $config }}
{{- $config = mustMergeOverwrite (include "otel.extensions" . | fromYaml) $config }}
{{- $config = mustMergeOverwrite (include "otel.processors" . | fromYaml) $config }}
{{- $config = mustMergeOverwrite (include "otel.service" . | fromYaml) $config }}
{{- $config = mustMergeOverwrite (include "otel.exporter" . | fromYaml) $config }}
{{- tpl (toYaml $config) . }}
{{- end }}

{{- define "otel.exporter" -}}
exporters:
  debug: {}
  debug/detailed:
    verbosity: detailed
  prometheus:
    endpoint: 0.0.0.0:9109
{{- end }}

{{- define "otel.extensions" -}}
extensions:
  health_check: {}
  memory_ballast:
    size_in_percentage: 40
{{- end }}

{{- define "otel.processors" -}}
processors:
  batch: {}
  memory_limiter:
    check_interval: 5s
    limit_percentage: 80
    spike_limit_percentage: 25
  k8sattributes:
    filter:
      node_from_env_var: K8S_NODE_NAME
    passthrough: false
    pod_association:
    - sources:
      - from: resource_attribute
        name: k8s.pod.ip
    - sources:
      - from: resource_attribute
        name: k8s.pod.uid
    - sources:
      - from: connection
    extract:
      metadata:
        - "k8s.namespace.name"
        - "k8s.deployment.name"
        - "k8s.statefulset.name"
        - "k8s.daemonset.name"
        - "k8s.cronjob.name"
        - "k8s.job.name"
        - "k8s.node.name"
        - "k8s.pod.name"
        - "k8s.pod.uid"
        - "k8s.pod.start_time"
      annotations:
        - tag_name: $$1
          key_regex: (.*)
          from: pod
      labels:
        - tag_name: $$1
          key_regex: (.*)
          from: pod
{{- end }}

{{- define "otel.service" -}}
service:
  extensions:
  - health_check
  - memory_ballast
  pipelines:
    metrics:
      exporters: [debug, prometheus]
      processors: [memory_limiter, batch, k8sattributes]
      receivers: [hostmetrics, k8s_cluster, kubeletstats]
    logs:
      exporters: [debug]
      processors: [memory_limiter, batch]
      receivers: [filelog]
  telemetry:
    metrics:
      address: ${env:POD_IP}:8888
{{- end }}