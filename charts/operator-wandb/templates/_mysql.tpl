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
TODO: In the future there might a ssl key+crt w/o CA or just a CA.
*/}}
{{- define "wandb.mysql" -}}
  {{- print "mysql://$(MYSQL_USER):$(MYSQL_PASSWORD)@$(MYSQL_HOST):$(MYSQL_PORT)/$(MYSQL_DATABASE)?" -}}
  {{- if .Values.global.mysql.tlsSecret.name }}
    {{- print "tls=custom" -}}
    {{- print "&ssl-cert=/etc/ssl/certs/mysql/tls.crt" -}}
    {{- print "&ssl-key=/etc/ssl/certs/mysql/tls.key" -}}
    {{- print "&ssl-ca=/etc/ssl/certs/mysql/ca.crt" -}}
  {{- else -}}
    {{- print "tls=preferred" -}}
  {{- end -}}
{{- end -}}

{{- define "wandb.waitForMySQL" -}}
{{- print "until mysql " -}}
{{- print "-h$MYSQL_HOST -u$MYSQL_USER -p$MYSQL_PASSWORD -D$MYSQL_DATABASE -P$MYSQL_PORT " -}}
  {{- if .Values.global.mysql.tlsSecret.name }}
    {{- print "--ssl-cert=/etc/ssl/certs/mysql/tls.crt " -}}
    {{- print "--ssl-key=/etc/ssl/certs/mysql/tls.key " -}}
    {{- print "--ssl-ca=/etc/ssl/certs/mysql/ca.crt " -}}
  {{- end }}
{{- print "--execute=\"SELECT 1\"; " -}}
{{- print "do echo waiting for db; sleep 2; done" -}}
{{- end -}}

{{- define "wandb.mysql.volumeMount" -}}
{{- if ne .Values.global.mysql.tlsSecret.name "" -}}
- name: mysql-certs
  mountPath: /etc/ssl/certs/mysql/
  readOnly: true
{{- end }}
{{- end -}}

{{- define "wandb.mysql.volume" -}}
{{- if ne .Values.global.mysql.tlsSecret.name "" -}}
- name: mysql-certs
  secret:
    secretName: {{ .Values.global.mysql.tlsSecret.name }}
    optional: true
    items:
      - key: {{ .Values.global.mysql.tlsSecret.keyKeyName }}
        path: tls.key
      - key: {{ .Values.global.mysql.tlsSecret.crtKeyName }}
        path: tls.crt
      - key: {{ .Values.global.mysql.tlsSecret.caKeyName }}
        path: ca.crt
{{- end -}}
{{- end -}}
