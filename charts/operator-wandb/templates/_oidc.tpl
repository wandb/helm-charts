{{/*
Return the normalized OIDC configuration so every template can safely consume
an absent, null, or partial global.auth.oidc map.
*/}}
{{- define "wandb.oidc.config" -}}
  {{- $global := default (dict) .Values.global -}}
  {{- $auth := default (dict) (get $global "auth") -}}
  {{- $oidc := default (dict) (get $auth "oidc") -}}
  {{- $oidcSecret := default (dict) (get $oidc "oidcSecret") -}}
  {{- toYaml (dict
    "clientId" (default "" (get $oidc "clientId"))
    "secret" (default "" (get $oidc "secret"))
    "authMethod" (default "" (get $oidc "authMethod"))
    "issuer" (default "" (get $oidc "issuer"))
    "oidcSecret" (dict
      "name" (default "" (get $oidcSecret "name"))
      "secretKey" (default "OIDC_SECRET" (get $oidcSecret "secretKey"))
  )) -}}
{{- end -}}

{{/*
Return the name of the secret where OIDC secret is stored, considering if the custom secret is defined
*/}}
{{- define "wandb.oidc.secretSecret" -}}
  {{- $oidc := include "wandb.oidc.config" . | fromYaml -}}
  {{- if $oidc.oidcSecret.name }}
  {{- $oidc.oidcSecret.name -}}
  {{- else }}
  {{- print .Release.Name "-oidc-secret" -}}
  {{- end -}}
{{- end -}}
