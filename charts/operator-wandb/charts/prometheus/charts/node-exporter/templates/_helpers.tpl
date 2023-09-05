{{/* vim: set filetype=mustache: */}}

{{/*
Expand the name of the chart.
*/}}
{{- define "node-exporter.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "node-exporter.fullname" -}}
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
{{- define "node-exporter.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "node-exporter.labels" -}}
helm.sh/chart: {{ include "node-exporter.chart" . }}
{{ include "node-exporter.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
wandb.com/app-name: {{ include "node-exporter.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "node-exporter.selectorLabels" -}}
app.kubernetes.io/name: {{ include "node-exporter.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "node-exporter.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "node-exporter.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Returns the extraEnv keys and values to inject into containers.

Global values will override any chart-specific values.
*/}}
{{- define "node-exporter.extraEnv" -}}
{{- $allExtraEnv := merge (default (dict) .local.extraEnv) .global.extraEnv -}}
{{- range $key, $value := $allExtraEnv }}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- end -}}
{{- end -}}

{{/*
Returns a list of _common_ labels to be shared across all
app deployments and other shared objects.
*/}}
{{- define "node-exporter.commonLabels" -}}
{{- $commonLabels := default (dict) .Values.common.labels -}}
{{- if $commonLabels }}
{{-   range $key, $value := $commonLabels }}
{{ $key }}: {{ $value | quote }}
{{-   end }}
{{- end -}}
{{- end -}}

{{/*
Returns a list of _pod_ labels to be shared across all
app deployments.
*/}}
{{- define "node-exporter.podLabels" -}}
{{- range $key, $value := .Values.pod.labels }}
{{ $key }}: {{ $value | quote }}
{{- end }}
{{- end -}}

{{- define "node-exporter.redis" -}}
{{- $cs := include "wandb.redis.connectionString" . }}
{{- $ca := include "wandb.redis.caCert" . }}
{{- if $ca }}
{{- printf "%s?tls=true&caCertPath=/etc/ssl/certs/redis_ca.pem&ttlInSeconds=604800" $cs -}}
{{- else }}
{{- print $cs -}}
{{- end }}
{{- end }}

{{- define "node-exporter.bucket" -}}
{{- if eq .Values.global.bucket.provider "az" }}
{{- printf "az://%s/%s" .Values.global.bucket.name .Values.global.bucket.path -}}
{{- end }}
{{- if eq .Values.global.bucket.provider "gcs" }}
{{- printf "gs://%s" .Values.global.bucket.name -}}
{{- end }}
{{- if eq .Values.global.bucket.provider "s3" }}
{{- printf "s3://%s" .Values.global.bucket.name -}}
{{- end }}
{{- end }}
