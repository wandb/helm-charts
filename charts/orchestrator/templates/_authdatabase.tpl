{{/*
Build AUTH_DATABASE_URL for the identity service (better-auth) from
.Values.global.authDatabase. The password may be a direct string or a valueFrom
reference (e.g. an ExternalSecret-materialized secret), handled by orchestrator.envVar.
The component vars must be emitted before AUTH_DATABASE_URL so the $(VAR)
interpolation resolves — same approach as orchestrator.postgresqlEnvVars.
*/}}
{{- define "orchestrator.authDatabaseEnvVars" -}}
{{ include "orchestrator.envVar" (dict "name" "AUTH_DB_USER" "value" .Values.global.authDatabase.user) }}
{{ include "orchestrator.envVar" (dict "name" "AUTH_DB_HOST" "value" .Values.global.authDatabase.host) }}
{{ include "orchestrator.envVar" (dict "name" "AUTH_DB_PORT" "value" .Values.global.authDatabase.port) }}
{{ include "orchestrator.envVar" (dict "name" "AUTH_DB_NAME" "value" .Values.global.authDatabase.database) }}
{{ include "orchestrator.envVar" (dict "name" "AUTH_DB_PASSWORD" "value" .Values.global.authDatabase.password) }}
- name: AUTH_DATABASE_URL
  value: "postgresql://$(AUTH_DB_USER):$(AUTH_DB_PASSWORD)@$(AUTH_DB_HOST):$(AUTH_DB_PORT)/$(AUTH_DB_NAME)"
{{- end -}}
