{{/*
SpiceDB (authorization) env, shared by the identity service (writes membership
grants) and the workspace-engine (enforces them). Same SPICEDB_* env names both
services read. The token (preshared key) may be a direct value or a valueFrom
reference (e.g. an ExternalSecret), handled by orchestrator.envVar.
*/}}
{{- define "orchestrator.spicedbEnvVars" -}}
{{ include "orchestrator.envVar" (dict "name" "SPICEDB_ADDR" "value" .Values.global.spicedb.addr) }}
{{ include "orchestrator.envVar" (dict "name" "SPICEDB_INSECURE" "value" .Values.global.spicedb.insecure) }}
{{ include "orchestrator.envVar" (dict "name" "SPICEDB_TOKEN" "value" .Values.global.spicedb.token) }}
{{- end -}}
