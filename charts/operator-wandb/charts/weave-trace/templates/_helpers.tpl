{{/* vim: set filetype=mustache: */}}

{{/*
Expand the name of the chart.
*/}}
{{- define "weaveTrace.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified name for weave-trace. (Should be something like wandb-weave-trace)
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "weaveTrace.fullname" -}}
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
Create a default fully qualified name for the weave-trace migration. (Should be something like wandb-weave-trace-migrate)
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "weaveTraceMigrate.fullname" -}}
{{ printf "%s-migrate" (include "weaveTrace.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified name for the weave-trace migration. (Should be something like wandb-weave-trace-migrate)
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "weaveWorker.fullname" -}}
{{ printf "%s-worker" (include "weaveTrace.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "weaveTrace.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "weaveTrace.labels" -}}
helm.sh/chart: {{ include "weaveTrace.chart" . }}
{{ include "weaveTrace.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
wandb.com/app-name: {{ include "weaveTrace.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "weaveTrace.selectorLabels" -}}
app.kubernetes.io/name: {{ include "weaveTrace.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "weaveTrace.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "weaveTrace.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Returns the extraEnv keys and values to inject into containers.

Global values will override any chart-specific values.
*/}}
{{- define "weaveTrace.extraEnv" -}}
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
{{- define "weaveTrace.commonLabels" -}}
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
{{- define "weaveTrace.podLabels" -}}
{{- range $key, $value := .Values.pod.labels }}
{{ $key }}: {{ $value | quote }}
{{- end }}
{{- end -}}
