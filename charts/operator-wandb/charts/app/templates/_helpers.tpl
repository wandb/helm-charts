{{/*
Expand the name of the chart.
*/}}
{{- define "app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "app.fullname" -}}
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
{{- define "app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "app.labels" -}}
helm.sh/chart: {{ include "app.chart" . }}
{{ include "app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
wandb.com/app-name: {{ include "app.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "app.name" . }}{{ .suffix }}
app.kubernetes.io/instance: {{ .Release.Name }}{{ .suffix }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "app.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "app.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Returns the extraEnv keys and values to inject into containers.

Global values will override any chart-specific values.
*/}}
{{- define "app.extraEnv" -}}
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
{{- define "app.commonLabels" -}}
{{- $commonLabels := default (dict) .Values.common.labels -}}
{{- if $commonLabels }}
{{-   range $key, $value := $commonLabels }}
{{ $key }}: {{ $value | trunc 63 | quote }}
{{-   end }}
{{- end -}}
{{- end -}}

{{/*
Returns a list of _pod_ labels to be shared across all
app deployments.
*/}}
{{- define "app.podLabels" -}}
{{- range $key, $value := .Values.pod.labels }}
{{ $key }}: {{ $value | trunc 63 | quote }}
{{- end }}
{{- end -}}

{{- define "app.internalJWTMap" -}}
'{
{{- range $value := .Values.internalJWTMap -}}
{{- if and (not (empty $value.subject)) (not (empty $value.issuer)) }}
{{- printf "%q: %q" $value.subject $value.issuer }},
{{- end -}}
{{- end -}}
}'
{{- end -}}

{{- define "app.runUpdateShadowTopic" -}}
{{- if .Values.global.pubSub.enabled -}}
pubsub:/{{ .Values.global.pubSub.project }}/{{ .Values.global.pubSub.runUpdateShadowTopic }}
{{- else if .Values.global.beta.bufstream.enabled -}}
kafka://$(KAFKA_BROKER_HOST):$(KAFKA_BROKER_PORT)/$(KAFKA_TOPIC_RUN_UPDATE_SHADOW_QUEUE)?producer_batch_bytes=104857600&num_partitions=$(KAFKA_RUN_UPDATE_SHADOW_QUEUE_NUM_PARTITIONS)
{{- else -}}
kafka://$(KAFKA_CLIENT_USER):$(KAFKA_CLIENT_PASSWORD)@$(KAFKA_BROKER_HOST):$(KAFKA_BROKER_PORT)/$(KAFKA_TOPIC_RUN_UPDATE_SHADOW_QUEUE)?producer_batch_bytes=104857600&num_partitions=$(KAFKA_RUN_UPDATE_SHADOW_QUEUE_NUM_PARTITIONS)
{{- end -}}
{{- end -}}

{{- define "app.historyStore" -}}
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

{{- define "app.liveHistoryStore" -}}
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
{{- define "app.fileStreamStore" -}}
{{- if .Values.global.pubSub.enabled -}}
pubsub:/{{ .Values.global.pubSub.project }}/{{ .Values.global.pubSub.filestreamTopic }}
{{- else -}}
mysql://$(MYSQL_USER):$(MYSQL_PASSWORD)@$(MYSQL_HOST):$(MYSQL_PORT)/$(MYSQL_DATABASE)?tls=preferred
{{- end -}}
{{- end -}}

{{- define "app.envFrom" -}}
{{- range $key, $value := .Values.envFrom -}}
- {{ $value }}:
    name: {{ $key }}
{{ end }}
{{- end }}

