{{/*
  A helper template for collecting and inserting the imagePullSecrets.

  It expects a dictionary with two entries:
    - `global` which contains global image settings, e.g. .Values.global.image
    - `local` which contains local image settings, e.g. .Values.image
*/}}
{{- define "wandb.image.pullSecrets" -}}
{{- $pullSecrets := default (list) .global.pullSecrets -}}
{{- if .local.pullSecrets -}}
{{-   $pullSecrets = concat $pullSecrets .local.pullSecrets -}}
{{- end -}}
{{- if $pullSecrets }}
imagePullSecrets:
{{-   range $index, $entry := $pullSecrets }}
- name: {{ $entry.name }}
{{-   end }}
{{- end }}
{{- end -}}

{{/*
  A helper template for inserting imagePullPolicy.

  It expects a dictionary with two entries:
    - `global` which contains global image settings, e.g. .Values.global.image
    - `local` which contains local image settings, e.g. .Values.image
*/}}
{{- define "wandb.image.pullPolicy" -}}
{{- $pullPolicy := coalesce .local.pullPolicy .global.pullPolicy -}}
{{- if $pullPolicy }}
imagePullPolicy: {{ $pullPolicy | quote }}
{{- end -}}
{{- end -}}
