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

{{- define "wandb.clickhouse.host" -}}
  {{- tpl .Values.global.clickhouse.host . -}}
{{- end }}

{{- define "wandb.clickhouse.port" -}}
{{- print $.Values.global.clickhouse.port -}}
{{- end }}

{{/*
Return the database name
*/}}
{{- define "wandb.clickhouse.database" -}}
{{- print $.Values.global.clickhouse.database -}}
{{- end -}}

{{/*
Return the database user
*/}}
{{- define "wandb.clickhouse.user" -}}
  {{- if kindIs "map" $.Values.global.clickhouse.user -}}
    {{- print "default" -}}
  {{- else -}}
    {{- print $.Values.global.clickhouse.user -}}
  {{- end -}}
{{- end -}}

{{/*
Return the database password
*/}}
{{- define "wandb.clickhouse.password" -}}
{{- print $.Values.global.clickhouse.password -}}
{{- end -}}
