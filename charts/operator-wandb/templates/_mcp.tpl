{{/*
Environment variables for the MCP server subchart.

Resolves:
- WF_TRACE_SERVER_URL: in-cluster weave-trace service
- WANDB_BASE_URL: the W&B instance URL (from global.host)
*/}}
{{- define "wandb.mcpEnvs" -}}
WF_TRACE_SERVER_URL: "http://{{ .Release.Name }}-weave-trace:8080"
WANDB_BASE_URL: {{ .Values.global.host | quote }}
{{- end -}}
