{{/*
Return the name of the secret where OIDC secret is stored, considering if the custom secret is defined
*/}}
{{- define "wandb.oidc.secretSecret" -}}
  {{- if .Values.global.auth.oidc.oidcSecret.name }}
  {{- .Values.global.auth.oidc.oidcSecret.name -}}
  {{- else }}
  {{- print .Release.Name "-oidc-secret" -}}
  {{- end -}}
{{- end -}}

{{/*
Read customer-owned OIDC settings for both the app and standalone API.
Required references prevent a missing ConfigMap/key from silently disabling OIDC.
*/}}
{{- define "wandb.oidc.configEnvs" -}}
  {{- $config := .Values.global.auth.oidc.oidcConfigMap | default dict -}}
  {{- if $config.name -}}
    {{- $keys := dict
    "GORILLA_OIDC_CLIENT_ID" $config.clientIdKey
    "OIDC_CLIENT_ID" $config.clientIdKey
    "GORILLA_OIDC_ISSUER" $config.issuerKey
    "OIDC_ISSUER" $config.issuerKey
    "GORILLA_AUTH_METHOD" $config.authMethodKey
    "OIDC_AUTH_METHOD" $config.authMethodKey
    "GORILLA_CORS_ORIGINS" $config.corsOriginsKey -}}
    {{- range $name, $key := $keys }}
- name: {{ $name }}
  valueFrom:
    configMapKeyRef:
      name: {{ $config.name | quote }}
      key: {{ $key | quote }}
    {{- end }}
  {{- end }}
{{- end -}}
