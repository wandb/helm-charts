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

{{/*
Return the db connection string
*/}}
{{- define "wandb.mysql" -}}
  {{- print "mysql://$(MYSQL_USER):$(MYSQL_PASSWORD)@$(MYSQL_HOST):$(MYSQL_PORT)/$(MYSQL_DATABASE)?" -}}
  {{- if .Values.global.mysql.tlsSecret.name }}
    {{- print "tls=custom&ssl-cert=/tbd/tls.crt&ssl-key=/tbd/tls.key" -}}
    {{- $secretObj := (lookup "v1" "Secret" .Release.Namespace .Values.global.mysql.tlsSecret.name) | default dict }}
    {{- $ca := (get $secretObj .Values.global.mysql.tlsSecret.caKeyName) }}
    {{- if $ca }}
      {{- print "&ssl-ca=/tbd/ca.crt" -}}
    {{- end }}
  {{- else -}}
    {{- print "tls=preferred" -}}
  {{- end -}}
{{- end -}}


