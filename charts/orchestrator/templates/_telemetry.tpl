{{/*
Telemetry env vars that need a node-local OTel collector address.

Apps send to the per-node otel DaemonSet via the host IP (status.hostIP) rather
than the ctrlplane-otel ClusterIP, avoiding an extra cross-node hop. OTEL_HOST_IP
is emitted FIRST so the $(OTEL_HOST_IP) interpolation in the addresses below
resolves — Kubernetes only substitutes $(VAR) from env entries declared earlier
in the list, so these MUST stay ordered (hence an envTpls include, not the
alphabetically-sorted env map). Same ordering approach as orchestrator.redisEnvVars.

Defaults that DON'T interpolate (DD_SERVICE, DD_ENV, TRACE_SAMPLE_RATE,
OTEL_SERVICE_NAME, OTEL_SAMPLER_RATIO) live in values.yaml under each service's
`env` map so they stay overrideable per environment.
*/}}

{{/*
workspace-engine (Go/airframe): exports metrics + traces over OTLP gRPC (4317).
It reads TRACE_ADDRESS / METRICS_ADDRESS (NOT the OTEL_* vars identity uses).
*/}}
{{- define "orchestrator.workspaceEngineTelemetryEnvVars" -}}
- name: OTEL_HOST_IP
  valueFrom:
    fieldRef:
      fieldPath: status.hostIP
- name: TRACE_ADDRESS
  value: "$(OTEL_HOST_IP):4317"
- name: METRICS_ADDRESS
  value: "$(OTEL_HOST_IP):4317"
{{- end -}}

{{/*
identity (TS/OTel SDK): exports over OTLP HTTP (4318); endpoint needs the scheme.
*/}}
{{- define "orchestrator.identityTelemetryEnvVars" -}}
- name: OTEL_HOST_IP
  valueFrom:
    fieldRef:
      fieldPath: status.hostIP
- name: OTEL_EXPORTER_OTLP_ENDPOINT
  value: "http://$(OTEL_HOST_IP):4318"
{{- end -}}
