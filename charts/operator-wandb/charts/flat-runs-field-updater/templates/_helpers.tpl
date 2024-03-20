{{/*
Expand the name of the chart.
*/}}
{{- define "flat-runs-field-updater.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "flat-runs-field-updater.fullname" -}}
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
{{- define "flat-runs-field-updater.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "flat-runs-field-updater.labels" -}}
helm.sh/chart: {{ include "flat-runs-field-updater.chart" . }}
{{ include "flat-runs-field-updater.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Returns the extraEnv keys and values to inject into containers.

Global values will override any chart-specific values.
*/}}
{{- define "flat-runs-field-updater.extraEnv" -}}
{{- $allExtraEnv := merge (default (dict) .local.extraEnv) .global.extraEnv -}}
{{- range $key, $value := $allExtraEnv }}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- end -}}
{{- end -}}

{{/*
Returns a list of _common_ labels to be shared across all
flat-runs-field-updater deployments and other shared objects.
*/}}
{{- define "flat-runs-field-updater.commonLabels" -}}
{{- $commonLabels := default (dict) .Values.common.labels -}}
{{- if $commonLabels }}
{{-   range $key, $value := $commonLabels }}
{{ $key }}: {{ $value | quote }}
{{-   end }}
{{- end -}}
{{- end -}}

{{/*
Returns a list of _pod_ labels to be shared across all
flat-runs-field-updater deployments.
*/}}
{{- define "flat-runs-field-updater.podLabels" -}}
{{- range $key, $value := .Values.pod.labels }}
{{ $key }}: {{ $value | quote }}
{{- end }}
{{- end -}}


{{/*
Selector labels
*/}}
{{- define "flat-runs-field-updater.selectorLabels" -}}
app.kubernetes.io/name: {{ include "flat-runs-field-updater.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "flat-runs-field-updater.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "flat-runs-field-updater.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "flat-runs-field-updater.bucket" -}}
{{- $bucket := "" -}} 
{{- if eq .Values.global.bucket.provider "az" -}}
{{- $bucket = printf "az://%s/%s" .Values.global.bucket.name .Values.global.bucket.path -}}
{{- end -}}
{{- if eq .Values.global.bucket.provider "gcs" -}}
{{- $bucket = printf "gs://%s" .Values.global.bucket.name -}}
{{- end -}}
{{- if eq .Values.global.bucket.provider "s3" -}}
{{- if and .Values.global.bucket.accessKey .Values.global.bucket.secretKey -}}
{{- $bucket = printf "s3://%s:%s@%s/%s" .Values.global.bucket.accessKey .Values.global.bucket.secretKey .Values.global.bucket.name .Values.global.bucket.path -}}
{{- else -}}
{{- $bucket = printf "s3://%s/%s" .Values.global.bucket.name .Values.global.bucket.path -}}
{{- end -}}
{{- end -}}
{{- trimSuffix "/" $bucket -}}
{{- end -}}