{{/*
JWT *verification* env for the workspace-engine: it validates the JWTs the
identity service signs. AUTH_JWKS_URL (non-empty) enables JWT auth and points at
the identity service's JWKS endpoint; AUTH_VALID_ISSUERS must match the `iss` the
identity stamps (its BASE_URL = global.fqdn); AUTH_AUDIENCE must equal identity's
AUTH_JWT_AUDIENCE (both sourced from global.jwt.audience).
*/}}
{{- define "orchestrator.authJwtEnvVars" -}}
{{ include "orchestrator.envVar" (dict "name" "AUTH_JWKS_URL" "value" (printf "http://%s-identity:8081/api/auth/jwks" .Release.Name)) }}
{{ include "orchestrator.envVar" (dict "name" "AUTH_VALID_ISSUERS" "value" .Values.global.fqdn) }}
{{ include "orchestrator.envVar" (dict "name" "AUTH_AUDIENCE" "value" .Values.global.jwt.audience) }}
{{- end -}}
