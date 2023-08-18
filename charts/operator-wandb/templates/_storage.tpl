{{- define "wandb.storageClass" -}}
{{- if .Values.storageClass -}}
{{-   .Values.storageClass -}}
{{- else if .Values.global.storageClass -}}
{{-   .Values.global.storageClass -}}
{{- end -}}
{{- end -}}