{{/*
Generate PostgreSQL password environment variable configuration
This handles both direct string values and valueFrom references
*/}}
{{- define "orchestrator.postgresqlEnvVars" -}}
{{ include "orchestrator.envVar" (dict "name" "POSTGRES_USER" "value" .Values.global.postgresql.user) }}
{{ include "orchestrator.envVar" (dict "name" "POSTGRES_HOST" "value" .Values.global.postgresql.host) }}
{{ include "orchestrator.envVar" (dict "name" "POSTGRES_PORT" "value" .Values.global.postgresql.port) }}
{{ include "orchestrator.envVar" (dict "name" "POSTGRES_DATABASE" "value" .Values.global.postgresql.database) }}
{{ include "orchestrator.envVar" (dict "name" "POSTGRES_PASSWORD" "value" .Values.global.postgresql.password) }}
- name: POSTGRES_URL
  value: "postgresql://$(POSTGRES_USER):$(POSTGRES_PASSWORD)@$(POSTGRES_HOST):$(POSTGRES_PORT)/$(POSTGRES_DATABASE)"
{{- end -}}
