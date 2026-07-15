{{- define "otel.config" -}}
{{- $data := deepCopy .Values.config }}
{{- $config := .Values.config }}
{{- if .Values.presets.receivers.hostMetrics }}
{{- $config = mustMergeOverwrite (include "otel.hostMetricsReceiver" . | fromYaml) $config }}
{{- end }}
{{- if .Values.presets.receivers.logsCollection }}
{{- $config = mustMergeOverwrite (include "otel.logsCollectionReceiver" . | fromYaml) $config }}
{{- end }}
{{- if .Values.presets.receivers.kubeletMetrics }}
{{- $config = mustMergeOverwrite (include "otel.kubeletMetricsReceiver" . | fromYaml) $config }}
{{- end }}
{{- if .Values.presets.receivers.kubernetesEvent }}
{{- $config = mustMergeOverwrite (include "otel.kubernetesEventReceiver" . | fromYaml) $config }}
{{- end }}
{{- if .Values.presets.receivers.kubernetesCluster }}
{{- $config = mustMergeOverwrite (include "otel.kubernetesClusterReceiver" . | fromYaml) $config }}
{{- end }}
{{- if .Values.presets.receivers.statsd }}
{{- $config = mustMergeOverwrite (include "otel.statsdReceiver" . | fromYaml) $config }}
{{- end }}
{{- if .Values.presets.receivers.otlp }}
{{- $config = mustMergeOverwrite (include "otel.otlpReceiver" . | fromYaml) $config }}
{{- end }}
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
  {{- if .Values.presets.receivers.kubernetesCluster }}
  k8s_leader_elector:
    auth_type: serviceAccount
    lease_name: {{ include "otel.fullname" . }}-leader
    lease_namespace: {{ .Release.Namespace }}
  {{- end }}
{{- end }}

{{- define "otel.processors" -}}
processors:
  batch: {}
  memory_limiter:
    check_interval: 5s
    limit_percentage: 80
    spike_limit_percentage: 25
  k8sattributes:
    {{- if ne (default "DaemonSet" .Values.workload.kind) "Deployment" }}
    filter:
      node_from_env_var: K8S_NODE_NAME
    {{- end }}
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
  {{- if .Values.presets.receivers.kubernetesCluster }}
  - k8s_leader_elector
  {{- end }}
  pipelines: {}
  telemetry:
    metrics:
      address: ${env:POD_IP}:8888
{{- end }}