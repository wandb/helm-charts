{{/*
Handles merging a set of deployment annotations
*/}}
{{- define "wandb.deploymentAnnotations" -}}
{{- $allAnnotations := merge (default (dict) (default (dict) .Values.deployment).annotations) .Values.global.deployment.annotations -}}
{{- if $allAnnotations -}}
{{- toYaml $allAnnotations -}}
{{- end -}}
{{- end -}}

{{/*
Handles merging a set of deployment annotations
*/}}
{{- define "wandb.statefulsetAnnotations" -}}
{{- $allAnnotations := merge (default (dict) (default (dict) .Values.statefulset).annotations) .Values.global.statefulset.annotations -}}
{{- if $allAnnotations -}}
{{- toYaml $allAnnotations -}}
{{- end -}}
{{- end -}}

{{/*
Handles merging a set of deployment annotations
*/}}
{{- define "wandb.daemonsetAnnotations" -}}
{{- $allAnnotations := merge (default (dict) (default (dict) .Values.daemonset).annotations) .Values.global.daemonset.annotations -}}
{{- if $allAnnotations -}}
{{- toYaml $allAnnotations -}}
{{- end -}}
{{- end -}}

{{/*
Handles merging a set of service annotations
*/}}
{{- define "wandb.serviceAnnotations" -}}
{{- $allAnnotations := merge (default (dict) (default (dict) .Values.service).annotations) .Values.global.service.annotations -}}
{{- if $allAnnotations }}
{{- toYaml $allAnnotations -}}
{{- end -}}
{{- end -}}
