{{- define "wandb.clickhouse.fullname" -}}
{{- if .Values.fullnameOverride }}
  {{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else -}}
  {{- .Release.Name | trunc 63 | trimSuffix "-" }}-clickhouse
{{- end }}
{{- end }}

{{- define "wandb.clickhouse.host" -}}
{{- if .Values.global.clickhouse.external -}}
  {{- .Values.global.clickhouse.host | default "default-host" -}}
{{- else -}}
  {{- include "wandb.clickhouse.fullname" . }}-ch-server-headless.{{ .Release.Namespace }}.svc.cluster.local
{{- end }}
{{- end }}

{{/*
Return name of secret where ClickHouse information is stored
*/}}
{{- define "wandb.clickhouse.passwordSecret" -}}
{{- if .Values.global.clickhouse.passwordSecret.name -}}
  {{- .Values.global.clickhouse.passwordSecret.name -}}
{{- else -}}
  {{- printf "%s-clickhouse" .Release.Name -}}
{{- end -}}
{{- end -}}

{{/*
Return name of secret where ClickHouse information is stored
*/}}
{{- define "wandb.clickhouse.passwordSecret.passwordKey" -}}
{{- if .Values.global.clickhouse.passwordSecret.name }}
  {{- .Values.global.clickhouse.passwordSecret.passwordKey | default "default" -}}
{{- else -}}
  CLICKHOUSE_PASSWORD
{{- end -}}
{{- end }}


{{- define "wandb.clickhouse.port" -}}
{{- if .Values.global.clickhouse.external -}}
  {{- .Values.global.clickhouse.port | default 8123 -}}
{{- else -}}
  8123
{{- end -}}
{{- end -}}


{{- define "wandb.clickhouse.database" -}}
{{- if .Values.global.clickhouse.external -}}
  {{- .Values.global.clickhouse.database | default "weave_trace_db" -}}
{{- else -}}
  weave_trace_db
{{- end -}}
{{- end -}}


{{- define "wandb.clickhouse.user" -}}
{{- if .Values.global.clickhouse.external -}}
  {{- .Values.global.clickhouse.user | default "default" -}}
{{- else -}}
  default
{{- end -}}
{{- end -}}


{{- define "wandb.clickhouse.password" -}}
{{- if .Values.global.clickhouse.external -}}
  {{- .Values.global.clickhouse.password | default "default" -}}
{{- else -}}
  default
{{- end -}}
{{- end -}}
