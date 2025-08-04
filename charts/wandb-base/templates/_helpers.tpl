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
{{- if .Values.image.tag }}
app.kubernetes.io/version: {{ .Values.image.tag | trunc 63 | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "wandb-base.selectorLabels" -}}
app.kubernetes.io/name: {{ include "wandb-base.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "wandb-base.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "wandb-base.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "wandb-base.reloaderAnnotations" -}}
{{- $configmaps := "" }}
{{- $secrets := "" }}
{{- range $name, $type := .Values.envFrom }}
{{- if eq $type "configMapRef" }}
{{ $configmaps = printf "%s%s," $configmaps $name }}
{{- end -}}
{{- if eq $type "secretRef" }}
{{ $secrets = printf "%s%s," $secrets $name }}
{{- end -}}
{{- end -}}

{{- range .Values.containers }}
{{- range $name, $type := .envFrom }}
{{- if eq $type "configMapRef" }}
{{ $configmaps = printf "%s%s," $configmaps $name }}
{{- end -}}
{{- if eq $type "secretRef" }}
{{ $secrets = printf "%s%s," $secrets $name }}
{{- end -}}
{{- end -}}
{{- end -}}

{{- if $configmaps }}
configmap.reloader.stakater.com/reload: {{ $configmaps | trimSuffix "," }}
{{- end }}
{{- if $secrets }}
secret.reloader.stakater.com/reload: {{ $secrets | trimSuffix "," }}
{{- end }}
reloader.stakater.com/auto: "true"
{{- end }}

{{- define "wandb-base.sizingInfo" }}
{{- $size := default "" (coalesce .Values.size .Values.global.size) }}
{{- $sizingInfo := default (dict) (get .Values.sizing $size) }}
{{- $defaultSize := default (dict) (get .Values.sizing "default") }}
{{- $mergedSize := merge $sizingInfo $defaultSize }}

{{- toYaml $mergedSize }}
{{- end }}

{{- define "wandb-base.topologySpreadConstraints" }}
{{- $topologyConstraints := default (deepCopy .Values.topologySpreadConstraints) list }}
  {{- range $constraint := $topologyConstraints }}
  {{- $_ := set $constraint "labelSelector" (dict "matchLabels" (include "wandb-base.selectorLabels" $ | fromYaml)) }}
  {{- end }}
{{- toYaml $topologyConstraints }}
{{- end }}
