{{/*
Return name of secret where information is stored
*/}}
{{- define "wandb.mysql.passwordSecret" -}}
{{- print .Release.Name "-mysql" -}}
{{- end -}}

{{/*
Return the db port
*/}}
{{- define "wandb.mysql.port" -}}
{{- print $.Values.global.mysql.port -}}
{{- end -}}

{{/*
Return the db host
*/}}
{{- define "wandb.mysql.host" -}}
{{- if eq .Values.global.mysql.host "" -}}
{{ printf "%s-%s" .Release.Name "mysql" }}
{{- else -}}
{{ .Values.global.mysql.host }}
{{- end -}}
{{- end -}}

{{/*
Return the db database
*/}}
{{- define "wandb.mysql.database" -}}
{{- print $.Values.global.mysql.database -}}
{{- end -}}

{{/*
Return the db user
*/}}
{{- define "wandb.mysql.user" -}}
{{- print $.Values.global.mysql.user -}}
{{- end -}}

{{/*
Return the db password
*/}}
{{- define "wandb.mysql.password" -}}
{{- print $.Values.global.mysql.password -}}
{{- end -}}


