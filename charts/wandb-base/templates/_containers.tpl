{{/*
  wandb-base.containers should be passed a dict with key `containers` containing the map of containers and a key `root`
  containing the . from the calling context
 */}}
{{- define "wandb-base.containers" -}}
  {{- range $containerName, $containerSource := .containers -}}
    {{- $enabled := true -}}
    {{- if hasKey $containerSource "enabled" -}}
        {{- $enabledValue := $containerSource.enabled -}}
        {{- if kindIs "string" $enabledValue -}}
          {{- $enabled = eq (tpl $enabledValue $.root | trim) "true" -}}
        {{- else -}}
          {{- $enabled = $enabledValue -}}
        {{- end -}}
    {{- end -}}
    {{- if $enabled -}}
      {{- $container := dict }}
      {{- $_ := deepCopy $containerSource | merge $container -}}
      {{- $_ = set $container "name" $containerName -}}
      {{- $_ = set $container "securityContext" (coalesce $container.securityContext (merge $.root.Values.securityContext $.root.Values.container.securityContext)) -}}
      {{- $_ = set $container "image" (coalesce $container.image $.root.Values.image) }}
      {{- $_ = set $container "envFrom" (merge (default (dict) ($container.envFrom)) (default (dict) ($.root.Values.envFrom))) -}}
      {{- $_ = set $container "env" (merge (default (dict) ($container.env)) (default (dict) ($.root.Values.env)) $.root.Values.extraEnv $.root.Values.global.env $.root.Values.global.extraEnv) -}}
      {{- $_ = set $container "root" $.root -}}
      {{- if eq $.source "containers" }}
        {{/* Merge in resources from .Values.resources to support legacy chart values */}}
        {{- $_ = set $container "resources" (merge (default (dict) ($container.resources)) (default (dict) ($.root.Values.resources))) -}}

        {{- $sizingInfo := fromYaml (include "wandb-base.sizingInfo" $.root) -}}
        {{- if $sizingInfo -}}
          {{- $_ = set $container "resources" (merge (default (dict) ($container.resources)) (default (dict) ($sizingInfo.resources))) -}}
        {{- end -}}

        {{- if $sizingInfo.env }}
          {{- $_ = set $container "env" (merge (default (dict) ($container.env)) (default (dict) ($sizingInfo.env))) -}}
        {{- end -}}
      {{- end -}}

      {{- /* We prerender the envTpls and put them into an array for searching */ -}}
      {{- $envTpls := list }}
      {{- if $.root.Values.envTpls -}}
        {{- range $.root.Values.envTpls }}
          {{- $envTpls = concat $envTpls (tpl . $.root | fromYamlArray) -}}
        {{- end -}}
      {{- end -}}

      {{- /* Iterate over the envvars rendered from envTpls, and remove any specified in env to avoid setElementOrder errors */ -}}
      {{- range $index, $envVar := $envTpls }}
        {{- if hasKey $container.env $envVar.name -}}
          {{- $envTpls = without $envTpls $envVar -}}
        {{- end -}}
      {{- end -}}
      {{- $_ = set $container "envTpls" $envTpls -}}

      {{ include "wandb-base.container" $container }}
    {{- end -}}
  {{- end -}}
{{- end -}}

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
    {{- .envTpls | toYaml | nindent 4 }}
  {{- end }}
  {{- if .env }}
    {{- tpl (include "wandb-base.env" . | nindent 4) $.root }}
  {{- end }}
  {{- if .securityContext }}
  securityContext:
    {{- toYaml .securityContext | nindent 4 }}
  {{- end }}
  {{- $repository := .image.repository }}
  {{- if $.root.Values.global.repositoryPrefix }}
    {{- $repository = printf "%s/%s" $.root.Values.global.repositoryPrefix $repository }}
  {{- end }}

  {{- if .imageTpl }}
  image:
  {{ tpl .imageTpl $.root | nindent 4 }}
  {{- else if .image.digest }}
  image: "{{ $repository }}@{{ .image.digest }}"
  {{- else if .image.tag }}
  image: "{{ $repository }}:{{ .image.tag }}"
  {{- else }}
  image: "{{ $repository }}:latest"
  {{- end }}
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

  {{- $localVolumeMounts := default list .volumeMounts }}
  {{- $globalVolumeMounts := default list $.root.Values.global.volumeMounts }}
  {{- $localVolumeMountTpls := default list .volumeMountsTpls }}
  {{- $globalVolumeMountTpls := default list $.root.Values.global.volumeMountsTpls }}
  {{- $volumeMountNames := list }}
  {{- $combinedVolumeMounts := list }}
  {{- range $volumeMount := $localVolumeMounts }}
    {{- $combinedVolumeMounts = append $combinedVolumeMounts $volumeMount }}
    {{- if and (kindIs "map" $volumeMount) (hasKey $volumeMount "name") }}
      {{- $volumeMountNames = append $volumeMountNames $volumeMount.name }}
    {{- end }}
  {{- end }}
  {{- range $volumeMount := $globalVolumeMounts }}
    {{- if and (kindIs "map" $volumeMount) (hasKey $volumeMount "name") }}
      {{- if not (has $volumeMount.name $volumeMountNames) }}
        {{- $combinedVolumeMounts = append $combinedVolumeMounts $volumeMount }}
        {{- $volumeMountNames = append $volumeMountNames $volumeMount.name }}
      {{- end }}
    {{- else }}
      {{- $combinedVolumeMounts = append $combinedVolumeMounts $volumeMount }}
    {{- end }}
  {{- end }}
  {{- $combinedVolumeMountTpls := concat $localVolumeMountTpls $globalVolumeMountTpls }}
  {{- if or $combinedVolumeMounts $combinedVolumeMountTpls }}
  volumeMounts:
    {{- range $combinedVolumeMountTpls }}
{{ tpl . $.root | indent 4 }}
    {{- end }}
    {{- if $combinedVolumeMounts }}
{{ tpl (toYaml $combinedVolumeMounts | nindent 4) $.root }}
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
