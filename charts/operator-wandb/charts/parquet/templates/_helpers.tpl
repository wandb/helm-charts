{{/* vim: set filetype=mustache: */}}

{{/*
Expand the name of the chart.
*/}}
{{- define "parquet.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "parquet.fullname" -}}
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

{{- define "parquet.redis" -}}
{{- $cs := include "wandb.redis.connectionString" . }}
{{- $ca := include "wandb.redis.caCert" . }}
{{- if $ca }}
{{- printf "%s?tls=true&caCertPath=/etc/ssl/certs/redis_ca.pem&ttlInSeconds=604800" $cs -}}
{{- else }}
{{- print $cs -}}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "parquet.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "parquet.labels" -}}
helm.sh/chart: {{ include "parquet.chart" . }}
{{ include "parquet.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
wandb.com/app-name: {{ include "parquet.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "parquet.selectorLabels" -}}
app.kubernetes.io/name: {{ include "parquet.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "parquet.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "parquet.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Returns the extraEnv keys and values to inject into containers.

Global values will override any chart-specific values.
*/}}
{{- define "parquet.extraEnv" -}}
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
{{- define "parquet.commonLabels" -}}
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
{{- define "parquet.podLabels" -}}
{{- range $key, $value := .Values.pod.labels }}
{{ $key }}: {{ $value | quote }}
{{- end }}
{{- end -}}


{{- define "parquet.historyStore" -}}
{{- $historyStore := printf "http://%s-parquet:8087/_goRPC_" .Release.Name -}}
{{- if .Values.global.bigTable.enabled -}}
{{- $historyStore = printf "%s,bigtablev3://%s/%s,bigtablev2://%s/%s" $historyStore .Values.global.bigTable.project .Values.global.bigTable.instance .Values.global.bigTable.project .Values.global.bigTable.instance -}}
{{- else -}}
{{- $historyStore = printf "%s,mysql://$(MYSQL_USER):$(MYSQL_PASSWORD)@$(MYSQL_HOST):$(MYSQL_PORT)/$(MYSQL_DATABASE)?tls=preferred" $historyStore -}}
{{- end -}}
{{- $historyStore -}}
{{- end -}}

{{- define "parquet.liveHistoryStore" -}}
{{- if .Values.global.bigTable.enabled -}}
{{- printf "bigtablev3://%s/%s,bigtablev2://%s/%s" .Values.global.bigTable.project .Values.global.bigTable.instance .Values.global.bigTable.project .Values.global.bigTable.instance -}}
{{- end -}}
mysql://$(MYSQL_USER):$(MYSQL_PASSWORD)@$(MYSQL_HOST):$(MYSQL_PORT)/$(MYSQL_DATABASE)?tls=preferred
{{- end -}}

{{/* TODO(dpanzella) - Probably need to make this support kafka as well*/}}
{{- define "parquet.fileStreamStore" -}}
{{- if .Values.global.pubSub.enabled -}}
pubsub:/{{ .Values.global.pubSub.project }}/{{ .Values.global.pubSub.filestreamTopic }}
{{- else -}}
mysql://$(MYSQL_USER):$(MYSQL_PASSWORD)@$(MYSQL_HOST):$(MYSQL_PORT)/$(MYSQL_DATABASE)?tls=preferred
{{- end -}}
{{- end -}}
