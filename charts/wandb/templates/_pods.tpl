{{- define "wandb.priorityClassName" -}}
{{- $pcName := default .Values.global.priorityClassName .Values.priorityClassName -}}
{{- if $pcName }}
priorityClassName: {{ $pcName }}
{{- end -}}
{{- end -}}

{{/*
Return a PodSecurityContext definition.

Usage:
  {{ include "wandb.podSecurityContext" .Values.securityContext }}
*/}}
{{- define "wandb.podSecurityContext" -}}
{{- $psc := . }}
{{- if $psc }}
securityContext:
{{-   if not (empty $psc.runAsUser) }}
  runAsUser: {{ $psc.runAsUser }}
{{-   end }}
{{-   if not (empty $psc.runAsGroup) }}
  runAsGroup: {{ $psc.runAsGroup }}
{{-   end }}
{{-   if not (empty $psc.fsGroup) }}
  fsGroup: {{ $psc.fsGroup }}
{{-   end }}
{{-   if not (empty $psc.fsGroupChangePolicy) }}
  fsGroupChangePolicy: {{ $psc.fsGroupChangePolicy }}
{{-   end }}
{{- end }}
{{- end -}}

{{/*
Return container specific securityContext template
*/}}
{{- define "wandb.containerSecurityContext" }}
{{- if .Values.containerSecurityContext }}
securityContext:
  {{- toYaml .Values.containerSecurityContext | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Return init container specific securityContext template
*/}}
{{- define "wandb.init.containerSecurityContext" }}
{{- if .Values.init.containerSecurityContext }}
securityContext:
  {{- toYaml .Values.init.containerSecurityContext | nindent 2 }}
{{- end }}
{{- end }}

