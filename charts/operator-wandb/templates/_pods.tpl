{{- define "wandb.priorityClassName" -}}
{{- $pcName := default .Values.global.priorityClassName .Values.priorityClassName -}}
{{- if $pcName }}
priorityClassName: {{ $pcName }}
{{- end -}}
{{- end -}}

{{/*
Return a PodSecurityContext definition.
*/}}
{{- define "wandb.podSecurityContext" -}}
{{- $psc := . | default dict }}
securityContext:
  {{- if not (empty $psc.runAsUser) }}
  runAsUser: {{ $psc.runAsUser }}
  {{- end }}
  {{- if not (empty $psc.runAsGroup) }}
  runAsGroup: {{ $psc.runAsGroup }}
  {{- end }}
  {{- if not (empty $psc.fsGroup) }}
  fsGroup: {{ $psc.fsGroup | int }}
  {{- end }}
  {{- if not (empty $psc.fsGroupChangePolicy) }}
  fsGroupChangePolicy: {{ $psc.fsGroupChangePolicy }}
  {{- end }}
  {{- if not (empty $psc.runAsNonRoot) }}
  runAsNonRoot: {{ $psc.runAsNonRoot }}
  {{- end }}
  {{- if not (empty $psc.allowPrivilegeEscalation) }}
  allowPrivilegeEscalation: {{ $psc.allowPrivilegeEscalation }}
  {{- end }}
  {{- if and (kindIs "map" $psc.seccompProfile) (not (empty $psc.seccompProfile.type)) }}
  seccompProfile:
    type: {{ $psc.seccompProfile.type }}
  {{- end }}
{{- end }}

{{/*
Return container-specific securityContext template.
*/}}
{{- define "wandb.containerSecurityContext" -}}
{{- $csc := . | default dict }}
{{- if $csc }}
securityContext:
  {{- if $csc.capabilities }}
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
  {{- if hasKey $csc "allowPrivilegeEscalation" }}
  allowPrivilegeEscalation: {{ $csc.allowPrivilegeEscalation }}
  {{- end }}
  {{- if hasKey $csc "readOnlyRootFilesystem" }}
  readOnlyRootFilesystem: {{ $csc.readOnlyRootFilesystem }}
  {{- end }}
  {{- if hasKey $csc "runAsUser" }}
  runAsUser: {{ $csc.runAsUser }}
  {{- end }}
  {{- if hasKey $csc "runAsNonRoot" }}
  runAsNonRoot: {{ $csc.runAsNonRoot }}
  {{- end }}
  {{- if hasKey $csc "runAsGroup" }}
  runAsGroup: {{ $csc.runAsGroup }}
  {{- end }}
  {{- if hasKey $csc "privileged" }}
  privileged: {{ $csc.privileged }}
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

