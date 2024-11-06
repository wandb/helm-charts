{{/*
Return the bucket credentials secret name
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

{{/*
Return the access key name for the bucket credentials, defaulting to "ACCESS_KEY"
*/}}
{{- define "wandb.bucket.accessKeyName" -}}
{{- if .Values.global.bucket.accessKeyName -}}
  {{ .Values.global.bucket.accessKeyName }}
{{- else }}
  ACCESS_KEY
{{- end -}}
{{- end -}}

{{/*
Return the secret access key name for the bucket credentials, defaulting to "SECRET_KEY"
*/}}
{{- define "wandb.bucket.secretAccessKeyName" -}}
{{- if .Values.global.bucket.secretAccessKeyName -}}
  {{ .Values.global.bucket.secretAccessKeyName }}
{{- else }}
  SECRET_KEY
{{- end -}}
{{- end -}}