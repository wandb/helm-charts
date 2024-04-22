{{/*
Return the clickhouse client user
*/}}
{{- define "wandb.clickhouse.user" -}}
{{ .Values.global.clickhouse.user }}
{{- end -}}

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
{{- print .Release.Name "-clickhouse" -}}
{{- end -}}

{{/*
Return the redis host
*/}}
{{- define "wandb.clickhouse.host" -}}
{{- if eq .Values.global.clickhouse.host "" -}}
{{- else -}}
{{ .Values.global.clickhouse.host }}
{{- end -}}
{{- end -}}