{{- define "wandb-base.containers" }}
{{- range .Values.containers}}
{{- $container := dict }}
{{- $_ := deepCopy . | merge $container }}
{{- $_ = set $container "securityContext" (coalesce $container.securityContext $.Values.securityContext) }}
{{- $_ = set $container "image" (coalesce $container.image $.Values.image) }}
{{- $_ = set $container "envFrom" (merge (default (dict) ($container.envFrom)) (default (dict) ($.Values.envFrom))) }}
{{- $_ = set $container "env" (merge (default (dict) ($container.env)) (default (dict) ($.Values.env))) }}
{{- $_ = set $container "root" $ }}
{{- include "wandb-base.container" $container }}
{{- end }}
{{- end }}

{{- define "wandb-base.initContainers" }}
{{- range .Values.initContainers}}
{{- $container := dict }}
{{- $_ := deepCopy . | merge $container }}
{{- $_ = set $container "securityContext" (coalesce $container.securityContext $.Values.securityContext) }}
{{- $_ = set $container "image" (coalesce $container.image $.Values.image) }}
{{- $_ = set $container "envFrom" (merge (default (dict) ($container.envFrom)) (default (dict) ($.Values.envFrom))) }}
{{- $_ = set $container "env" (merge (default (dict) ($container.env)) (default (dict) ($.Values.env))) }}
{{- $_ = set $container "root" $ }}
{{- include "wandb-base.container" $container }}
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
  {{- with .volumeMounts }}
  volumeMounts:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end }}

{{- define "wandb-base.env" }}
{{- range $key, $value := .env }}
{{- if kindIs "string" $value }}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- else }}
- name: {{ $key }}
{{- toYaml $value | nindent 2 }}
{{- end }}
{{- end }}
{{- end }}

{{- define "wandb-base.envFrom" }}
{{- range $key, $value := .envFrom }}
- {{ $value }}:
    name: {{ $key }}
{{- end }}
{{- end }}
