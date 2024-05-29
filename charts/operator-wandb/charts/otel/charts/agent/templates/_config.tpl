{{- define "otelAgent.config" -}}
{{- $data := deepCopy .Values.config }}
{{- $config := .Values.config }}
{{- if .Values.presets.receivers.hostMetrics }}
{{- $config = mustMergeOverwrite (include "otelAgent.hostMetricsReceiver" . | fromYaml) $config }}
{{- end }}
{{- if .Values.presets.receivers.logsCollection }}
{{- $config = mustMergeOverwrite (include "otelAgent.logsCollectionReceiver" . | fromYaml) $config }}
{{- end }}
{{- if .Values.presets.receivers.kubeletMetrics }}
{{- $config = mustMergeOverwrite (include "otelAgent.kubeletMetricsReceiver" . | fromYaml) $config }}
{{- end }}
{{- if .Values.presets.receivers.kubernetesEvent }}
{{- $config = mustMergeOverwrite (include "otelAgent.kubernetesEventReceiver" . | fromYaml) $config }}
{{- end }}
{{- if .Values.presets.receivers.kubernetesCluster }}
{{- $config = mustMergeOverwrite (include "otelAgent.kubernetesClusterReceiver" . | fromYaml) $config }}
{{- end }}
{{- if .Values.presets.receivers.statsd }}
{{- $config = mustMergeOverwrite (include "otelAgent.statsdReceiver" . | fromYaml) $config }}
{{- end }}
{{- if .Values.presets.receivers.otlp }}
{{- $config = mustMergeOverwrite (include "otelAgent.otlpReceiver" . | fromYaml) $config }}
{{- end }}
{{- if .Values.presets.receivers.azuremonitor }}
{{- $config = mustMergeOverwrite (include "otelAgent.azuremonitorReceiver" . | fromYaml) $config }}
{{- end }}
{{- $config = mustMergeOverwrite (include "otelAgent.extensions" . | fromYaml) $config }}
{{- $config = mustMergeOverwrite (include "otelAgent.processors" . | fromYaml) $config }}
{{- $config = mustMergeOverwrite (include "otelAgent.service" . | fromYaml) $config }}
{{- $config = mustMergeOverwrite (include "otelAgent.exporter" . | fromYaml) $config }}
{{- tpl (toYaml $config) . }}
{{- end }}

{{- define "otelAgent.exporter" -}}
exporters:
  debug: {}
  debug/detailed:
    verbosity: detailed
  prometheus:
    endpoint: 0.0.0.0:9109
{{- end }}

{{- define "otelAgent.extensions" -}}
extensions:
  health_check: {}
  memory_ballast:
    size_in_percentage: 40
{{- end }}

{{- define "otelAgent.processors" -}}
processors:
  batch: {}
  attributes: {}
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

{{- define "otelAgent.service" -}}
service:
  extensions:
  - health_check
  - memory_ballast
  pipelines: {}
  telemetry:
    metrics:
      address: ${env:POD_IP}:8888
{{- end }}