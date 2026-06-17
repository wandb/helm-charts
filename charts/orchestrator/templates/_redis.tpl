{{/*
REDIS_URL for the identity service and workspace-engine — both use it for
cross-pod SpiceDB read-after-write floor propagation. Built from global.redis;
component vars emitted first so the $(VAR) interpolation resolves (same approach
as orchestrator.postgresqlEnvVars). Password may be a value or a valueFrom.
*/}}
{{- define "orchestrator.redisEnvVars" -}}
{{ include "orchestrator.envVar" (dict "name" "REDIS_HOST" "value" .Values.global.redis.host) }}
{{ include "orchestrator.envVar" (dict "name" "REDIS_PORT" "value" .Values.global.redis.port) }}
{{ include "orchestrator.envVar" (dict "name" "REDIS_PASSWORD" "value" .Values.global.redis.password) }}
- name: REDIS_URL
  value: "redis://:$(REDIS_PASSWORD)@$(REDIS_HOST):$(REDIS_PORT)"
{{- end -}}
