{{- define "wandb-service.containers" }}
{{- range .Values.containers}}
{{- $container := dict }}
{{- $_ := deepCopy . | merge $container }}
{{- $_ = set $container "securityContext" (coalesce $container.securityContext $.Values.securityContext) }}
{{- $_ = set $container "image" (coalesce $container.image $.Values.image) }}
{{- $_ = set $container "envFrom" (concat $container.envFrom $.Values.envFrom) }}
{{- $_ = set $container "env" (concat $container.env $.Values.env) }}
{{- $_ = set $container "root" $ }}
{{- include "wandb-service.container" $container }}
{{- end }}
{{- end }}

{{- define "wandb-service.initContainers" }}
{{- range .Values.initContainers}}
{{- $container := merge . }}
{{- $_ := set $container "securityContext" (coalesce $container.securityContext $.Values.securityContext) }}
{{- $_ = set $container "image" (coalesce $container.image $.Values.image) }}
{{- $_ = set $container "envFrom" (concat $container.envFrom $.Values.envFrom) }}
{{- $_ = set $container "env" (concat $container.env $.Values.env) }}
{{- $_ = set $container "root" $ }}
{{- include "wandb-service.container" $container }}
{{- end }}
{{- end }}

{{- define "wandb-service.container" }}
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
  {{- with .envFrom }}
    {{- tpl (toYaml . | nindent 4) $.root }}
  {{- end }}
  env:
  {{- with .env }}
    {{- tpl (toYaml . | nindent 4) $.root }}
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
  {{ if .startupProbe }}
  startupProbe:
    {{- toYaml .startupProbe | nindent 4 }}
  {{ end }}
  {{ if .lifecycle }}
  lifecycle:
    {{- toYaml .lifecycle | nindent 4 }}
  {{ end }}
  {{ if .resources }}
  resources:
    {{- toYaml .resources | nindent 4 }}
  {{ end }}
  {{- with .volumeMounts }}
  volumeMounts:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end }}