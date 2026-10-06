{{- define "wandb.lumen.audience" -}}
{{- dig "lumen" "gcpWorkloadIdentity" "audience" "" .Values.global -}}
{{- end -}}

{{- define "wandb.lumen.dataRoot" -}}
{{- dig "lumen" "dataRoot" "" .Values.global -}}
{{- end -}}

{{- define "wandb.lumen.stagingPath" -}}
{{- .Values.stagingDirectory.mountPath -}}
{{- end -}}
