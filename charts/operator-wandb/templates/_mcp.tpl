{{/*
  Fail fast if mcp-server is enabled without a reachable weave-trace.
*/}}
{{- if and (index .Values "mcp-server" "install") (not (index .Values "weave-trace" "install")) -}}
{{- if not (dig "mcp-server" "env" "WF_TRACE_SERVER_URL" "" .Values) -}}
{{- fail "mcp-server requires weave-trace.install=true or mcp-server.env.WF_TRACE_SERVER_URL to be set" -}}
{{- end -}}
{{- end -}}

{{/*
Environment variables for the MCP server subchart.

Resolves:
- WF_TRACE_SERVER_URL: in-cluster weave-trace service (port 8722)
- WANDB_BASE_URL: the W&B instance URL (from global.host)

Requires weave-trace to be installed. If weave-trace is disabled,
override WF_TRACE_SERVER_URL in the mcp-server.env values block.
*/}}
{{- define "wandb.mcpEnvs" -}}
- name: WF_TRACE_SERVER_URL
  value: "http://{{ .Release.Name }}-weave-trace:8722"
- name: WANDB_BASE_URL
  value: {{ .Values.global.host | quote }}
{{- if .Values.datadog.enabled }}
- name: MCP_DATADOG_ENABLED
  value: "true"
- name: DD_SERVICE
  value: "mcp-server"
- name: DD_ENV
  value: "production"
- name: DD_AGENT_HOST
  valueFrom:
    fieldRef:
      fieldPath: status.hostIP
- name: DD_TRACE_AGENT_HOSTNAME
  valueFrom:
    fieldRef:
      fieldPath: status.hostIP
- name: DD_EXCEPTION_REPLAY_ENABLED
  value: "false"
- name: DD_TRACE_HEADER_TAGS
  value: ""
{{- end }}
{{- if .Values.otel.enabled }}
- name: MCP_OTEL_ENABLED
  value: "true"
- name: OTEL_SERVICE_NAME
  value: "mcp-server"
- name: OTEL_EXPORTER_OTLP_ENDPOINT
  value: "http://{{ .Release.Name }}-otel-collector:4317"
{{- end }}
{{- with (index .Values "mcp-server") }}
{{- if .auth }}
{{- if .auth.mode }}
- name: MCP_AUTH_MODE
  value: {{ .auth.mode | quote }}
{{- end }}
{{- if .auth.issuer }}
- name: MCP_OAUTH_ISSUER
  value: {{ .auth.issuer | quote }}
{{- end }}
{{- if .auth.audience }}
- name: MCP_OAUTH_AUDIENCE
  value: {{ .auth.audience | quote }}
{{- end }}
{{- if .auth.requiredScopes }}
- name: MCP_OAUTH_REQUIRED_SCOPES
  value: {{ .auth.requiredScopes | quote }}
{{- end }}
{{- end }}
{{- end }}
{{- end -}}
