{{/*
Return the kafka client password
*/}}
{{- define "wandb.clickhouse.password" -}}
{{ .Values.global.clickhouse.password }}
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
Return the redis host
*/}}
{{- define "wandb.clickhouse.host" -}}
{{- if eq .Values.global.clickhouse.host "" -}}
{{- else -}}
{{ .Values.global.clickhouse.host }}
{{- end -}}
{{- end -}}