{{/*
Return the bucket credentials secret name
*/}}
{{- define "wandb.bucket.secret" -}}
{{- if .Values.global.bucket.bucketSecret.name -}}
  {{ .Values.global.bucket.bucketSecret.name }}
{{- else }}
  {{- print .Release.Name "-bucket" -}}
{{- end -}}
{{- end }}
