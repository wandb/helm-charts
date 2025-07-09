{{/*
Return sweep provider for anaconda2
*/}}
{{- define "wandb.anaconda2.sweepProvider" -}}
{{- if .Values.global.anaconda2.enabled -}}
{{- printf "http://%s-anaconda2:8082" .Release.Name -}}
{{- else -}}
{{- printf "http://%s-app:8082" .Release.Name -}}
{{- end -}}
{{- end -}}
