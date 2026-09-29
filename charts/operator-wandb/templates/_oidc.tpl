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
  {{- $enabled := or $oidc.secret $secret.name -}}
  {{- if not $secret.name -}}
    {{- $name := include "wandb.oidc.secretSecret" . -}}
    {{- $existing := lookup "v1" "Secret" .Release.Namespace $name | default dict -}}
    {{- $metadata := get $existing "metadata" | default dict -}}
    {{- $annotations := get $metadata "annotations" | default dict -}}
    {{- if eq (get $annotations "wandb.ai/console-managed") "true" -}}
      {{- /* Console-owned credentials remain usable after removing inline values; empty credentials disable the reference. */ -}}
      {{- $data := get $existing "data" | default dict -}}
      {{- $enabled = not (empty (get $data $secretKey)) -}}
    {{- end -}}
  {{- end -}}
  {{- if $enabled }}
- name: GORILLA_OIDC_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ include "wandb.oidc.secretSecret" . | quote }}
      key: {{ $secretKey | quote }}
- name: OIDC_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ include "wandb.oidc.secretSecret" . | quote }}
      key: {{ $secretKey | quote }}
  {{- end }}
{{- end -}}
