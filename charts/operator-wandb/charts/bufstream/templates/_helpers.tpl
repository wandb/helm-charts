{{/*
Expand the name of the chart.
*/}}
{{- define "bufstream.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "bufstream.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Helpers to allow overriding the namespace
*/}}

{{- define "bufstream.namespace" -}}
{{- default .Release.Namespace .Values.namespaceOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Helpers to generate application configurations from a base, allowing arbitrary overrides from a value
*/}}

{{- define "bufstream.config-merge" }}
{{- $baseConfig := tpl (.Files.Get .configFile) . | fromYaml -}}
{{- $mergedConfig := mustMergeOverwrite (dict) $baseConfig .configOverrides -}}
{{- toYaml $mergedConfig }}
{{- end -}}

{{- define "bufstream.config" }}
{{ include "bufstream.config-merge" (merge (dict "configFile" "config/bufstream.yaml.tpl" "configOverrides" .Values.configOverrides) .) }}
{{- end -}}

{{/*
Misc helpers for reusable variables
*/}}

{{- define "bufstream.containerPorts" -}}
{{- $bufstreamContainerPorts := dict -}}
{{- $_ := set $bufstreamContainerPorts "connect" 8080 -}}
{{- $_ := set $bufstreamContainerPorts "kafka" 9092 -}}
{{- $_ := set $bufstreamContainerPorts "observability" 9090 -}}
{{- $_ := set $bufstreamContainerPorts "admin" 9089 }}
{{- toYaml $bufstreamContainerPorts -}}
{{- end -}}

{{- define "bufstream.containerPort" -}}
{{ get (include "bufstream.containerPorts" . | fromYaml) . }}
{{- end -}}

{{- define "bufstream.ports" -}}
{{- $bufstreamPorts := dict -}}
{{- $_ := set $bufstreamPorts "connect" 8080 -}}
{{- $_ := set $bufstreamPorts "kafka" 9092 -}}
{{- $_ := set $bufstreamPorts "admin" 9089 -}}
{{- toYaml $bufstreamPorts -}}
{{- end -}}

{{- define "bufstream.controlServerServiceName" -}}
{{- default (printf "%s-ctrl-server-headless" (include "bufstream.name" . )) -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "bufstream.labels" -}}
helm.sh/chart: {{ include "bufstream.chart" . }}
{{ include "bufstream.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "bufstream.selectorLabels" -}}
{{- $baseLabels := dict "app" (include "bufstream.name" .) "app.kubernetes.io/name" (include "bufstream.name" .) "app.kubernetes.io/instance" .Release.Name -}}
{{- $mergedLabels := mustMergeOverwrite (dict) $baseLabels .Values.bufstream.deployment.selectorLabels -}}
{{- toYaml $mergedLabels }}
{{- end }}

{{/*
Renders a complete tree, even values that contains template.
*/}}
{{- define "bufstream.render" -}}
  {{- if typeIs "string" .value }}
    {{- tpl .value .context }}
  {{ else }}
    {{- tpl (.value | toYaml) .context }}
  {{- end }}
{{- end -}}

{{- define "bufstream.observability" }}
observability:
  log_git_version: true
  log_level: {{ .Values.observability.logLevel }}
  {{- if and .Values.observability.exporter.address .Values.observability.otlpEndpoint }}
  {{ fail "cannot set both observability.exporter.address and observability.otlpEndpoint, set only the former instead" }}
  {{- else if coalesce .Values.observability.exporter.address .Values.observability.exporter.insecure }}
  exporter:
    {{- if .Values.observability.exporter.address }}
    address: {{ .Values.observability.exporter.address }}
    {{- end }}
    {{- if .Values.observability.exporter.insecure }}
    insecure: {{ .Values.observability.exporter.insecure }}
    {{- end }}
  {{- end }}
  {{- if .Values.observability.tracing.exporter }}
  trace_exporter: {{ .Values.observability.tracing.exporter }}
  trace_ratio: {{ .Values.observability.tracing.traceRatio }}
  {{- else }}
  traces:
    exporter_type: {{ .Values.observability.tracing.exporterType }}
    {{- if .Values.observability.tracing.address }}
    address: {{ .Values.observability.tracing.address }}
    {{- end }}
    {{- if .Values.observability.tracing.path }}
    path: {{ .Values.observability.tracing.path }}
    {{- end }}
    {{- if .Values.observability.tracing.insecure }}
    insecure: {{ .Values.observability.tracing.insecure }}
    {{- end }}
    trace_ratio: {{ .Values.observability.tracing.traceRatio }}
  {{- end }}
  {{- if .Values.observability.metrics.exporter }}
  metrics_exporter: {{ .Values.observability.metrics.exporter }}
  {{- else }}
  metrics:
    exporter_type: {{ .Values.observability.metrics.exporterType }}
    {{- if .Values.observability.metrics.address }}
    address: {{ .Values.observability.metrics.address }}
    {{- end }}
    {{- if .Values.observability.metrics.path }}
    path: {{ .Values.observability.metrics.path }}
    {{- end }}
    {{- if .Values.observability.metrics.insecure }}
    insecure: {{ .Values.observability.metrics.insecure }}
    {{- end }}
    {{- if .Values.observability.metrics.omitPartitionAttribute }}
    omit_partition_attribute: {{ .Values.observability.metrics.omitPartitionAttribute }}
    {{- end }}
    {{- if .Values.observability.metrics.enableInternalMetrics }}
    enable_internal_metrics: {{ .Values.observability.metrics.enableInternalMetrics }}
    {{- end }}
  {{- end }}
  debug_address:
    host: 0.0.0.0
    port: {{ include "bufstream.containerPort" "observability" }}
  {{- if .Values.observability.sensitiveInformationRedaction }}
  sensitive_information_redaction: {{ .Values.observability.sensitiveInformationRedaction }}
  {{- end }}
{{- end }}
