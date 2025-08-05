{{/*
  wandb-base.containers should be passed a dict with key `containers` containing the map of containers and a key `root`
  containing the . from the calling context
 */}}
{{- define "wandb-base.containers" -}}
  {{- range $containerName, $containerSource := .containers -}}
    {{- $container := dict }}
    {{- $_ := deepCopy $containerSource | merge $container }}
    {{- $_ = set $container "name" $containerName }}
    {{- $_ = set $container "securityContext" (coalesce $container.securityContext (merge $.root.Values.securityContext $.root.Values.container.securityContext)) }}
    {{- $_ = set $container "image" (coalesce $container.image $.root.Values.image) }}
    {{- $_ = set $container "envTpls" $.root.Values.envTpls }}
    {{- $_ = set $container "envFrom" (merge (default (dict) ($container.envFrom)) (default (dict) ($.root.Values.envFrom))) }}
    {{- $_ = set $container "env" (merge (default (dict) ($container.env)) (default (dict) ($.root.Values.env)) $.root.Values.extraEnv $.root.Values.global.env $.root.Values.global.extraEnv) }}
    {{- $_ = set $container "root" $.root }}
    {{- if eq $.source "containers" }}
      {{/* Merge in resources from .Values.resources to support legacy chart values */}}
      {{- $_ = set $container "resources" (merge (default (dict) ($.root.Values.resources)) (default (dict) ($container.resources))) }}

      {{- $sizingInfo := fromYaml (include "wandb-base.sizingInfo" $.root) }}
      {{- if $sizingInfo  }}
        {{- $_ = set $container "resources" (merge (default (dict) ($container.resources)) (default (dict) ($sizingInfo.resources))) }}
      {{- end }}

      {{- if $sizingInfo.env }}
        {{- $_ = set $container "env" (merge (default (dict) ($container.env)) (default (dict) ($sizingInfo.env))) }}
      {{- end }}
    {{- end }}
    {{ include "wandb-base.container" $container }}
  {{- end }}
{{- end }}

{{- define "wandb-base.container" }}
- name: {{ .name }}
  {{- if .command }}
  command:
    {{- toYaml .command | nindent 4 }}
  {{- end }}
  {{- if .args }}
  args:
    {{- toYaml .args | nindent 4 }}
  {{- end }}
  envFrom:
  {{- if .envFrom }}
    {{- tpl (include "wandb-base.envFrom" . | nindent 4) $.root }}
  {{- end }}
  env:
  {{- if .envTpls }}
    {{- range .envTpls }}
    {{- tpl . $.root | nindent 4 }}
    {{- end }}
  {{- end }}
  {{- if .env }}
    {{- tpl (include "wandb-base.env" . | nindent 4) $.root }}
  {{- end }}
  {{- if .securityContext }}
  securityContext:
    {{- toYaml .securityContext | nindent 4 }}
  {{- end }}
  image: "{{ .image.repository }}:{{ .image.tag }}"
  imagePullPolicy: {{ .image.pullPolicy }}
  {{- with .ports }}
  ports:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- if .livenessProbe }}
  livenessProbe:
    {{- toYaml .livenessProbe | nindent 4 }}
  {{- end }}
  {{- if .readinessProbe }}
  readinessProbe:
    {{- toYaml .readinessProbe | nindent 4 }}
  {{- end }}
  {{- if .startupProbe }}
  startupProbe:
    {{- toYaml .startupProbe | nindent 4 }}
  {{- end }}
  {{- if .lifecycle }}
  lifecycle:
    {{- toYaml .lifecycle | nindent 4 }}
  {{- end }}
  {{- if .resources }}
  resources:
    {{- toYaml .resources | nindent 4 }}
  {{- end }}
  {{- if or .volumeMounts .volumeMountsTpls }}
  volumeMounts:
    {{- range .volumeMountsTpls }}
{{ tpl . $.root | indent 4 }}
    {{- end }}
    {{- if .volumeMounts }}
{{ tpl (toYaml .volumeMounts | nindent 4) $.root }}
    {{- end }}
  {{- end }}
{{- end }}

{{- define "wandb-base.env" -}}
{{- range $key, $value := .env -}}
{{- if kindIs "map" $value }}
- name: {{ $key }}
{{- toYaml $value | nindent 2 }}
{{- else }}
- name: {{ $key }}
  value: {{ toString $value | quote }}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "wandb-base.envFrom" -}}
{{- range $key, $value := .envFrom }}
- {{ $value }}:
    name: {{ $key }}
{{- end }}
{{- end }}
