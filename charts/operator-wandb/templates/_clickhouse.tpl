{{- define "wandb.clickhouse.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else  -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Return the clickhouse password
*/}}
{{- define "wandb.clickhouse.password" -}}
{{- if .Values.clickhouse.install -}}
{{ .Values.clickhouse.password }}
{{- else -}}
{{ .Values.global.clickhouse.password }}
{{- end -}}
{{- end -}}

{{/*
Return name of secret where clickhouse information is stored
*/}}
{{- define "wandb.clickhouse.passwordSecret" -}}
{{- if .Values.global.clickhouse.passwordSecret.name }}
  {{- .Values.global.clickhouse.passwordSecret.name -}}
{{- else -}}
  {{- print .Release.Name "-clickhouse" -}}
{{- end -}}
{{- end }}

{{/*
Return name of secret where clickhouse information is stored
*/}}
{{- define "wandb.clickhouse.passwordSecret.passwordKey" -}}
{{- if .Values.global.clickhouse.passwordSecret.name }}
  {{- .Values.global.clickhouse.passwordSecret.passwordKey -}}
{{- else -}}
  CLICKHOUSE_PASSWORD
{{- end -}}
{{- end }}

{{- define "wandb.clickhouse.host" -}}
{{- if eq .Values.clickhouse.install true -}}
{{- printf "%s-ch-headless" (include "wandb.clickhouse.fullname" .) -}}
{{- else -}}
{{ .Values.global.clickhouse.host }}
{{- end -}}
{{- end }}

{{- define "wandb.clickhouse.port " -}}
{{- if eq .Values.clickhouse.install true -}}
{{ .Values.clickhouse.server.httpPort }}
{{- else -}}
{{ .Values.global.clickhouse.port }}
{{- end -}}
{{- end -}}

{{- define "wandb.clickhouse.database " -}}
{{- if eq .Values.clickhouse.install true -}}
{{ .Values.clickhouse.database }}
{{- else -}}
{{ .Values.global.clickhouse.database }}
{{- end -}}
{{- end -}}

{{- define "wandb.clickhouse.user " -}}
{{- if eq .Values.clickhouse.install true -}}
{{- printf "default" -}}
{{- else -}}
{{ .Values.global.clickhouse.database }}
{{- end -}}
{{- end -}}