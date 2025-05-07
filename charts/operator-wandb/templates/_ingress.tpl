{{/*
Return the appropriate apiVersion for Ingress.

It expects a dictionary with three entries:
  - `global` which contains global ingress settings, e.g. .Values.global.ingress
  - `local` which contains local ingress settings, e.g. .Values.ingress
  - `context` which is the parent context (either `.` or `$`)

Example usage:
{{- $ingressCfg := dict "global" .Values.global.ingress "local" .Values.ingress "context" . -}}
kubernetes.io/ingress.provider: "{{ template "wandb.ingress.provider" $ingressCfg }}"
*/}}
{{- define "wandb.ingress.apiVersion" -}}
{{-   if .local.apiVersion -}}
{{-     .local.apiVersion -}}
{{-   else if .global.apiVersion -}}
{{-     .global.apiVersion -}}
{{-   else if .context.Capabilities.APIVersions.Has "networking.k8s.io/v1/Ingress" -}}
{{-     print "networking.k8s.io/v1" -}}
{{-   else if .context.Capabilities.APIVersions.Has "networking.k8s.io/v1beta1/Ingress" -}}
{{-     print "networking.k8s.io/v1beta1" -}}
{{-   else -}}
{{-     print "extensions/v1beta1" -}}
{{-   end -}}
{{- end -}}

{{/*
Returns the ingress provider

It expects a dictionary with two entries:
  - `global` which contains global ingress settings, e.g. .Values.global.ingress
  - `local` which contains local ingress settings, e.g. .Values.ingress
*/}}
{{- define "wandb.ingress.provider" -}}
{{- default .global.provider .local.provider -}}
{{- end -}}

{{- define "defaultHost" -}}
{{- replace "https://" "" (replace "http://" "" .Values.global.host) }}
{{- end -}}


{{- define "IngressPath" -}}
- pathType: Prefix
  path: /
  backend:
    service:
      {{- if eq $.Values.ingress.defaultBackend "console" }}
      name: {{ $.Release.Name }}-console
      port:
        number: 8082
      {{- else if $.Values.frontend.install }}
      name: {{ $.Release.Name }}-frontend
      port:
        number: 8080
      {{- else }}
      name: {{ $.Release.Name }}-app
      port: 
        number: 8080
      {{- end }}
{{- if .Values.global.api.enabled }}
- pathType: Prefix
  path: /api
  backend:
    service:
      name: {{ $.Release.Name }}-api
      port: 
        number: 8081
- pathType: Prefix
  path: /graphql
  backend:
    service:
      name: {{ $.Release.Name }}-api
      port: 
        number: 8081
{{- if .Values.global.api.additionalPaths.analytics }}
- pathType: Prefix
  path: /analytics
  backend:
    service:
      name: {{ $.Release.Name }}-api
      port:
        number: 8081
{{- end }}
{{- if .Values.global.api.additionalPaths.oidc }}
- pathType: Prefix
  path: /oidc
  backend:
    service:
      name: {{ $.Release.Name }}-api
      port:
        number: 8081
{{- end }}
{{- if .Values.global.api.additionalPaths.proxy }}
- pathType: Prefix
  path: /proxy
  backend:
    service:
      name: {{ $.Release.Name }}-api
      port:
        number: 8081
{{- end }}
{{- if .Values.global.api.additionalPaths.files }}
- pathType: Prefix
  path: /files
  backend:
    service:
      name: {{ $.Release.Name }}-api
      port:
        number: 8081
{{- end }}
{{- if .Values.global.api.additionalPaths.debug }}
- pathType: Prefix
  path: /debug
  backend:
    service:
      name: {{ $.Release.Name }}-api
      port:
        number: 8081
{{- end }}
{{- if .Values.global.api.additionalPaths.service_redirect }}
- pathType: Prefix
  path: /service-redirect
  backend:
    service:
      name: {{ $.Release.Name }}-api
      port:
        number: 8081
{{- end }}
{{- if .Values.global.api.additionalPaths.service_dangerzone }}
- pathType: Prefix
  path: /service-dangerzone
  backend:
    service:
      name: {{ $.Release.Name }}-api
      port:
        number: 8081
{{- end }}
{{- if .Values.global.api.additionalPaths.scim }}
- pathType: Prefix
  path: /scim
  backend:
    service:
      name: {{ $.Release.Name }}-api
      port:
        number: 8081
{{- end }}
{{- if .Values.global.api.additionalPaths.admin }}
- pathType: Prefix
  path: /admin/audit_logs
  backend:
    service:
      name: {{ $.Release.Name }}-api
      port:
        number: 8081
{{- end }}
{{- if .Values.global.api.additionalPaths.artifacts }}
- pathType: Prefix
  path: /artifacts
  backend:
    service:
      name: {{ $.Release.Name }}-api
      port:
        number: 8081
{{- end }}
{{- end }}
- pathType: Prefix
  path: /console
  backend:
    service:
      name: {{ $.Release.Name }}-console
      port:
        number: 8082
{{- end }}
