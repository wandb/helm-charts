{{/*
Select the OIDC ConfigMap and keys, matching the license resource/reference pattern.
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
  {{- $defaults := dict
  "clientIdKey" "OIDC_CLIENT_ID"
  "issuerKey" "OIDC_ISSUER"
  "authMethodKey" "OIDC_AUTH_METHOD"
  "corsOriginsKey" "GORILLA_CORS_ORIGINS" -}}
  {{- range $field, $default := $defaults -}}
    {{- $key := default $default (index $config $field) -}}
    {{- if $external -}}
      {{- $key = required (printf "global.auth.oidc.oidcConfigMap.%s is required when oidcConfigMap.name is set" $field) (index $config $field) -}}
    {{- end -}}
    {{- $_ := set $source $field $key -}}
  {{- end -}}
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
  {{- $keys := dict "GORILLA_CORS_ORIGINS" $config.corsOriginsKey -}}
  {{- if $config.enabled -}}
    {{- $keys = merge $keys (dict
    "GORILLA_OIDC_CLIENT_ID" $config.clientIdKey
    "OIDC_CLIENT_ID" $config.clientIdKey
    "GORILLA_OIDC_ISSUER" $config.issuerKey
    "OIDC_ISSUER" $config.issuerKey
    "GORILLA_AUTH_METHOD" $config.authMethodKey
    "OIDC_AUTH_METHOD" $config.authMethodKey) -}}
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
