{{- define "wandb.commonLabels" -}}
{{- $commonLabels := merge (pluck "labels" (default (dict) .Values.common) | first) .Values.global.common.labels}}
{{- if $commonLabels }}
{{-   range $key, $value := $commonLabels }}
{{- if $key }}
{{ $key }}: {{ $value | quote }}
{{- end }}
{{-   end }}
{{- end -}}
{{- end -}}

{{- define "wandb.nodeSelector" -}}
{{- $nodeSelector := default .Values.global.nodeSelector .Values.nodeSelector -}}
{{- if $nodeSelector }}
nodeSelector:
  {{- toYaml $nodeSelector | nindent 2 }}
{{- end }}
{{- end -}}

{{/*
Handles merging a set of non-selector labels
*/}}
{{- define "wandb.podLabels" -}}
{{- $allLabels := merge (default (dict) .Values.podLabels) .Values.global.pod.labels -}}
{{- if $allLabels -}}
{{-   range $key, $value := $allLabels }}
{{ $key }}: {{ $value | quote }}
{{-   end }}
{{- end -}}
{{- end -}}

{{/*
Handles merging a set of labels for services
*/}}
{{- define "wandb.serviceLabels" -}}
{{- $allLabels := merge (default (dict) .Values.serviceLabels) .Values.global.service.labels -}}
{{- if $allLabels -}}
{{-   range $key, $value := $allLabels }}
{{ $key }}: {{ $value | quote }}
{{-   end }}
{{- end -}}
{{- end -}}

