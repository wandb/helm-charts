{{/* Use the named external ConfigMap, or the one rendered from inline values. */}}
{{- define "wandb.oidc.configMapName" -}}
  {{- default (printf "%s-oidc-configmap" .Release.Name) .Values.global.auth.oidc.oidcConfigMap.name -}}
{{- end -}}

{{- define "wandb.oidc.secretSecret" -}}
  {{- default (printf "%s-oidc-secret" .Release.Name) .Values.global.auth.oidc.oidcSecret.name -}}
{{- end -}}

{{/* Preserve the existing Secret key mapping for both application consumers. */}}
{{- define "wandb.oidcEnvs" -}}
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
