{{- define "wandb.security.configMapName" -}}
  {{- printf "%s-security-configmap" .Release.Name -}}
{{- end -}}

{{/* Legacy MySQL and OTel charts also inherit global.extraEnv outside wandb-base. */}}
{{- define "wandb.securityLegacyEnvs" -}}
  {{- $root := .root -}}
  {{- $env := merge (deepCopy ($root.Values.extraEnv | default dict)) ($root.Values.global.extraEnv | default dict) ($root.Values.extraEnvFrom | default dict) ($root.Values.global.extraEnvFrom | default dict) -}}
  {{- $container := dict "env" $env "envFrom" (.envFrom | default dict) -}}
  {{- include "wandb.securityEnvs" (merge (dict "container" $container) $root) -}}
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

{{/* Runs with the chart context and the merged container. Session references
follow existing API/Glue ConfigMap consumers, including container-local jobs.
*/}}
{{- define "wandb.securityEnvs" -}}
  {{- $keys := include "wandb.security.keys" . | fromYamlArray -}}
  {{- $configMaps := dict -}}
  {{- range $name, $kind := .container.envFrom -}}
    {{- if eq $kind "configMapRef" -}}
      {{- $_ := set $configMaps (tpl $name $) true -}}
    {{- end -}}
  {{- end -}}
  {{- range .container.envFromTpls -}}
    {{- range tpl . $ | fromYamlArray -}}
      {{- if and .configMapRef (empty .prefix) -}}
        {{- $_ := set $configMaps .configMapRef.name true -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
  {{- $sessionSources := dict "api" "GORILLA_SESSION_LENGTH" "glue" "GORILLA_GLUE_SESSION_LENGTH" -}}
  {{- range $service, $key := $sessionSources -}}
    {{- if hasKey $configMaps (printf "%s-%s-configmap" $.Release.Name $service) -}}
      {{- $keys = append $keys $key -}}
    {{- end -}}
  {{- end -}}
  {{- range $keys }}
    {{- if not (hasKey $.container.env .) }}
- name: {{ . }}
  valueFrom:
    configMapKeyRef:
      name: {{ include "wandb.security.configMapName" $ | quote }}
      key: {{ . }}
      optional: true
    {{- end -}}
  {{- end -}}
{{- end -}}
