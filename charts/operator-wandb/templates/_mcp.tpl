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
{{- end -}}
