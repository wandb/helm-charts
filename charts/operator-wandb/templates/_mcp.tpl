{{/*
  Fail fast if mcp-server is enabled without a reachable weave-trace.
  Runs at PARENT chart parse scope, where .Values["mcp-server"] resolves to
  the subchart block. Do NOT replicate this access pattern inside the helper
  defines below -- see scope note on wandb.mcpEnvs.
*/}}
{{- if and (index .Values "mcp-server" "install") (not (index .Values "weave-trace" "install")) -}}
{{- if not (index .Values "mcp-server" "env" "WF_TRACE_SERVER_URL") -}}
{{- fail "mcp-server requires weave-trace.install=true or mcp-server.env.WF_TRACE_SERVER_URL to be set" -}}
{{- end -}}
{{- end -}}

{{/*
Environment variables for the MCP server subchart.

SCOPE NOTE (please keep): wandb.mcpEnvs is invoked via envTpls -> tpl . $.root
from the mcp-server subchart render path (see charts/wandb-base/templates/_containers.tpl).
At call time .Values is the SUBCHART-scoped block (the "mcp-server:" subtree
from the parent), not the full parent values. Reference subchart-local keys
directly; .Values.global.* is auto-propagated by helm. Do NOT use
.Values["mcp-server"][...] inside this define -- it resolves to nil and
fails helm render with "index of nil pointer".

Resolves:
- WF_TRACE_SERVER_URL: public weave-trace URL via ingress (global.host + /traces).
  The chart's weave-trace subchart mounts the FastAPI app under API_PATH_PREFIX=/traces
  (see templates/weave-trace.yaml), so the in-cluster Service path http://<release>-weave-trace:8722
  returns 404 without the prefix. Using the ingress URL matches the convention other
  internal consumers use (see weave-trace.yaml WF_TRACE_SERVER_URL line).
- WANDB_BASE_URL: the W&B instance URL (from global.host)

Requires weave-trace to be installed. If weave-trace is disabled,
override WF_TRACE_SERVER_URL in the mcp-server.env values block.
*/}}
{{- define "wandb.mcpEnvs" -}}
{{- if not (index .Values "env" "WF_TRACE_SERVER_URL") }}
- name: WF_TRACE_SERVER_URL
  value: "{{ .Values.global.host }}/traces"
{{- end }}
- name: WANDB_BASE_URL
  value: {{ .Values.global.host | quote }}
{{- if index .Values "datadog" "enabled" }}
- name: MCP_DATADOG_ENABLED
  value: "true"
- name: MCP_DATADOG_FORWARD
  value: "true"
- name: DD_SERVICE
  value: "mcp-server"
- name: DD_ENV
  value: "production"
- name: DD_VERSION
  value: {{ .Values.image.tag | quote }}
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
{{- with index .Values "analytics" "datadogApiKeySecret" "name" }}
- name: DD_API_KEY
  valueFrom:
    secretKeyRef:
      name: {{ . }}
      key: {{ index $.Values "analytics" "datadogApiKeySecret" "key" | default "api-key" }}
{{- end }}
{{- end }}
{{- if index .Values "otel" "enabled" }}
- name: MCP_OTEL_ENABLED
  value: "true"
- name: OTEL_SERVICE_NAME
  value: "mcp-server"
- name: OTEL_EXPORTER_OTLP_ENDPOINT
  value: "http://{{ .Release.Name }}-otel-collector:4317"
{{- end }}
{{- end -}}
