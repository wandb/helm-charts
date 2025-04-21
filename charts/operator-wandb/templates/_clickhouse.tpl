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
Return name of secret where clickhouse information is stored
*/}}
{{- define "wandb.clickhouse.passwordSecret.passwordKey" -}}
{{- if .Values.global.clickhouse.passwordSecret.name }}
  {{- .Values.global.clickhouse.passwordSecret.passwordKey -}}
{{- else -}}
  CLICKHOUSE_PASSWORD
{{- end -}}
{{- end }}

{{/*
Return the redis host
*/}}
{{- define "wandb.clickhouse.host" -}}
{{- if eq .Values.global.clickhouse.host "" -}}
{{- else -}}
{{ tpl .Values.global.clickhouse.host . }}
{{- end -}}
{{- end -}}