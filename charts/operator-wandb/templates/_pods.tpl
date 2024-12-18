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
Return a simplified topologySpreadConstraints definition with dynamic labelSelector and matchLabels passed as a map.
*/}}
{{- define "wandb.topologySpreadConstraints" -}}
{{- $matchLabels := .matchLabels -}}
topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: kubernetes.io/hostname
    whenUnsatisfiable: ScheduleAnyway
    labelSelector:
      matchLabels:
        {{- range $key, $value := $matchLabels }}
        {{ $key }}: {{ $value | quote }}
        {{- end }}
  - maxSkew: 1
    topologyKey: topology.kubernetes.io/zone
    whenUnsatisfiable: ScheduleAnyway
    labelSelector:
      matchLabels:
        {{- range $key, $value := $matchLabels }}
        {{ $key }}: {{ $value | quote }}
        {{- end }}
{{- end }}

