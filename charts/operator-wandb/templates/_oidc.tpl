{{/* Use the named external ConfigMap, or the one rendered from inline values. */}}
{{- define "wandb.oidc.configMapName" -}}
  {{- $oidc := .Values.global.auth.oidc | default dict -}}
  {{- $configMap := $oidc.oidcConfigMap | default dict -}}
  {{- default (printf "%s-oidc-configmap" .Release.Name) $configMap.name -}}
{{- end -}}

{{- define "wandb.oidc.secretSecret" -}}
  {{- $oidc := .Values.global.auth.oidc | default dict -}}
  {{- $secret := $oidc.oidcSecret | default dict -}}
  {{- default (printf "%s-oidc-secret" .Release.Name) $secret.name -}}
{{- end -}}

{{/* Preserve the existing Secret key mapping for both application consumers. */}}
{{- define "wandb.oidcEnvs" -}}
  {{- $oidc := .Values.global.auth.oidc | default dict -}}
  {{- $secret := $oidc.oidcSecret | default dict -}}
  {{- $secretKey := $secret.secretKey | default "OIDC_SECRET" -}}
  {{- /* Always reference the chart-created Secret, even when empty, so Console can add or clear credentials with only a restart. */ -}}
- name: GORILLA_OIDC_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ include "wandb.oidc.secretSecret" . | quote }}
      key: {{ $secretKey | quote }}
  {{- if not $secret.name }}
      optional: true
  {{- end }}
- name: OIDC_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ include "wandb.oidc.secretSecret" . | quote }}
      key: {{ $secretKey | quote }}
  {{- if not $secret.name }}
      optional: true
  {{- end }}
{{- end -}}
