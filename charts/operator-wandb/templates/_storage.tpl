{{- define "wandb.storageClass" -}}
{{- if .Values.persistence.storageClass -}}
{{-   if (ne .Values.persistence.storageClass "") -}}
{{-     printf "storageClassName: %s" .Values.persistence.storageClass -}}
{{-   end -}}
{{- else if .Values.global.storageClass -}}
{{-   if (ne .Values.global.storageClass "") -}}
{{-     printf "storageClassName: %s" .Values.global.storageClass -}}
{{-   end -}}
{{- end -}}
{{- end -}}
