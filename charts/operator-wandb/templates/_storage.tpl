{{- define "wandb.storageClass" -}}
{{- if .Values.local.storageClass -}}
{{-   .Values.local.storageClass -}}
{{- else if .Values.global.storageClass -}}
{{-   .Values.global.storageClass -}}
{{- end -}}
{{- end -}}