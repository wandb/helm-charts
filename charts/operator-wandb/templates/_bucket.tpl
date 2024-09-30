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
