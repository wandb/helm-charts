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

