{{- define "wandb.storageClass" -}}
{{- if .Values.storageClass -}}
{{-   if (ne .Values.storageClass "") -}}
{{-     printf "storageClassName: %s" .Values.storageClass -}}
{{-   end -}}
{{- else if .Values.global.storageClass -}}
{{-   if (ne .Values.global.storageClass "") -}}
{{-     printf "storageClassName: %s" .Values.global.storageClass -}}
{{-   end -}}
{{- end -}}
{{- end -}}