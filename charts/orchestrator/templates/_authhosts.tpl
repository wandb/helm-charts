{{/*
Configure Better Auth's dynamic base URL only when the ingress has alternate
application hosts. Single-host installs retain the static BASE_URL behavior.
*/}}
{{- define "orchestrator.authHostEnvVars" -}}
  {{- $hosts := include "orchestrator.applicationHosts" . | fromYamlArray -}}
  {{- if gt (len $hosts) 1 -}}
{{ include "orchestrator.envVar" (dict "name" "AUTH_ALLOWED_HOSTS" "value" (join "," $hosts)) }}
  {{- end -}}
{{- end -}}
