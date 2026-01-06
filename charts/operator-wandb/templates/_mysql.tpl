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
Return the db password
*/}}
{{- define "wandb.mysql.password" -}}
{{- print $.Values.global.mysql.password -}}
{{- end -}}

{{/*
Return the db connection string
*/}}
{{- define "wandb.mysql" -}}
mysql://$(MYSQL_USER):$(MYSQL_PASSWORD)@$(MYSQL_HOST):$(MYSQL_PORT)/$(MYSQL_DATABASE)?tls=preferred
{{- end -}}


{{/*
  helper to extract logic for creating the caCert Volume
*/}}
{{- define "wandb.mysql.caCertVolume" -}}
{{- $refName := (printf "%s-mysql-ca-cert" .Release.name) -}}
{{- $key := "MYSQL_CA_CERT" -}}
{{- $path := "mysql_ca.pem" -}}
{{- if kindIs "map" .Values.global.mysql.caCert -}}
  {{- if "secret" }}
    {{- $refName = .Values.global.mysql.caCert.valueFrom.secretKeyRef.name -}}
    {{- $key = .Values.global.mysql.caCert.valueFrom.secretKeyRef.key -}}
    {{- $path = .Values.global.mysql.caCert.valueFrom.secretKeyRef.key  -}}
- name: mysql-ca
  secret:
    secretName: "{{ $refName }}"
    items:
      - key: "{{ $key }}"
        path: "{{ $path }}"
  {{- else if "configmap" }}
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
    {{ fail "Invaid caCert config" }}
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
{{- if or (kindIs "map" .Values.global.mysql.caCert) (not eq .Values.global.mysql.caCert "") }}
{{- $file := (include "wandb.mysql.certFileName" .) -}}
- name: mysql-ca
  mountPath: /etc/ssl/certs/{{ $file }}
  subPath: {{ $file }}
{{- end }}
{{- end -}}

