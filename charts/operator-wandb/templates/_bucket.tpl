{{/*
  Assorted bucket related helpers.
*/}}
{{- define "wandb.bucket.secret" -}}
{{- if .Values.global.bucket.secretName -}}
  {{ .Values.global.bucket.secretName }}
{{- else if .Values.global.defaultBucket.secretName -}}
  {{ .Values.global.defaultBucket.secretName }}
{{- else }}
  {{- print .Release.Name "-bucket" -}}
{{- end -}}
{{- end }}

{{- define "wandb.bucket.config" -}}
{{ .Release.Name }}-bucket-configmap
{{- end -}}


{{- define "wandb.bucket" -}}
{{- $url := "" -}} 
{{- $provider := .Values.global.bucket.provider -}}
provider: {{ $provider }}
{{- $name := .Values.global.bucket.name | default .Values.global.defaultBucket.name }}
name: {{ $name }}
{{- $path := .Values.global.bucket.path | default (default "" .Values.global.defaultBucket.path) }} 
path: {{ $path }}
region: {{ .Values.global.bucket.region | default .Values.global.defaultBucket.region }}
kmsKey: {{ .Values.global.bucket.kmsKey | default .Values.global.defaultBucket.kmsKey }}
{{- $accessKey:= .Values.global.bucket.accessKey | default .Values.global.defaultBucket.accessKey }}
accessKey: {{ $accessKey }}
{{- $secretKey:= .Values.global.bucket.secretKey | default .Values.global.defaultBucket.secretKey }}
secretKey: {{ $secretKey }}
accessKeyName: {{ .Values.global.bucket.accessKeyName | default (default "ACCESS_KEY" .Values.global.defaultBucket.accessKeyName) }}
secretKeyName: {{ .Values.global.bucket.secretKeyName | default (default "SECRET_KEY" .Values.global.defaultBucket.secretKeyName) }}
secretName: {{ include "wandb.bucket.secret" . }}
{{- if eq $provider "az" -}}
{{- $url = printf "az://%s/%s" $name $path -}}
{{- end -}}
{{- if eq $provider "gcs" -}}
{{- $url = printf "gs://%s/%s" $name $path -}}
{{- end -}}
{{- if eq $provider "s3" -}}
{{- if and $accessKey $secretKey -}}
{{- $url = printf "s3://%s:%s@%s/%s" $accessKey $secretKey $name $path -}}
{{- else -}}
{{- $url = printf "s3://%s/%s" $name $path -}}
{{- end -}}
{{- end -}}
{{- $url = trimSuffix "/" $url }}
url: {{ $url }}
{{- end -}}
