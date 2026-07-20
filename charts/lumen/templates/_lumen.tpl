{{- define "wandb.lumen.audience" -}}
{{- dig "lumen" "gcpWorkloadIdentity" "audience" "" .Values.global -}}
{{- end -}}

{{- define "wandb.lumen.dataRoot" -}}
{{- dig "lumen" "dataRoot" "" .Values.global -}}
{{- end -}}

{{- define "wandb.lumen.stagingPath" -}}
/vol/staging
{{- end -}}

{{- define "wandb.lumen.ducklakeRoot" -}}
{{- $configured := dig "config" "ducklakeRoot" "" .Values.ui -}}
{{- if $configured -}}
{{- $configured -}}
{{- else -}}
{{- $dataRoot := include "wandb.lumen.dataRoot" . -}}
{{- if $dataRoot -}}
{{- printf "%s/ducklake" (trimSuffix "/" $dataRoot) -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "wandb.lumen.uiFullname" -}}
{{- if .Values.ui.fullnameOverride -}}
{{- .Values.ui.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default "ui" .Values.ui.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "wandb.lumen.processorServiceAccountName" -}}
{{- if .Values.processor.serviceAccount.name -}}
{{- .Values.processor.serviceAccount.name -}}
{{- else if .Values.processor.fullnameOverride -}}
{{- .Values.processor.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default "processor" .Values.processor.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "wandb.lumen.validateUI" -}}
{{- if .Values.ui.enabled -}}
{{- if and (not .Values.ui.image.digest) (or (not .Values.ui.image.tag) (eq .Values.ui.image.tag "latest")) -}}
{{- fail "ui.image.tag must be an immutable tag, or ui.image.digest must be set, when ui.enabled=true" -}}
{{- end -}}
{{- $fetchImage := index .Values.ui.initContainers "fetch-reader" "image" -}}
{{- if and (not $fetchImage.digest) (or (not $fetchImage.tag) (eq $fetchImage.tag "latest")) -}}
{{- fail "ui.initContainers.fetch-reader.image.tag must be an immutable tag, or its digest must be set, when ui.enabled=true" -}}
{{- end -}}
{{- end -}}
{{- end -}}
