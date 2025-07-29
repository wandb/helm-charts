{{/*
This file contains templates for deprecated features, added for backward compatibility with older versions of the chart.
*/}}

{{/*
Handles merging a set of deployment annotations
*/}}
{{- define "wandb-base.deploymentAnnotations" -}}
{{- $allAnnotations := merge (default (dict) (default (dict) .Values.deployment).annotations) .Values.global.deployment.annotations -}}
{{- if $allAnnotations -}}
{{- toYaml $allAnnotations -}}
{{- end -}}
{{- end -}}

{{/*
Handles merging a set of deployment annotations
*/}}
{{- define "wandb-base.statefulsetAnnotations" -}}
{{- $allAnnotations := merge (default (dict) (default (dict) .Values.statefulset).annotations) .Values.global.statefulset.annotations -}}
{{- if $allAnnotations -}}
{{- toYaml $allAnnotations -}}
{{- end -}}
{{- end -}}

{{/*
Handles merging a set of service annotations
*/}}
{{- define "wandb-base.serviceAnnotations" -}}
{{- $allAnnotations := merge (default (dict) (default (dict) .Values.service).annotations) .Values.global.service.annotations -}}
{{- if $allAnnotations }}
{{- toYaml $allAnnotations -}}
{{- end -}}
{{- end -}}

{{/*
Handles merging a set of pod annotations
*/}}
{{- define "wandb-base.podAnnotations" -}}
{{- $allAnnotations := merge (default (dict) (default (dict) .Values.pod).annotations) .Values.global.pod.annotations -}}
{{- if $allAnnotations }}
{{- toYaml $allAnnotations -}}
{{- end -}}
{{- end -}}

{{/*
Handles merging a set of non-selector labels
*/}}
{{- define "wandb.podLabels" -}}
{{- $allLabels := merge .Values.podLabels .Values.global.pod.labels -}}
{{- if $allLabels -}}
{{-   range $key, $value := $allLabels }}
{{ $key }}: {{ $value | trunc 63 | quote }}
{{-   end }}
{{- end -}}
{{- end -}}

{{/*
Handles merging a set of labels for services
*/}}
{{- define "wandb.serviceLabels" -}}
{{- $allLabels := merge .Values.serviceLabels .Values.global.service.labels -}}
{{- if $allLabels -}}
{{-   range $key, $value := $allLabels }}
{{ $key }}: {{ $value | trunc 63 | quote }}
{{-   end }}
{{- end -}}
{{- end -}}