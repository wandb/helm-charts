{{/* Use the named external ConfigMap, or the one rendered from inline values. */}}
{{- define "wandb.oidc.configMapName" -}}
  {{- default (printf "%s-oidc-configmap" .Release.Name) .Values.global.auth.oidc.oidcConfigMap.name -}}
{{- end -}}

{{- define "wandb.oidc.secretSecret" -}}
  {{- default (printf "%s-oidc-secret" .Release.Name) .Values.global.auth.oidc.oidcSecret.name -}}
{{- end -}}

{{/* Preserve the existing Secret key mapping for both application consumers. */}}
{{- define "wandb.oidcEnvs" -}}
  {{- $oidc := .Values.global.auth.oidc -}}
  {{- $enabled := or $oidc.secret $oidc.oidcSecret.name -}}
  {{- if not $oidc.oidcSecret.name -}}
    {{- $name := include "wandb.oidc.secretSecret" . -}}
    {{- $existing := lookup "v1" "Secret" .Release.Namespace $name | default dict -}}
    {{- $metadata := get $existing "metadata" | default dict -}}
    {{- $annotations := get $metadata "annotations" | default dict -}}
    {{- if eq (get $annotations "wandb.ai/console-managed") "true" -}}
      {{- /* Console-owned credentials remain usable after removing inline values; empty credentials disable the reference. */ -}}
      {{- $data := get $existing "data" | default dict -}}
      {{- $enabled = not (empty (get $data $oidc.oidcSecret.secretKey)) -}}
    {{- end -}}
  {{- end -}}
  {{- if $enabled }}
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
