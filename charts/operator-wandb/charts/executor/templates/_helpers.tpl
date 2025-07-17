{{/*
Expand the name of the chart.
*/}}
{{- define "executor.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "executor.fullname" -}}
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
{{- define "executor.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "executor.labels" -}}
helm.sh/chart: {{ include "executor.chart" . }}
{{ include "executor.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Returns the extraEnv keys and values to inject into containers.

Global values will override any chart-specific values.
*/}}
{{- define "executor.extraEnv" -}}
{{- $allExtraEnv := merge (default (dict) .local.extraEnv) .global.extraEnv -}}
{{- range $key, $value := $allExtraEnv }}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- end -}}
{{- end -}}

{{/*
Returns a list of _common_ labels to be shared across all
executor deployments and other shared objects.
*/}}
{{- define "executor.commonLabels" -}}
{{- $commonLabels := default (dict) .Values.common.labels -}}
{{- if $commonLabels }}
{{-   range $key, $value := $commonLabels }}
{{ $key }}: {{ $value | quote }}
{{-   end }}
{{- end -}}
{{- end -}}

{{/*
Returns a list of _pod_ labels to be shared across all
executor deployments.
*/}}
{{- define "executor.podLabels" -}}
{{- range $key, $value := .Values.pod.labels }}
{{ $key }}: {{ $value | quote }}
{{- end }}
{{- end -}}
{{/*
Selector labels
*/}}
{{- define "executor.selectorLabels" -}}
app.kubernetes.io/name: {{ include "executor.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "executor.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "executor.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "executor.taskQueue" -}}
{{- $cs := include "wandb.redis.connectionString" . }}
{{- $params := include "wandb.redis.parametersQuery" . }}
{{- $concur := .Values.workerConcurrency }}
{{- if $concur -}}
  {{- if $params }}
    {{- $cs = printf "%s&" $cs -}}
  {{- else }}
    {{- $cs = printf "%s?" $cs -}}
  {{- end }}
  {{- $cs = printf "%sconcurrency=%s" $cs ($concur | toString) -}}
{{- end }}
{{- print $cs }}
{{- end }}

{{- define "executor.historyStore" -}}
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

{{- define "executor.liveHistoryStore" -}}
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
{{- define "executor.fileStreamStore" -}}
{{- if .Values.global.pubSub.enabled -}}
pubsub:/{{ .Values.global.pubSub.project }}/{{ .Values.global.pubSub.filestreamTopic }}
{{- else -}}
mysql://$(MYSQL_USER):$(MYSQL_PASSWORD)@$(MYSQL_HOST):$(MYSQL_PORT)/$(MYSQL_DATABASE)?tls=preferred
{{- end -}}
{{- end -}}

{{- define "executor.runUpdateShadowTopic" -}}
{{- if .Values.global.pubSub.enabled -}}
pubsub:/{{ .Values.global.pubSub.project }}/{{ .Values.global.pubSub.runUpdateShadowTopic }}
{{- else if .Values.global.beta.bufstream.enabled -}}
kafka://$(KAFKA_BROKER_HOST):$(KAFKA_BROKER_PORT)/$(KAFKA_TOPIC_RUN_UPDATE_SHADOW_QUEUE)?producer_batch_bytes=134217728&num_partitions=$(KAFKA_RUN_UPDATE_SHADOW_QUEUE_NUM_PARTITIONS)
{{- else -}}
kafka://$(KAFKA_CLIENT_USER):$(KAFKA_CLIENT_PASSWORD)@$(KAFKA_BROKER_HOST):$(KAFKA_BROKER_PORT)/$(KAFKA_TOPIC_RUN_UPDATE_SHADOW_QUEUE)?producer_batch_bytes=134217728&num_partitions=$(KAFKA_RUN_UPDATE_SHADOW_QUEUE_NUM_PARTITIONS)
{{- end -}}
{{- end -}}

{{- define "executor.envFrom" -}}
{{- range $key, $value := .Values.envFrom -}}
- {{ $value }}:
    name: {{ $key }}
{{ end }}
{{- end }}
