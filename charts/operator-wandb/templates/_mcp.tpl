{{/*
  Datadog Autodiscovery tag JSON for the MCP container. Invoked from the mcp-server
  subchart's podAnnotations[ad.datadoghq.com/mcp-server.tags].

  SCOPE NOTE (please keep): like wandb.mcpEnvs below, this helper is called via tpl
  with .root set to the subchart scope (.Values is the "mcp-server:" subtree).

  Emits a JSON array usable as the value of ad.datadoghq.com/<container>.tags.
  Includes only bounded, chart-owned dimensions. Customer identifiers and
  operator-provided free-form tags are deliberately excluded.
*/}}
{{- define "wandb.mcpDatadogTags" -}}
  {{- $legacyDatadog := index .Values "datadog" | default dict -}}
  {{- $deploymentType := index $legacyDatadog "deploymentType" | default "self-managed" -}}
{{ list "product:wandb" "component:mcp-server" (printf "deployment_type:%s" $deploymentType) | toJson }}
{{- end -}}

{{/*
  Datadog Autodiscovery log config for the MCP container. The `.tags`
  annotation only adds metadata; this `.logs` annotation is what tells a
  Datadog Agent on an allowlisted cluster to collect the mcp-server container
  stdout and attribute it to the configured service.

  SCOPE NOTE: same as wandb.mcpDatadogTags -- .Values is the "mcp-server"
  subtree at call time.
*/}}
{{- define "wandb.mcpDatadogLogs" -}}
  {{- $entry := dict "source" "python" "service" (include "wandb.mcpDDService" .) -}}
{{ list $entry | toJson }}
{{- end -}}

{{/*
  Fixed DD UST label values. Used by mcp-server.podLabels
  so the templated value stays short enough to survive wandb-base.podLabels'
  trunc-63 (which operates on the un-evaluated template text).

  SCOPE NOTE: same as wandb.mcpDatadogTags -- .Values is the "mcp-server"
  subtree at call time.
*/}}
{{- define "wandb.mcpDDService" -}}
  {{- $legacyDatadog := index .Values "datadog" | default dict -}}
{{- index $legacyDatadog "service" | default "wandb-mcp-server-onprem" -}}
{{- end -}}
{{- define "wandb.mcpDDEnv" -}}
  {{- $legacyDatadog := index .Values "datadog" | default dict -}}
{{- index $legacyDatadog "env" | default "production" -}}
{{- end -}}

{{/*
  Resolve the effective Kubernetes observability provider once for every
  consumer. The legacy Datadog flag remains only as a narrow bridge for the
  current Managed Spec fragment; validation rejects conflicting combinations.

  SCOPE NOTE: .Values is the mcp-server subchart scope.
*/}}
{{- define "wandb.mcpObservabilityProvider" -}}
  {{- $observability := index .Values "observability" | default dict -}}
  {{- $provider := index $observability "provider" | default "none" | toString | trim | lower -}}
  {{- $legacyDatadog := index .Values "datadog" | default dict -}}
  {{- if index $legacyDatadog "enabled" | default false -}}
    {{- $provider = "datadog-agent" -}}
  {{- end -}}
{{- $provider -}}
{{- end -}}

{{/*
  Reproduce wandb-base.fullname for a dependency alias using the parent or
  subchart release scope. This is intentionally limited to default names;
  mcp-validation requires an explicit internal URL when API/app naming is
  overridden. Keeping the same contains/truncate rule avoids generating a
  backend URL that differs from the Service name for release names such as
  "customer-api" or names near Kubernetes' 63-character limit.
*/}}
{{- define "wandb.defaultComponentFullname" -}}
  {{- $root := .root -}}
  {{- $name := .name -}}
  {{- if contains $name $root.Release.Name -}}
{{- $root.Release.Name | trunc 63 | trimSuffix "-" -}}
  {{- else -}}
    {{- printf "%s-%s" $root.Release.Name $name | trunc 63 | trimSuffix "-" -}}
  {{- end -}}
{{- end -}}

{{/*
  Fail when a credential-bearing MCP upstream is not a bounded HTTP(S) URL.
  Callers choose whether /traces is allowed.
  IPv6 literals are intentionally unsupported until Helm can validate them
  correctly instead of accepting arbitrary bracketed strings.
*/}}
{{- define "wandb.validateMcpEndpoint" -}}
  {{- $url := .url -}}
  {{- $allowTraces := .allowTraces | default false -}}
  {{- $pathPattern := ternary "(/traces)?" "" $allowTraces -}}
  {{- $hostPattern := `([A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?)([.]([A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?))*` -}}
  {{- $urlPattern := printf `^https?://%s(:[0-9]{1,5})?%s/?$` $hostPattern $pathPattern -}}
  {{- if not (regexMatch $urlPattern $url) -}}
    {{- fail .errorMessage -}}
  {{- end -}}
  {{- $origin := trimSuffix "/" $url -}}
  {{- if $allowTraces -}}
    {{- $origin = trimSuffix "/traces" $origin -}}
  {{- end -}}
  {{- $portMatch := regexFind `:[0-9]+$` $origin -}}
  {{- if $portMatch -}}
    {{- $portDigits := trimPrefix ":" $portMatch -}}
    {{- $port := atoi $portDigits -}}
    {{- if or (lt $port 1) (gt $port 65535) -}}
      {{- fail .errorMessage -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/* Resolve the chart-only `auto` selector to a server-owned exact profile. */}}
{{- define "wandb.resolveMcpToolProfile" -}}
  {{- if eq .profile "auto" -}}
    {{- ternary "models-weave" "models-only" .hasTraceBackend -}}
  {{- else -}}
    {{- .profile -}}
  {{- end -}}
{{- end -}}

{{/* Map chart t-shirt sizes to the three server-owned capacity classes. */}}
{{- define "wandb.resolveMcpCapacityClass" -}}
  {{- $size := .Values.global.size | default "default" | toString | trim | lower -}}
  {{- if eq $size "medium" -}}
medium
  {{- else if has $size (list "large" "xlarge" "xxlarge") -}}
large
  {{- else -}}
small
  {{- end -}}
{{- end -}}

{{/*
  Release-critical environment names are generated from typed values or owned
  by the server's workload profile. The validation template rejects them from
  every generic environment merge channel so no hidden override can change the
  reviewed profile, limits, authentication, routing, or observability policy.
*/}}
{{- define "wandb.mcpReservedEnvNames" -}}
{{- list
  "WANDB_BASE_URL"
  "WANDB_INTERNAL_BASE_URL"
  "WF_TRACE_SERVER_URL"
  "WEAVE_TRACE_SERVER_URL"
  "WB_AGENT_BASE_URL"
  "WANDB_MCP_TOOL_PROFILE"
  "WANDB_MCP_ACCESS_MODE"
  "WANDB_MCP_ENABLE_WEAVE_TOOLS"
  "WANDB_MCP_ENABLE_WEAVE_AGENT_TOOLS"
  "WANDB_MCP_ENABLE_ARIA_TOOLS"
  "WANDB_MCP_ENABLE_RAW_GRAPHQL"
  "WANDB_MCP_READ_ONLY"
  "MCP_WORKLOAD_PROFILE"
  "MCP_CAPACITY_CLASS"
  "MCP_HOSTED_MODE"
  "MCP_TRANSPORT"
  "MCP_AUTH_DISABLED"
  "MCP_TOOL_TIMEOUT_SECONDS"
  "MCP_WANDB_REQUEST_TIMEOUT_SECONDS"
  "MCP_ADMISSION_CONTROL_ENABLED"
  "MCP_ADMISSION_ACTOR_CAPACITY"
  "MCP_ADMISSION_PROCESS_CAPACITY"
  "MCP_ADMISSION_WAIT_MS"
  "MCP_RATE_LIMIT_ENABLED"
  "MCP_RATE_LIMIT_PER_KEY"
  "MCP_RATE_LIMIT_GLOBAL"
  "MCP_MAX_QUERY_LIMIT"
  "MCP_MAX_FULL_TRACE_LIMIT"
  "MCP_MAX_HISTORY_SAMPLES"
  "MCP_MAX_HISTORY_KEYS"
  "MCP_MAX_HISTORY_RANGE_STEPS"
  "MCP_MAX_WANDB_QUERY_ITEMS"
  "MCP_MAX_FULL_DETAIL_ITEMS"
  "MCP_MAX_PROJECT_FIELDS"
  "MCP_MAX_PROBE_RUNS"
  "MCP_MAX_EVALUATION_ROWS"
  "MCP_MAX_SCHEMA_SAMPLE_ROWS"
  "MCP_MAX_WANDB_QUERY_ITEMS_PER_PAGE"
  "MCP_MAX_GQL_ITEMS"
  "MCP_MAX_GQL_ITEMS_PER_PAGE"
  "MCP_SYNC_TOOL_WORKERS"
  "MCP_COUNT_TOOL_WORKERS"
  "MAX_RESPONSE_TOKENS"
  "MAX_ACCUMULATED_BYTES"
  "SESSION_TTL_SECONDS"
  "MAX_SESSIONS_PER_KEY"
  "MCP_SERVER_ENABLE_HMAC_SHA256_SESSIONS"
  "UVICORN_WORKERS"
  "UVICORN_LIMIT_CONCURRENCY"
  "MCP_ANALYTICS_DISABLED"
  "MCP_ANALYTICS_QUEUE_CAPACITY"
  "MCP_ANALYTICS_TEST_BUFFER_CAPACITY"
  "MCP_REQUEST_SUCCESS_SAMPLE_RATE"
  "MCP_SEGMENT_FORWARD"
  "MCP_DEPLOYMENT_TYPE"
  "MCP_LOG_PRIVACY_LEVEL"
  "MCP_DATADOG_ENABLED"
  "MCP_DATADOG_FORWARD"
  "MCP_OTEL_ENABLED"
  "MCP_LOG_FORMAT"
  "DD_SERVICE"
  "DD_ENV"
  "DD_VERSION"
  "DD_AGENT_HOST"
  "DD_TRACE_AGENT_HOSTNAME"
  "DD_EXCEPTION_REPLAY_ENABLED"
  "DD_TRACE_HEADER_TAGS"
  "DD_API_KEY"
  "OTEL_SERVICE_NAME"
  "OTEL_EXPORTER_OTLP_ENDPOINT"
  | toJson -}}
{{- end -}}

{{/* Match exact release settings and future names in reserved policy families. */}}
{{- define "wandb.isMcpReservedEnvName" -}}
  {{- $reserved := has .name .reservedNames -}}
  {{- range .reservedPrefixes -}}
    {{- if hasPrefix . $.name -}}
      {{- $reserved = true -}}
    {{- end -}}
  {{- end -}}
{{- ternary "true" "false" $reserved -}}
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
- WANDB_MCP_TOOL_PROFILE: exact server-owned tool profile (never `auto`).
- WANDB_MCP_ACCESS_MODE: orthogonal read-write/read-only selector.
- MCP_WORKLOAD_PROFILE and MCP_CAPACITY_CLASS: server-owned Dedicated policy.
- WF_TRACE_SERVER_URL: public weave-trace URL via ingress (global.host + /traces).
  The chart's weave-trace subchart mounts the FastAPI app under API_PATH_PREFIX=/traces
  (see templates/weave-trace.yaml), so the in-cluster Service path http://<release>-weave-trace:8722
  returns 404 without the prefix. Using the ingress URL matches the convention other
  internal consumers use (see weave-trace.yaml WF_TRACE_SERVER_URL line).
- WANDB_BASE_URL: the public W&B instance URL (from global.host)
- WANDB_INTERNAL_BASE_URL: typed routing.internalBaseUrl or the namespace-local
  split API / monolith Service used by backend calls.
*/}}
{{- define "wandb.mcpEnvs" -}}
  {{- $tools := index .Values "tools" | default dict -}}
  {{- $profile := index $tools "profile" | default "auto" | toString | trim | lower -}}
  {{- $accessMode := index .Values "accessMode" | default "read-write" | toString | trim | lower -}}
  {{- $traceBackend := index .Values "traceBackend" | default dict -}}
  {{- $traceMode := index $traceBackend "mode" | default "auto" | toString | trim | lower -}}
  {{- $explicitTraceURL := tpl (index $traceBackend "url" | default "" | toString) . | trim -}}
  {{- $hasExplicitTraceURL := ne $explicitTraceURL "" -}}
  {{- $globalWeaveTrace := index .Values.global "weave-trace" | default dict -}}
  {{- $hasTraceBackend := and (eq $traceMode "auto") (or $hasExplicitTraceURL (index $globalWeaveTrace "enabled")) -}}
  {{- $resolvedProfile := include "wandb.resolveMcpToolProfile" (dict "profile" $profile "hasTraceBackend" $hasTraceBackend) -}}
  {{- $routing := index .Values "routing" | default dict -}}
  {{- $internalBaseURL := tpl (index $routing "internalBaseUrl" | default "" | toString) . | trim -}}
  {{- $provider := include "wandb.mcpObservabilityProvider" . | trim -}}
  {{- $observability := index .Values "observability" | default dict -}}
  {{- $privacy := index $observability "privacy" | default "standard" | toString | trim | lower -}}
  {{- $legacyPrivacy := index .Values "privacy" | default dict -}}
  {{- if hasKey $legacyPrivacy "logLevel" -}}
    {{- $privacy = index $legacyPrivacy "logLevel" | toString | trim | lower -}}
  {{- end -}}
- name: WANDB_MCP_TOOL_PROFILE
  value: {{ $resolvedProfile | quote }}
- name: WANDB_MCP_ACCESS_MODE
  value: {{ $accessMode | quote }}
- name: MCP_WORKLOAD_PROFILE
  value: "dedicated"
- name: MCP_CAPACITY_CLASS
  value: {{ include "wandb.resolveMcpCapacityClass" . | trim | quote }}
- name: MCP_TRANSPORT
  value: "http"
- name: MCP_AUTH_DISABLED
  value: "false"
- name: MCP_ANALYTICS_DISABLED
  value: "false"
- name: MCP_SEGMENT_FORWARD
  value: "true"
  {{- if and (eq $resolvedProfile "models-weave") $hasExplicitTraceURL }}
- name: WF_TRACE_SERVER_URL
  value: {{ $explicitTraceURL | quote }}
  {{- else if and (eq $resolvedProfile "models-weave") $hasTraceBackend }}
- name: WF_TRACE_SERVER_URL
  value: {{ printf "%s/traces" (trimSuffix "/" (.Values.global.host | toString)) | quote }}
  {{- end }}
- name: WANDB_BASE_URL
  value: {{ .Values.global.host | quote }}
- name: WANDB_INTERNAL_BASE_URL
  {{- if ne $internalBaseURL "" }}
  value: {{ $internalBaseURL | quote }}
  {{- else }}
    {{- if .Values.global.api.enabled }}
  value: "http://{{ include "wandb.defaultComponentFullname" (dict "root" . "name" "api") }}:8081"
    {{- else }}
  value: "http://{{ include "wandb.defaultComponentFullname" (dict "root" . "name" "app") }}:8080"
    {{- end }}
  {{- end }}
- name: MCP_LOG_PRIVACY_LEVEL
  value: {{ $privacy | quote }}
  {{- if eq $provider "datadog-agent" }}
- name: MCP_DATADOG_ENABLED
  value: "true"
- name: DD_SERVICE
  value: {{ include "wandb.mcpDDService" . | quote }}
- name: DD_ENV
  value: {{ include "wandb.mcpDDEnv" . | quote }}
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
  {{- end }}
  {{- if eq $provider "otel" }}
    {{- $otel := index .Values.global "otel" | default dict -}}
    {{- $otelTraces := index $otel "traces" | default dict -}}
    {{- $otelHost := tpl (index $otelTraces "host" | default "" | toString) . | trim -}}
    {{- if eq $otelHost "" -}}
      {{- $otelHost = printf "%s-otel-daemonset" .Release.Name -}}
    {{- end -}}
    {{- $otelPort := index $otelTraces "port" | default 4317 -}}
    {{- $otelProto := index $otelTraces "proto" | default "grpc" | toString | trim | lower }}
- name: MCP_OTEL_ENABLED
  value: "true"
- name: OTEL_SERVICE_NAME
  value: "mcp-server"
- name: OTEL_EXPORTER_OTLP_ENDPOINT
  value: "http://{{ $otelHost }}:{{ $otelPort }}"
- name: OTEL_EXPORTER_OTLP_PROTOCOL
  value: {{ ternary "http/protobuf" "grpc" (eq $otelProto "http") | quote }}
  {{- end }}
{{- end -}}
