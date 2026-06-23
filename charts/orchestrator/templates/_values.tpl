{{/*
Check if a value is configured as a valueFrom reference
Usage: {{ include "orchestrator.isValueFrom" .Values.some.property }}
*/}}
{{- define "orchestrator.isValueFrom" -}}
{{- if and (kindIs "map" .) (hasKey . "valueFrom") -}}
true
{{- end -}}
{{- end -}}

{{/*
Get the direct string value (only for direct string values)
Usage: {{ include "orchestrator.directValue" .Values.some.property }}
*/}}
{{- define "orchestrator.directValue" -}}
{{- if kindIs "string" . -}}
{{- . -}}
{{- else -}}
{{- fail "Value is not a string. Use orchestrator.envVar for valueFrom references." -}}
{{- end -}}
{{- end -}}

{{/*
Generate environment variable configuration for any property
This handles both direct string values and valueFrom references
Usage: {{ include "orchestrator.envVar" (dict "name" "ENV_VAR_NAME" "value" .Values.some.property) }}
*/}}
{{- define "orchestrator.envVar" -}}
{{- $name := .name -}}
{{- $value := .value -}}
{{- if and (kindIs "map" $value) (hasKey $value "valueFrom") -}}
- name: {{ $name }}
  valueFrom:
    {{- toYaml (get $value "valueFrom") | nindent 4 }}
{{- else if kindIs "string" $value -}}
{{- if ne $value "" -}}
- name: {{ $name }}
  value: {{ $value | quote }}
{{- end -}}
{{- else if not (kindIs "invalid" $value) -}}
- name: {{ $name }}
  value: {{ $value | quote }}
{{- end -}}
{{- end -}}

{{/*
Generate multiple environment variables from a map of properties
Usage: {{ include "orchestrator.envVars" (dict "envVars" (dict "CLIENT_ID" .Values.auth.clientId "CLIENT_SECRET" .Values.auth.clientSecret)) }}
*/}}
{{- define "orchestrator.envVars" -}}
{{- range $envName, $value := .envVars -}}
{{- include "orchestrator.envVar" (dict "name" $envName "value" $value) }}
{{- end -}}
{{- end -}}

{{/*
Check if a value should be stored in a secret (i.e., it's a direct string value)
This is used to determine if we should create secrets for backwards compatibility
Usage: {{ include "orchestrator.shouldStoreInSecret" .Values.some.property }}
*/}}
{{- define "orchestrator.shouldStoreInSecret" -}}
{{- if and (kindIs "string" .) (ne . "") -}}
true
{{- end -}}
{{- end -}}

{{/*
Get value for storing in secret (base64 encoded)
Only works with direct string values
Usage: {{ include "orchestrator.secretValue" .Values.some.property }}
*/}}
{{- define "orchestrator.secretValue" -}}
{{- if include "orchestrator.shouldStoreInSecret" . -}}
{{- . | b64enc -}}
{{- else -}}
{{- fail "Cannot store valueFrom reference in secret. Use environment variables instead." -}}
{{- end -}}
{{- end -}}