{{/*
Expand the name of the chart.
*/}}
{{- define "glue.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "glue.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "glue.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "glue.labels" -}}
helm.sh/chart: {{ include "glue.chart" . }}
{{ include "glue.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Returns the extraEnv keys and values to inject into containers.

Global values will override any chart-specific values.
*/}}
{{- define "glue.extraEnv" -}}
{{- $allExtraEnv := merge (default (dict) .local.extraEnv) .global.extraEnv -}}
{{- range $key, $value := $allExtraEnv }}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- end -}}
{{- end -}}

{{/*
Returns a list of _common_ labels to be shared across all
glue deployments and other shared objects.
*/}}
{{- define "glue.commonLabels" -}}
{{- $commonLabels := default (dict) .Values.common.labels -}}
{{- if $commonLabels }}
{{-   range $key, $value := $commonLabels }}
{{ $key }}: {{ $value | quote }}
{{-   end }}
{{- end -}}
{{- end -}}

{{/*
Returns a list of _pod_ labels to be shared across all
glue deployments.
*/}}
{{- define "glue.podLabels" -}}
{{- range $key, $value := .Values.pod.labels }}
{{ $key }}: {{ $value | quote }}
{{- end }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "glue.selectorLabels" -}}
app.kubernetes.io/name: {{ include "glue.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "glue.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "glue.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "glue.redis" -}}
{{- $cs := include "wandb.redis.connectionString" . }}
{{- $ca := include "wandb.redis.caCert" . }}
{{- if $ca }}
{{- printf "%s?tls=true&caCertPath=/etc/ssl/certs/redis_ca.pem&ttlInSeconds=604800" $cs -}}
{{- else }}
{{- print $cs -}}
{{- end }}
{{- end }}

{{- define "glue.bucket" -}}
{{- $bucketValues := .Values.global.defaultBucket }}
{{- if .Values.global.bucket.provider }}
{{- $bucketValues = .Values.global.bucket }}
{{- end }}
{{- $bucket := "" -}}
{{- if eq $bucketValues.provider "az" -}}
{{- $bucket = printf "az://%s/%s" $bucketValues.name (default "" $bucketValues.path) -}}
{{- end -}}
{{- if eq $bucketValues.provider "gcs" -}}
{{- $bucket = printf "gs://%s/%s" $bucketValues.name (default "" $bucketValues.path) -}}
{{- end -}}
{{- if eq $bucketValues.provider "s3" -}}
{{- if and $bucketValues.accessKey $bucketValues.secretKey -}}
{{- $bucket = printf "s3://%s:%s@%s/%s" $bucketValues.accessKey $bucketValues.secretKey $bucketValues.name (default "" $bucketValues.path) -}}
{{- else -}}
{{- $bucket = printf "s3://%s/%s" $bucketValues.name (default "" $bucketValues.path) -}}
{{- end -}}
{{- end -}}
{{- trimSuffix "/" $bucket -}}
{{- end }}

{{/*
MySQL Port
*/}}
{{- define "glue.mysql.port" -}}
{{- .Values.mysql.port | default "3306" }}
{{- end }}

{{/*
MySQL Host
*/}}
{{- define "glue.mysql.host" -}}
{{- .Values.mysql.host | default (printf "%s-mysql" .Release.Name) }}
{{- end }}

{{/*
MySQL Database
*/}}
{{- define "glue.mysql.database" -}}
{{- .Values.mysql.database | default "wandb" }}
{{- end }}

{{/*
MySQL User
*/}}
{{- define "glue.mysql.user" -}}
{{- .Values.mysql.user | default "wandb" }}
{{- end }}

{{/*
MySQL Password Secret
*/}}
{{- define "glue.mysql.passwordSecret" -}}
{{- .Values.mysql.passwordSecret | default (printf "%s-mysql" .Release.Name) }}
{{- end }}

{{- define "glue.cloud" -}}
{{- $bucketValues := .Values.global.defaultBucket }}
{{- if .Values.global.bucket.provider }}
{{- $bucketValues = .Values.global.bucket }}
{{- end }}
{{- $cloud := "minio-local" -}}
{{- if eq $bucketValues.provider "az" -}}
{{- $cloud = "azure" -}}
{{- end -}}
{{- if eq $bucketValues.provider "gcs" -}}
{{- $cloud = "google" -}}
{{- end -}}
{{- if eq $bucketValues.provider "s3" -}}
{{- $cloud = "aws" -}}
{{- end -}}
{{- $cloud -}}
{{- end }}
