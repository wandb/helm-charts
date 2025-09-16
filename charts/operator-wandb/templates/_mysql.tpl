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
mysql://$(MYSQL_USER):$(MYSQL_PASSWORD)@$(MYSQL_HOST):$(MYSQL_PORT)/$(MYSQL_DATABASE)?tls=required&ssl-ca=/etc/ssl/certs/mysql_ca.pem
{{- else -}}
mysql://$(MYSQL_USER):$(MYSQL_PASSWORD)@$(MYSQL_HOST):$(MYSQL_PORT)/$(MYSQL_DATABASE)?tls=preferred
{{- end -}}
{{- end -}}

{{/*
Return the MySQL health check command for init containers
*/}}
{{- define "wandb.mysql.healthCheckCommand" -}}
{{- if and .Values.global.mysql.caCert (ne .Values.global.mysql.caCert "") -}}
until mysql -h$MYSQL_HOST -u$MYSQL_USER -p"$(python -c "import sys; from urllib import parse; print(parse.unquote_plus(sys.argv[1]))" $MYSQL_PASSWORD)" -D$MYSQL_DATABASE -P$MYSQL_PORT --ssl-mode=VERIFY_CA --ssl-ca=/etc/ssl/certs/mysql_ca.pem --execute="SELECT 1"; do echo waiting for db; sleep 2; done
{{- else -}}
until mysql -h$MYSQL_HOST -u$MYSQL_USER -p"$(python -c "import sys; from urllib import parse; print(parse.unquote_plus(sys.argv[1]))" $MYSQL_PASSWORD)" -D$MYSQL_DATABASE -P$MYSQL_PORT --ssl-mode=PREFERRED --execute="SELECT 1"; do echo waiting for db; sleep 2; done
{{- end -}}
{{- end -}}


