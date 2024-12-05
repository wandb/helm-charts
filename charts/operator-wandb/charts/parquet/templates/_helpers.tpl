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

{{- define "parquet.bucket" -}}
{{- $bucketValues := .Values.global.defaultBucket }}
{{- if .Values.global.bucket.provider }}
{{- $bucketValues = .Values.global.bucket }}
{{- end }}
{{- $bucket := "" -}}
{{- if eq $bucketValues.provider "az" -}}
{{- $bucket = printf "az://%s/%s" $bucketValues.name (default "" $bucketValues.path) -}}
{{- end -}}
{{- if eq $bucketValues.provider "gcs" -}}
{{- $bucket = printf "gs://%s/%s" $bucketValues.name (default "" $bucketValues.path) -}}
{{- end -}}
{{- if eq $bucketValues.provider "s3" -}}
{{- if and $bucketValues.accessKey $bucketValues.secretKey -}}
{{- $bucket = printf "s3://%s:%s@%s/%s" $bucketValues.accessKey $bucketValues.secretKey $bucketValues.name (default "" $bucketValues.path) -}}
{{- else -}}
{{- $bucket = printf "s3://%s/%s" $bucketValues.name (default "" $bucketValues.path) -}}
{{- end -}}
{{- end -}}
{{- trimSuffix "/" $bucket -}}
{{- end -}}

{{- define "parquet.historyStore" -}}
    {{- $stores := list -}}
    {{- $stores = append $stores (printf "http://%s-parquet:8087/_goRPC_" .Release.Name) -}}

    {{- if .Values.global.bigtable.v3.enabled -}}
        {{- $stores = append $stores (printf "bigtablev3://%s/%s" .Values.global.bigtable.project .Values.global.bigtable.instance) -}}
    {{- end -}}

    {{- if .Values.global.bigtable.v2.enabled -}}
        {{- $stores = append $stores (printf "bigtablev2://%s/%s" .Values.global.bigtable.project .Values.global.bigtable.instance) -}}
    {{- end -}}

    {{- if not (or .Values.global.bigtable.v2.enabled .Values.global.bigtable.v3.enabled) -}}
        {{- $stores = append $stores "mysql://$(MYSQL_USER):$(MYSQL_PASSWORD)@$(MYSQL_HOST):$(MYSQL_PORT)/$(MYSQL_DATABASE)?tls=preferred" -}}
    {{- end -}}

    {{- join "," $stores -}}
{{- end -}}

{{- define "parquet.liveHistoryStore" -}}
{{- $historyStore := printf "mysql://$(MYSQL_USER):$(MYSQL_PASSWORD)@$(MYSQL_HOST):$(MYSQL_PORT)/$(MYSQL_DATABASE)?tls=preferred" -}}
{{- if or .Values.global.bigtable.v2.enabled .Values.global.bigtable.v3.enabled -}}
  {{- $stores := list -}}

  {{- if .Values.global.bigtable.v3.enabled -}}
    {{- $stores = append $stores (printf "bigtablev3://%s/%s" .Values.global.bigtable.project .Values.global.bigtable.instance) -}}
  {{- end -}}

  {{- if .Values.global.bigtable.v2.enabled -}}
    {{- $stores = append $stores (printf "bigtablev2://%s/%s" .Values.global.bigtable.project .Values.global.bigtable.instance) -}}
  {{- end -}}

  {{- $historyStore = join "," $stores -}}
{{- end -}}
{{- $historyStore -}}
{{- end -}}

{{/* TODO(dpanzella) - Probably need to make this support kafka as well*/}}
{{- define "parquet.fileStreamStore" -}}
{{- if .Values.global.pubSub.enabled -}}
pubsub:/{{ .Values.global.pubSub.project }}/{{ .Values.global.pubSub.filestreamTopic }}
{{- else -}}
mysql://$(MYSQL_USER):$(MYSQL_PASSWORD)@$(MYSQL_HOST):$(MYSQL_PORT)/$(MYSQL_DATABASE)?tls=preferred
{{- end -}}
{{- end -}}

{{- define "parquet.envFrom" -}}
{{- range $key, $value := .Values.envFrom -}}
- {{ $value }}:
    name: {{ $key }}
{{ end }}
{{- end }}

