{{/*
Select the OIDC ConfigMap, matching the license resource/reference pattern.
The external resource is never read or rendered by Helm.
*/}}
{{- define "wandb.oidc.configMap" -}}
  {{- $oidc := .Values.global.auth.oidc -}}
  {{- $config := $oidc.oidcConfigMap | default dict -}}
  {{- $external := not (empty $config.name) -}}
  {{- $source := dict
  "name" (default (printf "%s-oidc-configmap" .Release.Name) $config.name)
  "external" $external
  "enabled" (or $external (ne $oidc.clientId "")) -}}
  {{- $source | toJson -}}
{{- end -}}

{{- define "wandb.oidc.secretSecret" -}}
  {{- default (printf "%s-oidc-secret" .Release.Name) .Values.global.auth.oidc.oidcSecret.name -}}
{{- end -}}

{{/*
Both app and API use the selected ConfigMap in inline and external modes.
Only CORS is optional when inline OIDC is disabled: app.extraCors may provide
that key, but an absent key must preserve the application's default origins.
*/}}
{{- define "wandb.oidcEnvs" -}}
  {{- $config := include "wandb.oidc.configMap" . | fromJson -}}
  {{- $keys := dict "GORILLA_CORS_ORIGINS" "GORILLA_CORS_ORIGINS" -}}
  {{- if $config.enabled -}}
    {{- $keys = merge $keys (dict
    "GORILLA_OIDC_CLIENT_ID" "OIDC_CLIENT_ID"
    "OIDC_CLIENT_ID" "OIDC_CLIENT_ID"
    "GORILLA_OIDC_ISSUER" "OIDC_ISSUER"
    "OIDC_ISSUER" "OIDC_ISSUER"
    "GORILLA_AUTH_METHOD" "OIDC_AUTH_METHOD"
    "OIDC_AUTH_METHOD" "OIDC_AUTH_METHOD") -}}
  {{- end -}}
  {{- range $name, $key := $keys }}
- name: {{ $name }}
  valueFrom:
    configMapKeyRef:
      name: {{ $config.name | quote }}
      key: {{ $key | quote }}
    {{- if not $config.enabled }}
      optional: true
    {{- end }}
  {{- end }}
  {{- if or .Values.global.auth.oidc.secret .Values.global.auth.oidc.oidcSecret.name }}
- name: GORILLA_OIDC_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ include "wandb.oidc.secretSecret" . | quote }}
      key: {{ .Values.global.auth.oidc.oidcSecret.secretKey | quote }}
- name: OIDC_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ include "wandb.oidc.secretSecret" . | quote }}
      key: {{ .Values.global.auth.oidc.oidcSecret.secretKey | quote }}
  {{- end }}
{{- end -}}
