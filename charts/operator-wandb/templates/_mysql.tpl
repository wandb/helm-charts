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
{{- if and .Values.global.mysql.caCert (ne .Values.global.mysql.caCert "") -}}
{{/* 
TODO: The ssl-ca parameter is currently ignored by the Go MySQL driver.
For proper CA certificate verification, the gorilla application needs to:
1. Check for MYSQL_CA_CERT_PATH environment variable
2. Register a named TLS config using mysql.RegisterTLSConfig()
3. Use tls=wandb-mysql-ca instead of ssl-ca parameter
The certificate is already mounted at /etc/ssl/certs/mysql_ca.pem
*/}}
mysql://$(MYSQL_USER):$(MYSQL_PASSWORD)@$(MYSQL_HOST):$(MYSQL_PORT)/$(MYSQL_DATABASE)?tls=preferred&ssl-ca=/etc/ssl/certs/mysql_ca.pem
{{- else -}}
mysql://$(MYSQL_USER):$(MYSQL_PASSWORD)@$(MYSQL_HOST):$(MYSQL_PORT)/$(MYSQL_DATABASE)?tls=preferred
{{- end -}}
{{- end -}}



