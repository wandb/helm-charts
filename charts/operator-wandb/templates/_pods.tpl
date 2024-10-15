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
  {{- if not (empty $psc.runAsUser) }}
  runAsUser: {{ $psc.runAsUser }}
  {{- end }}
  {{- if not (empty $psc.runAsGroup) }}
  runAsGroup: {{ $psc.runAsGroup }}
  {{- end }}
  {{- if not (empty $psc.runAsNonRoot) }}
  fsGroup: {{ $psc.runAsNonRoot }}
  {{- end }}
  {{- if not (empty $psc.fsGroup) }}
  fsGroup: {{ $psc.fsGroup }}
  {{- end }}
  {{- if not (empty $psc.fsGroupChangePolicy) }}
  fsGroupChangePolicy: {{ $psc.fsGroupChangePolicy }}
  {{- end }}
  {{- if not (empty $psc.seccompProfile.type) }}
  seccompProfile:
        type: {{ $psc.seccompProfile.type }}
  {{- end }}
{{- end }}
{{- end -}}

{{/*
Return container specific securityContext template
*/}}
{{- define "wandb.containerSecurityContext" -}}
{{- $csc := . -}}
{{- if $csc }}
securityContext:
  {{- if or (not (empty $csc.capabilities.add)) (not (empty $csc.capabilities.drop)) }}
  capabilities:
    {{- if not (empty $csc.capabilities.add) }}
    add:
    {{- range $c := $csc.capabilities.add }}
      - {{ $c }}
    {{- end }}
    {{- end }}
    {{- if not (empty $csc.capabilities.drop) }}
    drop:
    {{- range $c := $csc.capabilities.drop }}
      - {{ $c }}
    {{- end }}
    {{- end }}
  {{- end }}
  {{- if not (empty $csc.allowPrivilegeEscalation) }}
  allowPrivilegeEscalation: {{ $csc.allowPrivilegeEscalation }}
  {{- end }}
  {{- if not (empty $csc.readOnlyRootFilesystem) }}
  readOnlyRootFilesystem: {{ $csc.readOnlyRootFilesystem }}
  {{- end }}
{{- end }}
{{- end -}}

{{/*
Return init container specific securityContext template
*/}}
{{- define "wandb.init.containerSecurityContext" }}
{{- if .Values.init.containerSecurityContext }}
securityContext:
  {{- toYaml .Values.init.containerSecurityContext | nindent 2 }}
{{- end }}
{{- end }}

