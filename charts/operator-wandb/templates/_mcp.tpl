{{/*
Environment variables for the MCP server subchart.

Resolves:
- WF_TRACE_SERVER_URL: in-cluster weave-trace service
- WANDB_BASE_URL: the W&B instance URL (from global.host)
*/}}
{{- define "wandb.mcpEnvs" -}}
- name: WF_TRACE_SERVER_URL
  value: "http://{{ .Release.Name }}-weave-trace:8722"
- name: WANDB_BASE_URL
  value: {{ .Values.global.host | quote }}
{{- end -}}
{{- end -}}
