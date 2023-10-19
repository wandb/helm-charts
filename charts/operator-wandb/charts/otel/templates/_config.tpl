{{- define "otel.config" -}}
{{- $data := deepCopy .Values.config }}
{{- $config := .Values.config }}
{{- $config = mustMergeOverwrite (include "otel.hostMetricsReceiver" . | fromYaml) $config }}
{{- $config = mustMergeOverwrite (include "otel.logsCollectionReceiver" . | fromYaml) $config }}
{{- $config = mustMergeOverwrite (include "otel.extensions" . | fromYaml) $config }}
{{- $config = mustMergeOverwrite (include "otel.processors" . | fromYaml) $config }}
{{- $config = mustMergeOverwrite (include "otel.service" . | fromYaml) $config }}
{{- $config = mustMergeOverwrite (include "otel.exporter" . | fromYaml) $config }}
{{- tpl (toYaml $config) . }}
{{- end }}

{{- define "otel.exporter" -}}
exporters:
  debug: {}
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
{{- end }}

{{- define "otel.service" -}}
service:
  extensions:
  - health_check
  - memory_ballast
  pipelines:
    metrics:
      exporters: [debug]
      processors: [memory_limiter, batch]
      receivers: [hostmetrics]
    logs:
      exporters: [debug]
      processors: [memory_limiter, batch]
      receivers: [filelog]
  telemetry:
    metrics:
      address: ${env:POD_IP}:8888
{{- end }}