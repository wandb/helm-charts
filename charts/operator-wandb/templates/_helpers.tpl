{{/*
Expand the name of the chart.
*/}}
{{- define "wandb.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "wandb.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "wandb.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "wandb.labels" -}}
helm.sh/chart: {{ include "wandb.chart" . }}
{{ include "wandb.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "wandb.selectorLabels" -}}
app.kubernetes.io/name: {{ include "wandb.name" . }}{{ .suffix }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "wandb.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "wandb.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Return the endpoint to send otel traces to (only works when called within a subchart or traceRatio will not be present)
*/}}
{{- define "wandb.otelTracesEndpoint" -}}
{{- if .Values.global.otel.traces.host -}}
otlp+{{ .Values.global.otel.traces.proto }}://{{ .Values.global.otel.traces.host }}:{{ .Values.global.otel.traces.port }}?trace_ratio={{ default 0.0 .Values.traceRatio }}
{{- else -}}
otlp+{{ .Values.global.otel.traces.proto }}://{{ .Release.Name }}-otel-daemonset:{{ .Values.global.otel.traces.port }}?trace_ratio={{ default 0.0 .Values.traceRatio }}
{{- end -}}
{{- end -}}

{{- define "wandb.internalJWTMap" -}}
'{
{{- $items := list -}}
{{- range $value := .Values.app.internalJWTMap -}}
{{- if and (not (empty $value.subject)) (not (empty $value.issuer)) }}
{{- $items = append $items (printf "%q: %q" $value.subject $value.issuer) -}}
{{- end -}}
{{- end -}}
{{- join ", " $items -}}
}'
{{- end -}}