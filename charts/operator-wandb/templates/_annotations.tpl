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

{{- define "wandb.gksFuseAnnotations" -}}
{{- /* https://cloud.google.com/kubernetes-engine/docs/how-to/cloud-storage-fuse-csi-driver-sidecar */ -}}
{{- if .Values.fuse.enabled }}
{{- if and (eq (include "wandb.bucket" . | fromYaml).provider "gcs") (eq .Values.global.cloudProvider "gcp") }}
gke-gcsfuse/volumes: "true"
{{- if index .Values.fuse.resources.limits "ephemeral-storage" }}
gke-gcsfuse/ephemeral-storage-limit: "{{ index .Values.fuse.resources.limits "ephemeral-storage" }}"
{{- end -}}
{{- if .Values.fuse.resources.requests.cpu }}
gke-gcsfuse/cpu-request: "{{ .Values.fuse.resources.requests.cpu }}"
gke-gcsfuse/metadata-prefetch-cpu-request: "{{ .Values.fuse.resources.requests.cpu }}"
{{- end -}}
{{- if .Values.fuse.resources.limits.cpu }}
gke-gcsfuse/cpu-limit: "{{ .Values.fuse.resources.limits.cpu }}"
gke-gcsfuse/metadata-prefetch-cpu-limit: "{{ .Values.fuse.resources.limits.cpu }}"
{{- end -}}
{{- if .Values.fuse.resources.requests.memory }}
gke-gcsfuse/memory-request: "{{ .Values.fuse.resources.requests.memory }}"
gke-gcsfuse/metadata-prefetch-memory-request: "{{ .Values.fuse.resources.requests.memory }}"
{{- end -}}
{{- if .Values.fuse.resources.limits.memory }}
gke-gcsfuse/memory-limit: "{{ .Values.fuse.resources.limits.memory }}"
gke-gcsfuse/metadata-prefetch-memory-limit: "{{ .Values.fuse.resources.limits.memory }}"
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
