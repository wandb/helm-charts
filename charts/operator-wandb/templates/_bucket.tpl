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


{{- define "wandb.resolved.bucket" -}}
{{- $url := "" -}} 
{{- $provider := .Values.global.bucket.provider | default .Values.global.defaultBucket.provider -}}
provider: {{ $provider }}
{{- $name := .Values.global.bucket.name | default .Values.global.defaultBucket.name -}}
name: {{ $name }}
{{- $path := .Values.global.bucket.path | default (default "" .Values.global.defaultBucket.path) -}} 
path: {{ $path }}
region: {{ .Values.global.bucket.region | default .Values.global.defaultBucket.region }}
kmsKey: {{ .Values.global.bucket.kmsKey | default .Values.global.defaultBucket.kmsKey }}
{{- $accessKey:= .Values.global.bucket.accessKey | default .Values.global.defaultBucket.accessKey -}}
accessKey: {{ $accessKey }}
{{- $secretKey:= .Values.global.bucket.secretKey | default .Values.global.defaultBucket.secretKey -}}
secretKey: {{ $secretKey }}
accessKeyName: {{ .Values.global.bucket.accessKeyName | default .Values.global.defaultBucket.accessKeyName }}
secretAccessKeyName: {{ .Values.global.bucket.secretAccessKeyName | default .Values.global.defaultBucket.secretAccessKeyName }}
secretName: {{ .Value.global.bucket.secretName | default .Values.global.defaultBucket.secretName }}
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
{{- trimSuffix "/" $url -}}
url: {{ $url }}
{{- end -}}
