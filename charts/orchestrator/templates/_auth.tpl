{{/*
Generate Google OAuth environment variables using the new valueFrom pattern
*/}}
{{- define "orchestrator.googleAuthEnvVars" -}}
{{- $google := .Values.global.authProviders.google -}}
{{ include "orchestrator.envVar" (dict "name" "AUTH_GOOGLE_CLIENT_ID" "value" $google.clientId) }}
{{ include "orchestrator.envVar" (dict "name" "AUTH_GOOGLE_CLIENT_SECRET" "value" $google.clientSecret) }}
{{- end -}}

{{/*
Generate Okta OAuth environment variables using the new valueFrom pattern
*/}}
{{- define "orchestrator.oktaAuthEnvVars" -}}
{{- $okta := .Values.global.authProviders.okta -}}
{{ include "orchestrator.envVar" (dict "name" "AUTH_OKTA_ISSUER" "value" $okta.issuer) }}
{{ include "orchestrator.envVar" (dict "name" "AUTH_OKTA_CLIENT_ID" "value" $okta.clientId) }}
{{ include "orchestrator.envVar" (dict "name" "AUTH_OKTA_CLIENT_SECRET" "value" $okta.clientSecret) }}
{{- end -}}

{{- define "orchestrator.authSecretEnvVars" -}}
{{- $authSecret := .Values.global.secrets.authSecret -}}
{{- if not (include "orchestrator.isValueFrom" $authSecret) -}}
{{- $secretName := (printf "%s-auth-secret" .Release.Name) -}}
{{ include "orchestrator.envVar" (dict "name" "AUTH_SECRET" "value" (dict "valueFrom" (dict "secretKeyRef" (dict "name" $secretName "key" "AUTH_SECRET")))) }}
{{- else }}
{{ include "orchestrator.envVar" (dict "name" "AUTH_SECRET" "value" $authSecret) }}
{{- end -}}
{{- end -}}

{{- define "orchestrator.encryptionKeyEnvVars" -}}
{{- $encryptionKey := .Values.global.secrets.encryptionKey -}}
{{- if not (include "orchestrator.isValueFrom" $encryptionKey) -}}
{{- $secretName := (printf "%s-encryption-key" .Release.Name) -}}
{{ include "orchestrator.envVar" (dict "name" "VARIABLES_AES_256_KEY" "value" (dict "valueFrom" (dict "secretKeyRef" (dict "name" $secretName "key" "AES_256_KEY")))) }}
{{- else }}
{{ include "orchestrator.envVar" (dict "name" "VARIABLES_AES_256_KEY" "value" $encryptionKey) }}
{{- end -}}
{{- end -}}

{{/*
Generate all auth provider environment variables
*/}}
{{- define "orchestrator.authProviderEnvVars" -}}
{{ include "orchestrator.googleAuthEnvVars" . }}
{{ include "orchestrator.oktaAuthEnvVars" . }}
{{ include "orchestrator.authSecretEnvVars" . }}
{{ include "orchestrator.encryptionKeyEnvVars" . }}
{{- end -}}
