{{/*
  Assorted bucket related helpers.
*/}}
{{- define "wandb.bucket.secret" -}}
{{- if include "wandb.resolved.bucket" .secretName -}}
  {{ include "wandb.resolved.bucket" .secretName  }}
{{- else }}
  {{- print .Release.Name "-bucket" -}}
{{- end -}}
{{- end }}


{{- define "wandb.resolved.bucket" -}}
provider: {{ .Values.global.bucket.provider | default .Values.global.defaultBucket.provider}}
name: {{ .Values.global.bucket.name | default .Values.global.defaultBucket.name }}
path: {{ .Values.global.bucket.path | default .Values.global.defaultBucket.path }}
region: {{ .Values.global.bucket.region | default .Values.global.defaultBucket.region }}
kmsKey: {{ .Values.global.bucket.kmsKey | default .Values.global.defaultBucket.kmsKey }}
accessKey: {{- b64enc "test" -}}
accessKeyName: {{ .Values.global.bucket.accessKeyName | default .Values.global.defaultBucket.accessKeyName }}
secretKey: {{- b64enc "test" -}}
secretAccessKeyName: {{ .Values.global.bucket.secretAccessKeyName | default .Values.global.defaultBucket.secretAccessKeyName }}
secretName: {{ .Value.global.bucket.secretName | default .Values.global.defaultBucket.secretName }}
{{- end -}}
