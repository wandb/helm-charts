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
  Datadog Autodiscovery tag JSON for the MCP container. Invoked from the mcp-server
  subchart's podAnnotations[ad.datadoghq.com/mcp-server.tags].

  SCOPE NOTE (please keep): like wandb.mcpEnvs below, this helper is called via tpl
  with .root set to the subchart scope (.Values is the "mcp-server:" subtree). Access
  .Values.datadog.* directly; do NOT use .Values["mcp-server"][...] here or scope breaks.

  Emits a JSON array usable as the value of ad.datadoghq.com/<container>.tags.
  Always includes product:wandb, component:mcp-server, deployment_type:<value>.
  Optionally appends customer:<value> and any extraTags entries.
*/}}
{{- define "wandb.mcpDatadogTags" -}}
{{- $tags := list "product:wandb" "component:mcp-server" (printf "deployment_type:%s" (index .Values "datadog" "deploymentType" | default "self-managed")) -}}
{{- with index .Values "datadog" "customer" -}}
{{- $tags = append $tags (printf "customer:%s" .) -}}
{{- end -}}
{{- range (index .Values "datadog" "extraTags" | default list) -}}
{{- $tags = append $tags . -}}
{{- end -}}
{{ toJson $tags }}
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
{{/*
  Privacy level for customer-supplied content in logs. Default here is "standard"
  (redact free-text params, demote verbose log sites to DEBUG) so customer K8s
  installs don't retain plaintext customer queries/descriptions/titles in logs.
  Override via mcp-server.privacy.logLevel: "off" | "standard" | "strict".
  See https://github.com/wandb/wandb-mcp-server/blob/main/docs/OBSERVABILITY.md
*/}}
- name: MCP_LOG_PRIVACY_LEVEL
  value: {{ index .Values "privacy" "logLevel" | default "standard" | quote }}
{{- if index .Values "datadog" "enabled" }}
- name: MCP_DATADOG_ENABLED
  value: "true"
{{/*
  Forwarder is enabled ONLY when datadog.mode == "forwarder" (serverless). On managed K8s
  (mode=agent, default), we intentionally do NOT set MCP_DATADOG_FORWARD -- the DD Agent
  DaemonSet handles logs (via stdout tail) and APM (via DD_AGENT_HOST:8126). Setting the
  forwarder in agent mode would double-ship logs and require a DD_API_KEY on the workload.
*/}}
{{- if eq (index .Values "datadog" "mode" | default "agent") "forwarder" }}
- name: MCP_DATADOG_FORWARD
  value: "true"
{{- end }}
- name: DD_SERVICE
  value: {{ index .Values "datadog" "service" | default "wandb-mcp-server-onprem" | quote }}
- name: DD_ENV
  value: {{ index .Values "datadog" "env" | default "production" | quote }}
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
{{/*
  Tell the server to emit structured JSON logs so Datadog parses level/status correctly
  instead of misclassifying normal INFO request logs as errors. Requires
  wandb-mcp-server >= 0.3.3 (MCP_LOG_FORMAT support). Earlier images ignore this var.
*/}}
- name: MCP_LOG_FORMAT
  value: "json"
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
