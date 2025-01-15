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
Handles merging a set of service annotations
*/}}
{{- define "wandb.serviceAnnotations" -}}
{{- $allAnnotations := merge (default (dict) (default (dict) .Values.service).annotations) .Values.global.service.annotations -}}
{{- if $allAnnotations }}
{{- toYaml $allAnnotations -}}
{{- end -}}
{{- end -}}

{{/*
Create the ownerReferences object dynamically for WeightsAndBaises resources in the same namespace.
This function adds ownerReferences only when the enableOwnerReferences flag is set to true in values.yaml.
It also includes error handling to ensure the lookup result is valid.
*/}}

{{- define "wandb.ownerReference" -}}
{{- if .Values.global.enableOwnerReferences }}
{{- $resource := (lookup "apps.wandb.com/v1" "WeightsAndBiases" .Release.Namespace "wandb") }}
{{- if $resource }}
ownerReferences:
  - apiVersion: apps.wandb.com/v1
    blockOwnerDeletion: true
    controller: true
    kind: WeightsAndBiases
    name: {{ $resource.metadata.name }}
    uid: {{ $resource.metadata.uid }}
{{- end }}
{{- end }}
{{- end }}
