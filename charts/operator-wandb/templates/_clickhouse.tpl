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
