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
  {{- if hasKey $psc "runAsUser" }}
  runAsUser: {{ $psc.runAsUser }}
  {{- end }}
  {{- if hasKey $psc "runAsGroup" }}
  runAsGroup: {{ $psc.runAsGroup }}
  {{- end }}
  {{- if hasKey $psc "fsGroup" }}
  fsGroup: {{ $psc.fsGroup | int }}
  {{- end }}
  {{- if hasKey $psc "fsGroupChangePolicy" }}
  fsGroupChangePolicy: {{ $psc.fsGroupChangePolicy }}
  {{- end }}
  {{- if hasKey $psc "runAsNonRoot" }}
  runAsNonRoot: {{ $psc.runAsNonRoot }}
  {{- end }}
  {{- if hasKey $psc "allowPrivilegeEscalation" }}
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
  {{- if kindIs "map" $csc.capabilities }}
  capabilities:
    {{- if gt (len $csc.capabilities.add) 0 }}
    add:
      {{- range $c := $csc.capabilities.add }}
      - {{ $c }}
      {{- end }}
    {{- end }}
    {{- if gt (len $csc.capabilities.drop) 0 }}
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


{{/*
Return a soft nodeAffinity definition
{{ include "wandb.nodeAffinity.soft" (dict "key" "FOO" "values" (list "BAR" "BAZ")) -}}
*/}}

{{- define "wandb.nodeAffinity.soft" -}}
preferredDuringSchedulingIgnoredDuringExecution:
  - preference:
      matchExpressions:
        - key: {{ .key }}
          operator: In
          values:
            {{- range .values }}
            - {{ . | quote }}
            {{- end }}
    weight: 1
{{- end -}}

{{/*
Return a hard nodeAffinity definition
{{ include "wandb.nodeAffinity.hard" (dict "key" "FOO" "values" (list "BAR" "BAZ")) -}}
*/}}

{{- define "wandb.nodeAffinity.hard" -}}
requiredDuringSchedulingIgnoredDuringExecution:
  nodeSelectorTerms:
    - matchExpressions:
        - key: {{ .key }}
          operator: In
          values:
            {{- range .values }}
            - {{ . | quote }}
            {{- end }}
{{- end -}}

{{/*
Return a nodeAffinity definition
*/}}
{{- define "wandb.nodeAffinity.type" -}}
  {{- if eq .type "soft" }}
    {{- include "wandb.nodeAffinity.soft" . -}}
  {{- else if eq .type "hard" }}
    {{- include "wandb.nodeAffinity.hard" . -}}
  {{- end -}}
{{- end -}}
