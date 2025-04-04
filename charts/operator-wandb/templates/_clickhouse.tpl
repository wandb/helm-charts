{{- define "wandb.clickhouse.fullname" -}}
{{- if .Values.fullnameOverride }}
  {{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else -}}
  {{- .Release.Name | trunc 63 | trimSuffix "-" }}-clickhouse
{{- end }}
{{- end }}

{{- define "wandb.clickhouse.host" -}}
{{- if not .Values.clickhouse.install -}}
  {{- .Values.global.clickhouse.host | default "" -}}
{{- else -}}
  {{- include "wandb.clickhouse.fullname" . }}-ch-server-headless.{{ .Release.Namespace }}.svc.cluster.local
{{- end }}
{{- end }}

{{/*
Get ClickHouse password from either explicit value or secret
*/}}
{{- define "wandb.clickhouse.password" -}}
{{- if not .Values.clickhouse.install -}}
  {{- if .Values.global.clickhouse.password -}}
    {{- .Values.global.clickhouse.password -}}
  {{- else if .Values.global.clickhouse.passwordSecret.name -}}
    {{- /* For template/lint we simply return a dummy value instead of trying to look up a secret */ -}}
    {{- if .Release.IsUpgrade | or .Release.IsInstall -}}
      {{- $secretName := .Values.global.clickhouse.passwordSecret.name -}}
      {{- $secretKey := .Values.global.clickhouse.passwordSecret.passwordKey | default "CLICKHOUSE_PASSWORD" -}}
      {{- $secret := (lookup "v1" "Secret" .Release.Namespace $secretName) -}}
      {{- if and $secret $secret.data }}
        {{- $value := index $secret.data $secretKey | b64dec -}}
        {{- if $value }}
          {{- $value -}}
        {{- else }}
          {{- fail (printf "Key %s not found in Secret %s" $secretKey $secretName) -}}
        {{- end }}
      {{- else }}
        {{- fail (printf "Secret %s not found or has no data in namespace %s" $secretName .Release.Namespace) -}}
      {{- end }}
    {{- else -}}
      {{- /* Return a dummy password for lint/template */ -}}
      dummy-password-lint-only
    {{- end -}}
  {{- else }}
    {{- if .Release.IsUpgrade | or .Release.IsInstall -}}
      {{- fail "When using external ClickHouse (clickhouse.install=false), either global.clickhouse.password or global.clickhouse.passwordSecret must be provided" -}}
    {{- else -}}
      {{- /* Return a dummy password for lint/template */ -}}
      dummy-password-lint-only
    {{- end -}}
  {{- end }}
{{- else -}}
  {{- if .Values.clickhouse.password -}}
    {{- .Values.clickhouse.password -}}
  {{- else if .Values.clickhouse.passwordSecret -}}
    {{- if .Values.clickhouse.passwordSecret.name -}}
      {{- /* For template/lint we simply return a dummy value instead of trying to look up a secret */ -}}
      {{- if .Release.IsUpgrade | or .Release.IsInstall -}}
        {{- $secretName := .Values.clickhouse.passwordSecret.name -}}
        {{- $secretKey := .Values.clickhouse.passwordSecret.key | default "CLICKHOUSE_PASSWORD" -}}
        {{- $secret := (lookup "v1" "Secret" .Release.Namespace $secretName) -}}
        {{- if and $secret $secret.data }}
          {{- $value := index $secret.data $secretKey | b64dec -}}
          {{- if $value }}
            {{- $value -}}
          {{- else }}
            {{- fail (printf "Key %s not found in Secret %s" $secretKey $secretName) -}}
          {{- end }}
        {{- else }}
          {{- fail (printf "Secret %s not found or has no data in namespace %s" $secretName .Release.Namespace) -}}
        {{- end }}
      {{- else -}}
        {{- /* Return a dummy password for lint/template */ -}}
        dummy-password-lint-only
      {{- end -}}
    {{- else -}}
      {{- randAlphaNum 16 | quote -}}
    {{- end -}}
  {{- else -}}
    {{- randAlphaNum 16 | quote -}}
  {{- end }}
{{- end -}}
{{- end -}}

{{/*
Return name of secret where ClickHouse information is stored
*/}}
{{- define "wandb.clickhouse.passwordSecret" -}}
{{- if not .Values.clickhouse.install -}}
  {{- if .Values.global.clickhouse.passwordSecret.name -}}
    {{- .Values.global.clickhouse.passwordSecret.name -}}
  {{- else -}}
    {{- fail "When using external ClickHouse (clickhouse.install=false), global.clickhouse.passwordSecret.name must be provided" -}}
  {{- end }}
{{- else -}}
  {{- if .Values.clickhouse.passwordSecret -}}
    {{- if .Values.clickhouse.passwordSecret.name -}}
      {{- .Values.clickhouse.passwordSecret.name -}}
    {{- else -}}
      {{- printf "%s-clickhouse" .Release.Name -}}
    {{- end -}}
  {{- else -}}
    {{- printf "%s-clickhouse" .Release.Name -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return key in secret where ClickHouse password is stored
*/}}
{{- define "wandb.clickhouse.passwordSecret.passwordKey" -}}
{{- if not .Values.clickhouse.install -}}
  {{- if .Values.global.clickhouse.passwordSecret.name }}
    {{- .Values.global.clickhouse.passwordSecret.passwordKey | default "CLICKHOUSE_PASSWORD" -}}
  {{- else -}}
    {{- fail "When using external ClickHouse (clickhouse.install=false), global.clickhouse.passwordSecret.name must be provided" -}}
  {{- end }}
{{- else -}}
  {{- if .Values.clickhouse.passwordSecret -}}
    {{- if .Values.clickhouse.passwordSecret.key -}}
      {{- .Values.clickhouse.passwordSecret.key | default "CLICKHOUSE_PASSWORD" -}}
    {{- else -}}
      CLICKHOUSE_PASSWORD
    {{- end -}}
  {{- else -}}
    CLICKHOUSE_PASSWORD
  {{- end -}}
{{- end -}}
{{- end }}

{{- define "wandb.clickhouse.port" -}}
{{- if not .Values.clickhouse.install -}}
  {{- .Values.global.clickhouse.port | default 8123 -}}
{{- else -}}
  {{- if .Values.clickhouse.server -}}
    {{- .Values.clickhouse.server.httpPort | default 8123 -}}
  {{- else -}}
    {{- 8123 -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{- define "wandb.clickhouse.database" -}}
{{- if not .Values.clickhouse.install -}}
  {{- .Values.global.clickhouse.database | default "default" -}}
{{- else -}}
  {{- .Values.clickhouse.database | default "weave_trace_db" -}}
{{- end -}}
{{- end -}}

{{- define "wandb.clickhouse.user" -}}
{{- if not .Values.clickhouse.install -}}
  {{- .Values.global.clickhouse.user | default "default" -}}
{{- else -}}
  {{- .Values.clickhouse.user | default "wandb-user" -}}
{{- end -}}
{{- end -}}
