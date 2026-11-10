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
  determine the name of the mysql cert.
*/}}
{{- define "wandb.mysql.certFileName" -}}
  {{- if kindIs "map" $.Values.global.mysql.caCert -}}
    {{- if $.Values.global.mysql.caCert.valueFrom.secretKeyRef -}}
      {{/* Passed a secret */}}
    {{- print $.Values.global.mysql.caCert.valueFrom.secretKeyRef.key -}}
    {{- else if $.Values.global.mysql.caCert.valueFrom.configMapKeyRef -}}
      {{/* Passed a configmap */}}
    {{- print $.Values.global.mysql.caCert.valueFrom.configMapKeyRef.key -}}
    {{- else -}}
      {{/* Invalid */}}
      {{ fail "Invalid config for 'global.mysql.caCert'" }}
    {{- end -}}
  {{- else -}}
    {{/* Passed value directly */}}
  {{- print "mysql_ca.pem" -}}
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
  {{- if kindIs "map" $.Values.global.mysql.user -}}
    {{- print "wandb" -}}
  {{- else -}}
    {{- print $.Values.global.mysql.user -}}
  {{- end -}}
{{- end -}}

{{/*
MYSQL_PASSWORD env entry: from global.mysql.fromSecret, an inline valueFrom
map, or the password Secret.
*/}}
{{- define "wandb.mysql.passwordEnv" -}}
- name: MYSQL_PASSWORD
  {{- if .Values.global.mysql.fromSecret }}
  value: ""
  valueFrom:
    secretKeyRef:
      name: {{ .Values.global.mysql.fromSecret | quote }}
      key: "password"
  {{- else if kindIs "map" .Values.global.mysql.password }}
    {{- toYaml .Values.global.mysql.password | nindent 2 }}
  {{- else }}
  valueFrom:
    secretKeyRef:
      name: {{ include "wandb.mysql.passwordSecret" . | quote}}
      key: "{{ .Values.global.mysql.passwordSecret.passwordKey }}"
  {{- end }}
{{- end -}}

{{/*
Env entry for one global.mysql setting: from global.mysql.fromSecret, an
inline valueFrom map, or the plain value.
Usage: dict "root" . "name" "MYSQL_HOST" "key" "host"
*/}}
{{- define "wandb.mysql.settingEnv" -}}
  {{- $mysql := .root.Values.global.mysql -}}
  {{- $setting := get $mysql .key -}}
- name: {{ .name }}
  {{- if $mysql.fromSecret }}
    {{/* Clear the previous inline CR value when switching to the Secret. */}}
  value: ""
  valueFrom:
    secretKeyRef:
      name: {{ $mysql.fromSecret | quote }}
      key: {{ .key | quote }}
  {{- else if kindIs "map" $setting }}
    {{- toYaml $setting | nindent 2 }}
  {{- else }}
  value: "{{ include (printf "wandb.mysql.%s" .key) .root }}"
  {{- end }}
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
  {{- if .Values.global.mysql.rdsIamAuth -}}
mysql://$(MYSQL_USER)@$(MYSQL_HOST):$(MYSQL_PORT)/$(MYSQL_DATABASE)?tls=custom&ssl-ca=$(MYSQL_CA_CERT_PATH)&rds-iam-auth=true&aws-region={{ .Values.global.mysql.awsRegion }}
  {{- else if .Values.global.mysql.cloudSqlProxy.enabled -}}
mysql://$(MYSQL_USER)@127.0.0.1:3306/$(MYSQL_DATABASE)?tls=false
  {{- else if .Values.global.mysql.azureEntraAuth -}}
    {{- if include "wandb.mysql.caCertConfigured" . -}}
mysql://$(MYSQL_USER)@$(MYSQL_HOST):$(MYSQL_PORT)/$(MYSQL_DATABASE)?tls=custom&ssl-ca=$(MYSQL_CA_CERT_PATH)&azure-entra-auth=true
    {{- else -}}
mysql://$(MYSQL_USER)@$(MYSQL_HOST):$(MYSQL_PORT)/$(MYSQL_DATABASE)?tls=true&azure-entra-auth=true
    {{- end -}}
  {{- else -}}
mysql://$(MYSQL_USER):$(MYSQL_PASSWORD)@$(MYSQL_HOST):$(MYSQL_PORT)/$(MYSQL_DATABASE)?tls=preferred
  {{- end -}}
{{- end -}}


{{/*
  helper to extract logic for creating the caCert Volume
*/}}
{{- define "wandb.mysql.caCertVolume" -}}
  {{- $refName := (printf "%s-mysql-ca-cert" .Release.Name) -}}
  {{- $key := "MYSQL_CA_CERT" -}}
  {{- $path := "mysql_ca.pem" -}}
  {{- if kindIs "map" .Values.global.mysql.caCert -}}
    {{- if .Values.global.mysql.caCert.valueFrom.secretKeyRef }}
      {{- $refName = .Values.global.mysql.caCert.valueFrom.secretKeyRef.name -}}
      {{- $key = .Values.global.mysql.caCert.valueFrom.secretKeyRef.key -}}
      {{- $path = .Values.global.mysql.caCert.valueFrom.secretKeyRef.key  -}}
- name: mysql-ca
  secret:
    secretName: "{{ $refName }}"
    items:
      - key: "{{ $key }}"
        path: "{{ $path }}"
    {{- else if .Values.global.mysql.caCert.valueFrom.configMapKeyRef }}
      {{- $refName = .Values.global.mysql.caCert.valueFrom.configMapKeyRef.name -}}
      {{- $key = .Values.global.mysql.caCert.valueFrom.configMapKeyRef.key -}}
      {{- $path = .Values.global.mysql.caCert.valueFrom.configMapKeyRef.key  -}}
- name: mysql-ca
  configMap:
    name: "{{ $refName }}"
    items:
      - key: "{{ $key }}"
        path: "{{ $path }}"
    {{- else }}
      {{ fail "Invalid caCert config" }}
    {{- end }}
  {{- else }}
    {{- if not (eq .Values.global.mysql.caCert "") }}
- name: mysql-ca
  secret:
    secretName: "{{ $refName }}"
    items:
      - key: "{{ $key }}"
        path: "{{ $path }}"
    {{- end }}
  {{- end }}
{{- end -}}

{{/*
  helper to extract logic for creating the caCert Volume Mount
*/}}
{{- define "wandb.mysql.caCertVolumeMount" -}}
  {{- if or (kindIs "map" .Values.global.mysql.caCert) (not (eq .Values.global.mysql.caCert "")) }}
    {{- $file := (include "wandb.mysql.certFileName" .) -}}
- name: mysql-ca
  mountPath: /etc/ssl/certs/{{ $file }}
  subPath: {{ $file }}
  {{- end }}
{{- end -}}

{{/*
Return "true" when workloads reach MySQL without a password: a short-lived
token (RDS IAM or Microsoft Entra ID) or the Cloud SQL Auth Proxy's automatic
IAM authentication.
*/}}
{{- define "wandb.mysql.passwordless" -}}
  {{- if or .Values.global.mysql.rdsIamAuth .Values.global.mysql.azureEntraAuth .Values.global.mysql.cloudSqlProxy.enabled -}}
    {{- print "true" -}}
  {{- end -}}
{{- end -}}

{{/*
Return "true" when global.mysql.caCert is set inline or by reference.
*/}}
{{- define "wandb.mysql.caCertConfigured" -}}
  {{- $caCert := .Values.global.mysql.caCert -}}
  {{- if or (kindIs "map" $caCert) (and (kindIs "string" $caCert) (ne $caCert "")) -}}
    {{- print "true" -}}
  {{- end -}}
{{- end -}}

{{/*
Return whether a MySQL workload needs the Azure workload identity token, either
for storage or for Microsoft Entra ID MySQL authentication.
*/}}
{{- define "wandb.mysqlAzureWorkloadIdentityEnabled" -}}
{{- or (eq (include "wandb.azureStorageIdentityEnabled" .) "true") (eq (toString .Values.global.mysql.azureEntraAuth) "true") -}}
{{- end }}

{{/*
Cloud SQL Auth Proxy v2 settings. The proxy reads each CSQL_PROXY_<FLAG>
variable as the matching command-line flag. It listens on loopback only, so
just the pod's own containers can use its IAM identity.
*/}}
{{- define "wandb.mysql.cloudSqlProxyEnvs" -}}
- name: CSQL_PROXY_INSTANCE_CONNECTION_NAME
  value: {{ .Values.global.mysql.cloudSqlProxy.instanceConnectionName | quote }}
- name: CSQL_PROXY_AUTO_IAM_AUTHN
  value: "true"
- name: CSQL_PROXY_PRIVATE_IP
  value: "true"
- name: CSQL_PROXY_ADDRESS
  value: "127.0.0.1"
- name: CSQL_PROXY_PORT
  value: "3306"
- name: CSQL_PROXY_HEALTH_CHECK
  value: "true"
- name: CSQL_PROXY_HTTP_ADDRESS
  value: "0.0.0.0"
- name: CSQL_PROXY_HTTP_PORT
  value: "9801"
- name: CSQL_PROXY_EXIT_ZERO_ON_SIGTERM
  value: "true"
{{- end -}}
