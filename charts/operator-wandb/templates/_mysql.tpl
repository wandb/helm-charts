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
Return the db connection string with TLS support
*/}}
{{- define "wandb.mysql" -}}
  {{- $tlsConfig := .Values.global.mysql.tls -}}
  {{- $baseUrl := "mysql://$(MYSQL_USER):$(A_MYSQL_PASSWORD)@$(MYSQL_HOST):$(MYSQL_PORT)/$(MYSQL_DATABASE)?" -}}
  {{- if $tlsConfig.secret.name -}}
    {{- $mode := $tlsConfig.mode | default "required" -}}
    {{- if and $tlsConfig.secret.keys.cert $tlsConfig.secret.keys.key -}}
      {{- print $baseUrl "tls=custom" -}}
      {{- print "&ssl-cert=/etc/ssl/certs/mysql/" $tlsConfig.secret.keys.cert -}}
      {{- print "&ssl-key=/etc/ssl/certs/mysql/" $tlsConfig.secret.keys.key -}}
      {{- if $tlsConfig.secret.keys.ca -}}
        {{- print "&ssl-ca=/etc/ssl/certs/mysql/" $tlsConfig.secret.keys.ca -}}
      {{- end -}}
    {{- else if $tlsConfig.secret.keys.ca -}}
      {{- print $baseUrl "tls=" $mode -}}
      {{- print "&ssl-ca=/etc/ssl/certs/mysql/" $tlsConfig.secret.keys.ca -}}
    {{- else -}}
      {{- print $baseUrl "tls=" $mode -}}
    {{- end -}}
  {{- else -}}
    {{- $mode := $tlsConfig.mode | default "preferred" -}}
    {{- print $baseUrl "tls=" $mode -}}
  {{- end -}}
{{- end -}}

{{/*
Return the MySQL wait command with TLS support
*/}}
{{- define "wandb.waitForMySQL" -}}
  {{- $tlsConfig := .Values.global.mysql.tls -}}
  {{- $baseCmd := "until mysql -h$MYSQL_HOST -u$MYSQL_USER -p$MYSQL_PASSWORD -D$MYSQL_DATABASE -P$MYSQL_PORT" -}}
  {{- if $tlsConfig.secret.name -}}
    {{- if and $tlsConfig.secret.keys.cert $tlsConfig.secret.keys.key -}}
      {{- print $baseCmd " --ssl-cert=/etc/ssl/certs/mysql/" $tlsConfig.secret.keys.cert -}}
      {{- print " --ssl-key=/etc/ssl/certs/mysql/" $tlsConfig.secret.keys.key -}}
      {{- if $tlsConfig.secret.keys.ca -}}
        {{- print " --ssl-ca=/etc/ssl/certs/mysql/" $tlsConfig.secret.keys.ca -}}
      {{- end -}}
    {{- else if $tlsConfig.secret.keys.ca -}}
      {{- print $baseCmd " --ssl-ca=/etc/ssl/certs/mysql/" $tlsConfig.secret.keys.ca -}}
    {{- else -}}
      {{- print $baseCmd -}}
    {{- end -}}
  {{- else -}}
    {{- print $baseCmd -}}
  {{- end -}}
  {{- print " --execute=\"SELECT 1\"; do echo waiting for db; sleep 2; done" -}}
{{- end -}}

{{/*
Return the MySQL TLS volume mount configuration
*/}}
{{- define "wandb.mysql.volumeMount" -}}
  {{- $tlsConfig := .Values.global.mysql.tls -}}
  {{- if $tlsConfig.secret.name -}}
    {{- if or (and $tlsConfig.secret.keys.cert $tlsConfig.secret.keys.key) $tlsConfig.secret.keys.ca -}}
- name: mysql-certs
  mountPath: /etc/ssl/certs/mysql/
  readOnly: true
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
Return the MySQL TLS volume configuration
*/}}
{{- define "wandb.mysql.volume" -}}
  {{- $tlsConfig := .Values.global.mysql.tls -}}
  {{- if $tlsConfig.secret.name -}}
    {{- if or (and $tlsConfig.secret.keys.cert $tlsConfig.secret.keys.key) $tlsConfig.secret.keys.ca -}}
- name: mysql-certs
  secret:
    secretName: {{ $tlsConfig.secret.name }}
    optional: true
    items:
      {{- if $tlsConfig.secret.keys.ca }}
      - key: {{ $tlsConfig.secret.keys.ca }}
        path: {{ $tlsConfig.secret.keys.ca }}
      {{- end }}
      {{- if $tlsConfig.secret.keys.cert }}
      - key: {{ $tlsConfig.secret.keys.cert }}
        path: {{ $tlsConfig.secret.keys.cert }}
      {{- end }}
      {{- if $tlsConfig.secret.keys.key }}
      - key: {{ $tlsConfig.secret.keys.key }}
        path: {{ $tlsConfig.secret.keys.key }}
      {{- end }}
    {{- end -}}
  {{- end -}}
{{- end -}}


