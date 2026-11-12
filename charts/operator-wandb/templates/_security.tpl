{{- define "wandb.security.configMapName" -}}
  {{- printf "%s-security-configmap" .Release.Name -}}
{{- end -}}

{{- define "wandb.security.keys" -}}
- GORILLA_ALLOW_USER_TEAM_CREATION
- GORILLA_DISABLE_CODE_SAVING
- GORILLA_ALLOW_ANONYMOUS_PUBLIC_PROJECTS
- GORILLA_DISABLE_SSO_PROVISIONING
- GORILLA_INSECURE_ALLOW_API_KEY_ADMIN_ACCESS
- GORILLA_BUCKET_ATTRIBUTION_DISABLED
- GORILLA_ONPREM_HIDE_UPGRADE_BANNER
- GORILLA_ARTIFACT_GC_ENABLED
- GORILLA_DATA_RETENTION_PERIOD
{{- end -}}

{{/* Copy only settings already present; unset flags must remain absent. */}}
{{- define "wandb.security.inlineData" -}}
  {{- $data := dict -}}
  {{- $extraEnv := .Values.global.extraEnv | default dict -}}
  {{- range include "wandb.security.keys" . | fromYamlArray -}}
    {{- if hasKey $extraEnv . -}}
      {{- $_ := set $data . (get $extraEnv . | toString) -}}
    {{- end -}}
  {{- end -}}
  {{- $sessionLength := printf "%vh" .Values.global.auth.sessionLengthHours -}}
  {{- $_ := set $data "GORILLA_SESSION_LENGTH" $sessionLength -}}
  {{- $_ := set $data "GORILLA_GLUE_SESSION_LENGTH" $sessionLength -}}
  {{- $data | toYaml -}}
{{- end -}}
