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
{{- if .Values.global.clickhouse.port }}
  {{- .Values.global.clickhouse.port -}}
{{- else -}}
  {{- if .Values.clickhouse.install }}
    {{- print "8123" -}}
  {{- else -}}
    {{- print "8443" -}}
  {{- end -}}
{{- end -}}
{{- end }}