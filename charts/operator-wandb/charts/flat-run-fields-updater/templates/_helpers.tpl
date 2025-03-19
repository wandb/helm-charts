{{/*
Expand the name of the chart.
*/}}
{{- define "flat-run-fields-updater.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "flat-run-fields-updater.fullname" -}}
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
{{- define "flat-run-fields-updater.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "flat-run-fields-updater.labels" -}}
helm.sh/chart: {{ include "flat-run-fields-updater.chart" . }}
{{ include "flat-run-fields-updater.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Returns the extraEnv keys and values to inject into containers.

Global values will override any chart-specific values.
*/}}
{{- define "flat-run-fields-updater.extraEnv" -}}
{{- $allExtraEnv := merge (default (dict) .local.extraEnv) .global.extraEnv -}}
{{- range $key, $value := $allExtraEnv }}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- end -}}
{{- end -}}

{{/*
Returns a list of _common_ labels to be shared across all
flat-run-fields-updater deployments and other shared objects.
*/}}
{{- define "flat-run-fields-updater.commonLabels" -}}
{{- $commonLabels := default (dict) .Values.common.labels -}}
{{- if $commonLabels }}
{{-   range $key, $value := $commonLabels }}
{{ $key }}: {{ $value | quote }}
{{-   end }}
{{- end -}}
{{- end -}}

{{/*
Returns a list of _pod_ labels to be shared across all
flat-run-fields-updater deployments.
*/}}
{{- define "flat-run-fields-updater.podLabels" -}}
{{- range $key, $value := .Values.pod.labels }}
{{ $key }}: {{ $value | quote }}
{{- end }}
{{- end -}}
{{/*
Selector labels
*/}}
{{- define "flat-run-fields-updater.selectorLabels" -}}
app.kubernetes.io/name: {{ include "flat-run-fields-updater.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "flat-run-fields-updater.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "flat-run-fields-updater.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "flat-run-fields-updater.runUpdateShadowQueue" -}}
{{- if .Values.global.pubSub.enabled -}}
pubsub:/{{ .Values.global.pubSub.project }}/{{ .Values.global.pubSub.runUpdateShadowTopic }}/{{ .Values.pubSub.subscription }}
{{- else if .Values.global.beta.bufstream.enabled -}}
kafka://$(KAFKA_BROKER_HOST):9092/$(KAFKA_TOPIC_RUN_UPDATE_SHADOW_QUEUE)?consumer_group_id=default-group&num_partitions=$(KAFKA_RUN_UPDATE_SHADOW_QUEUE_NUM_PARTITIONS)&replication_factor=3
{{- else -}}
kafka://$(KAFKA_CLIENT_USER):$(KAFKA_CLIENT_PASSWORD)@$(KAFKA_BROKER_HOST):9092/$(KAFKA_TOPIC_RUN_UPDATE_SHADOW_QUEUE)?consumer_group_id=default-group&num_partitions=$(KAFKA_RUN_UPDATE_SHADOW_QUEUE_NUM_PARTITIONS)&replication_factor=3
{{- end -}}
{{- end -}}


{{- define "flat-run-fields-updater.envFrom" -}}
{{- range $key, $value := .Values.envFrom -}}
- {{ $value }}:
    name: {{ $key }}
{{ end }}
{{- end }}
