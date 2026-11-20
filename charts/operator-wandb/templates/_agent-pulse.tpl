{{/* Called from the agent-pulse subchart; Values contains its local settings. */}}
{{- define "wandb.agentPulseEnvs" -}}
  {{- if and (empty .Values.image.tag) (empty .Values.image.digest) -}}
    {{- fail "agent-pulse requires an explicit image.tag or image.digest" -}}
  {{- end -}}
  {{- $secret := required "agent-pulse.connectionSecret is required" .Values.connectionSecret -}}
  {{- $apiURL := .Values.routing.apiBaseUrl -}}
  {{- if not $apiURL -}}
    {{- if .Values.global.api.enabled -}}
      {{- $apiURL = printf "http://%s-api:8081" .Release.Name -}}
    {{- else -}}
      {{- $apiURL = printf "http://%s-app:8080" .Release.Name -}}
    {{- end -}}
  {{- end -}}
- name: WANDB_ORIGIN
  value: {{ .Values.global.host | quote }}
- name: WANDB_LOGIN_URL
  value: {{ printf "%s/oidc/login" (trimSuffix "/" .Values.global.host) | quote }}
- name: WANDB_COOKIE_NAME
  value: {{ .Values.routing.cookieName | quote }}
- name: WANDB_CLIENT_BASE_URL
  value: {{ tpl $apiURL . | quote }}
- name: WEAVE_CLIENT_BASE_URL
  value: {{ tpl (default (printf "http://%s-weave-trace:8080/traces" .Release.Name) .Values.routing.traceBaseUrl) . | quote }}
  {{- range $key := list "DATABASE_URL" "CLICKHOUSE_URL" "CLICKHOUSE_USERNAME" "CLICKHOUSE_PASSWORD" }}
- name: {{ $key }}
  valueFrom:
    secretKeyRef:
      name: {{ $secret | quote }}
      key: {{ $key }}
  {{- end }}
{{- end -}}
