{{/*
Return the name of the secret where information is stored, considering if the custom secret is defined
*/}}
{{- define "wandb.mysql.passwordSecret" -}}
{{- if .Values.global.mysql.passwordSecret.name }}
  {{- .Values.global.mysql.passwordSecret.name -}}
{{- else }}
  {{- print .Release.Name "-mysql" -}}
{{- end -}}
{{- end -}}

{{/*
Return the key name for the MySQL root password, with a default fallback
*/}}
{{- define "wandb.mysql.rootPasswordKey" -}}
{{- if .Values.global.mysql.passwordSecret.rootPasswordKey }}
  {{- .Values.global.mysql.passwordSecret.rootPasswordKey -}}
{{- else }}
  MYSQL_ROOT_PASSWORD
{{- end -}}
{{- end -}}

{{/*
Return the key name for the MySQL password, with a default fallback
*/}}
{{- define "wandb.mysql.passwordKey" -}}
{{- if .Values.global.mysql.passwordSecret.passwordKey }}
  {{- .Values.global.mysql.passwordSecret.passwordKey -}}
{{- else }}
  MYSQL_PASSWORD
{{- end -}}
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


