{{/*
Expand the name of the chart.
*/}}
{{- define "wandb-base.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "wandb-base.fullname" -}}
  {{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
  {{- else }}
    {{- $name := default (.Chart.Name | kebabcase) .Values.nameOverride }}
    {{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
    {{- else }}
      {{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
    {{- end }}
  {{- end }}
{{- end }}

{{- define "wandb-base.deploymentPostfix" -}}
  {{- if not (eq .Values.deploymentPostfix "") -}}
    {{- printf "-%s" .Values.deploymentPostfix -}}
  {{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "wandb-base.chart" -}}
  {{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "wandb-base.labels" -}}
helm.sh/chart: {{ include "wandb-base.chart" . }}
{{ include "wandb-base.selectorLabels" . }}
  {{- if .Values.image.digest }}
    {{/* spec won't allow ':' and recommended practice is to truncate to 12 chars */}}
app.kubernetes.io/version: {{ .Values.image.digest | trimPrefix "sha256:" | trunc 12 | quote }}
  {{- else if .Values.image.tag }}
app.kubernetes.io/version: {{ .Values.image.tag | trunc 63 | quote }}
  {{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
  {{- $commonLabels := merge (default (dict) .Values.common.labels) (default (dict) .Values.global.common.labels) }}
  {{- range $key, $value := $commonLabels }}
{{ $key }}: {{ $value | trunc 63 | quote }}
  {{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "wandb-base.selectorLabels" -}}
app.kubernetes.io/name: {{ include "wandb-base.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "wandb-base.helmHookAnnotations" -}}
  {{- $hook := required "Values.helmHook.hook must be set when helmHook.enabled is true" .Values.helmHook.hook -}}
"helm.sh/hook": {{ $hook | quote }}
  {{- if .Values.helmHook.hookWeight }}
"helm.sh/hook-weight": {{ .Values.helmHook.hookWeight | quote }}
  {{- end }}
  {{- if .Values.helmHook.hookDeletePolicy }}
"helm.sh/hook-delete-policy": {{ .Values.helmHook.hookDeletePolicy | quote }}
  {{- end }}
{{- end }}

{{/*
Create the name of the service to use
*/}}
{{- define "wandb-base.serviceName" -}}
{{- default (include "wandb-base.fullname" .) .Values.service.name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "wandb-base.serviceAccountName" -}}
  {{- if include "wandb-base.azureStorageServiceAccountEnabled" . | trim | eq "true" }}
{{- include "wandb-base.azureStorageServiceAccountName" . }}
  {{- else if .Values.serviceAccount.useWeaveTraceIdentity }}
{{- include "wandb-base.weaveTraceServiceAccountName" . }}
  {{- else if .Values.serviceAccount.create }}
{{- default (include "wandb-base.fullname" .) .Values.serviceAccount.name }}
  {{- else }}
{{- default "default" .Values.serviceAccount.name }}
  {{- end }}
{{- end }}

{{/*
Use the shared account only for workloads that already opt into Azure workload
identity. This keeps legacy bucket-scoped identities and key-based BYOB on
their component accounts.
*/}}
{{- define "wandb-base.azureStorageServiceAccountEnabled" -}}
  {{- $identity := default (dict) .Values.global.azureStorageIdentity -}}
  {{- $globalConfigured := and (not (empty $identity.tenantId)) (not (empty $identity.clientId)) -}}
  {{- $bucket := default (dict) .Values.global.bucket -}}
  {{- $hasCustomerBucket := not (empty $bucket.name) -}}
  {{- $defaultBucket := default (dict) .Values.global.defaultBucket -}}
  {{- $usesDeploymentIdentity := or
  (and (not $hasCustomerBucket) (eq $defaultBucket.provider "az"))
  (and $hasCustomerBucket (eq $bucket.azureAuthMethod "workloadIdentity"))
  -}}
  {{- $explicitSharedServiceAccount := default false .Values.azureStorageUseSharedServiceAccount -}}
  {{- if kindIs "string" $explicitSharedServiceAccount -}}
    {{- $explicitSharedServiceAccount = eq (tpl $explicitSharedServiceAccount . | trim) "true" -}}
  {{- end -}}
  {{- $podLabels := default (dict) .Values.podLabels -}}
  {{- $workloadIdentity := get $podLabels "azure.workload.identity/use" | default false -}}
  {{- $enabled := false -}}
  {{- if kindIs "string" $workloadIdentity -}}
    {{- $enabled = eq (tpl $workloadIdentity . | trim) "true" -}}
  {{- else -}}
    {{- $enabled = $workloadIdentity -}}
  {{- end -}}
{{- and $globalConfigured (or $usesDeploymentIdentity $explicitSharedServiceAccount) $enabled -}}
{{- end }}

{{- define "wandb-base.azureStorageServiceAccountName" -}}
  {{- $identity := default (dict) .Values.global.azureStorageIdentity -}}
  {{- $serviceAccount := default (dict) $identity.serviceAccount -}}
{{- default "wandb-bucket-access" $serviceAccount.name -}}
{{- end }}

{{/*
Create the name of the shared Weave Trace service account.
*/}}
{{- define "wandb-base.weaveTraceServiceAccountName" -}}
  {{- printf "%s-weave-trace" .Release.Name -}}
{{- end }}

{{- define "wandb-base.deploymentRolloutStrategy" -}}
  {{- if eq .Values.strategy.type "RollingUpdate"  }}
type: RollingUpdate
rollingUpdate:
  {{- toYaml .Values.strategy.rollingUpdate | nindent 2 }}
  {{ else if eq .Values.strategy.type "Recreate" }}
type: Recreate
  {{- end }}
{{- end }}

{{- define "wandb-base.statefulsetRolloutStrategy" -}}
  {{- if eq .Values.strategy.type "RollingUpdate"  }}
type: RollingUpdate
  {{ else if eq .Values.strategy.type "OnDelete" }}
type: OnDelete
  {{- end }}
{{- end }}

{{- define "wandb-base.sizingInfo" }}
  {{- $size := default "" (coalesce .Values.size .Values.global.size) }}
  {{- $sizingInfo := default (dict) (get .Values.sizing $size) }}
  {{- $defaultSize := default (dict) (get .Values.sizing "default") }}
  {{- $mergedSize := mergeOverwrite $defaultSize $sizingInfo }}

{{- toYaml $mergedSize }}
{{- end }}

{{- define "wandb-base.sizingInfoHorizontal" }}
  {{- $sizingInfo := fromYaml (include "wandb-base.sizingInfo" .) }}
  {{- $hpaSizing := mergeOverwrite $sizingInfo.autoscaling.horizontal .Values.autoscaling.horizontal }}

{{- toYaml $hpaSizing }}
{{- end }}

{{- define "wandb-base.sizingInfoKeda" }}
  {{- $sizingInfo := fromYaml (include "wandb-base.sizingInfo" .) }}
  {{- $kedaSizing := mergeOverwrite $sizingInfo.autoscaling.keda .Values.autoscaling.keda }}

{{- toYaml $kedaSizing }}
{{- end }}

{{- define "wandb-base.topologySpreadConstraints" }}
  {{- $topologyConstraints := default (deepCopy .Values.topologySpreadConstraints) list }}
  {{- range $constraint := $topologyConstraints }}
    {{- $_ := set $constraint "labelSelector" (dict "matchLabels" (include "wandb-base.selectorLabels" $ | fromYaml)) }}
  {{- end }}
{{- toYaml $topologyConstraints }}
{{- end }}

{{- define "wandb-base.replicaCount" }}
  {{- $desiredReplicas := .Values.replicaCount }}
  {{- $kedaSizing := fromYaml (include "wandb-base.sizingInfoKeda" .) }}
  {{- $hpaSizing := fromYaml (include "wandb-base.sizingInfoHorizontal" .) }}
  {{- if $kedaSizing.enabled }}
    {{- if $kedaSizing.minReplicaCount }}
      {{- $desiredReplicas = $kedaSizing.minReplicaCount }}
    {{- end }}
    {{- $scaledObject := lookup "keda.sh/v1alpha1" "ScaledObject" .Release.Namespace (include "wandb-base.fullname" . | trimAll "") }}
    {{- if and $scaledObject $scaledObject.status $scaledObject.status.hpaName }}
      {{- $hpa := lookup "autoscaling/v2" "HorizontalPodAutoscaler" .Release.Namespace $scaledObject.status.hpaName }}
      {{- if and $hpa (gt $hpa.status.currentReplicas 0) }}
        {{- $desiredReplicas = $hpa.status.currentReplicas }}
      {{- end }}
    {{- end }}
  {{- else if $hpaSizing.enabled }}
    {{- if $hpaSizing.replicaCount }}
      {{- $desiredReplicas = $hpaSizing.replicaCount }}
    {{- end }}
    {{- $hpa := lookup "autoscaling/v2" "HorizontalPodAutoscaler" .Release.Namespace (include "wandb-base.fullname" . | trimAll "") }}
    {{- if and $hpa (gt $hpa.status.currentReplicas 0) }}
      {{- $desiredReplicas = $hpa.status.currentReplicas }}
    {{- end }}
  {{- end }}
{{- print $desiredReplicas }}
{{- end }}

{{/*
Common annotations - merges global and local common annotations
*/}}
{{- define "wandb-base.commonAnnotations" -}}
  {{- $commonAnnotations := merge (default (dict) .Values.common.annotations) (default (dict) .Values.global.common.annotations) }}
  {{- if $commonAnnotations }}
{{- toYaml $commonAnnotations }}
  {{- end }}
{{- end }}
