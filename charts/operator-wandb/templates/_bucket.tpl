{{/*
  Assorted bucket related helpers.
*/}}
{{- define "wandb.bucket.secret" -}}
{{- if .Values.global.bucket.secret.secretName -}}
  {{ .Values.global.bucket.secret.secretName }}
{{- else }}
  {{- print .Release.Name "-bucket" -}}
{{- end -}}
{{- end }}

{{- define "wandb.bucket.config" -}}
{{ .Release.Name }}-bucket-configmap
{{- end -}}

{{- define "wandb.bucket" -}}
{{- $url := "" -}}
{{- $provider := .Values.global.bucket.provider | default .Values.global.defaultBucket.provider -}}
provider: {{ $provider }}
{{- $name := .Values.global.bucket.name | default .Values.global.defaultBucket.name }}
name: {{ $name }}
{{- $path := .Values.global.bucket.path | default .Values.global.defaultBucket.path }}
path: {{ $path }}
region: {{ .Values.global.bucket.region | default .Values.global.defaultBucket.region }}
kmsKey: {{ .Values.global.bucket.kmsKey | default .Values.global.defaultBucket.kmsKey }}
{{- $accessKey := default "" (.Values.global.bucket.accessKey | default .Values.global.defaultBucket.accessKey) }}
accessKey: {{ $accessKey }}
{{- $secretKey := default "" (.Values.global.bucket.secretKey | default .Values.global.defaultBucket.secretKey) }}
secretKey: {{ $secretKey }}
accessKeyName: {{ .Values.global.bucket.secret.accessKeyName }}
secretKeyName: {{ .Values.global.bucket.secret.secretKeyName }}
secretName: {{ include "wandb.bucket.secret" . }}
{{- if eq $provider "az" -}}
{{- $url = "az://$(BUCKET_NAME)/$(BUCKET_PATH)" -}}
{{- end -}}
{{- if eq $provider "gcs" -}}
{{- $url = "gs://$(BUCKET_NAME)/$(BUCKET_PATH)" -}}
{{- end -}}
{{- if eq $provider "s3" -}}
{{- if or (and $accessKey $secretKey) .Values.global.bucket.secret.secretName -}}
{{- $url = "s3://$(BUCKET_ACCESS_KEY):$(BUCKET_SECRET_KEY)@$(BUCKET_NAME)/$(BUCKET_PATH)" -}}
{{- else -}}
{{- $url = "s3://$(BUCKET_NAME)/$(BUCKET_PATH)" -}}
{{- end -}}
{{- end -}}
{{- $url = trimSuffix "/" $url }}
url: {{ $url }}
{{- end -}}
