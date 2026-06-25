{{- define "lumen.audience" -}}
{{- dig "lumen" "gcpWorkloadIdentity" "audience" "" .Values.global -}}
{{- end -}}

{{- define "lumen.dataRoot" -}}
{{- dig "lumen" "dataRoot" "" .Values.global -}}
{{- end -}}