{{- define "lumen.audience" -}}
{{- dig "lumen" "gcpWorkloadIdentity" "audience" "" .Values.global -}}
{{- end -}}
