{{/* Shared inline configuration: this helper runs in the evaluations subchart context. */}}
{{- define "wandb.evaluations.env" -}}
- name: CES_HTTP_ADDRESS
  value: ":9300"
- name: WANDB_BASE_URL
  {{- if .Values.global.api.enabled }}
  value: "http://{{ .Release.Name }}-api:8081/"
  {{- else }}
  value: "http://{{ .Release.Name }}-app:8080/"
  {{- end }}
  {{- range $kind := list "mysql" "clickhouse" }}
    {{- $db := index $.Values $kind }}
    {{- $prefix := printf "CES_%s_" (upper $kind) }}
    {{- range $field := list "host" "database" "user" "tls" }}
- name: {{ $prefix }}{{ upper $field }}
  value: {{ required (printf "evaluations.%s.%s is required" $kind $field) (index $db $field) | quote }}
    {{- end }}
- name: {{ $prefix }}PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ required (printf "evaluations.%s.passwordSecret.name is required" $kind) $db.passwordSecret.name | quote }}
      key: {{ required (printf "evaluations.%s.passwordSecret.key is required" $kind) $db.passwordSecret.key | quote }}
  {{- end }}
- name: CES_MYSQL_PORT
  value: {{ .Values.mysql.port | quote }}
- name: CES_CLICKHOUSE_NATIVE_PORT
  value: {{ .Values.clickhouse.nativePort | quote }}
{{- end -}}

{{/* Reuse the existing CA mount format, with an earlier hook object for inline PEM. */}}
{{- define "wandb.evaluations.caVolumes" -}}
  {{- $context := deepCopy . }}
  {{- $ca := .Values.global.mysql.caCert }}
  {{- if and (kindIs "string" $ca) (not (empty $ca)) }}
    {{- $_ := set $context.Values.global.mysql "caCert" (dict "valueFrom" (dict "secretKeyRef" (dict "name" (printf "%s-evaluations-mysql-ca" .Release.Name) "key" "mysql_ca.pem"))) }}
  {{- end }}
{{- include "wandb.mysql.caCertVolume" $context }}
{{- end -}}

{{/* Validate production database isolation and the sole permitted plaintext connection. */}}
{{- define "wandb.evaluations.validate" -}}
  {{- range $env := list (.Values.evaluations.env | default dict) (.Values.evaluations.extraEnv | default dict) (.Values.evaluations.containers.evaluations.env | default dict) }}
    {{- if hasKey $env "CES_ENVIRONMENT" }}
      {{- if eq (toString (get $env "CES_ENVIRONMENT")) "local" }}
        {{- fail "evaluations CES_ENVIRONMENT=local is unsupported" }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- $mysql := .Values.evaluations.mysql }}
  {{- $mysqlLoopback := or (regexMatch `^127(\.(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])){3}$` $mysql.host) (eq $mysql.host "::1") }}
  {{- if and (eq $mysql.tls "disabled") (not $mysqlLoopback) }}
    {{- fail "evaluations.mysql.tls=disabled requires a literal loopback IP" }}
  {{- end }}
  {{- if and (kindIs "string" .Values.global.mysql.database) (eq $mysql.database .Values.global.mysql.database) }}
    {{- fail "evaluations.mysql.database must be separate from Gorilla" }}
  {{- end }}
  {{- if and (kindIs "string" .Values.global.clickhouse.database) (eq .Values.evaluations.clickhouse.database .Values.global.clickhouse.database) }}
    {{- fail "evaluations.clickhouse.database must be separate from Weave Trace" }}
  {{- end }}
{{- end -}}
