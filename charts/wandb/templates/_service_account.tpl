{{/*
Return the sub-chart serviceAccount name
If that is not present it will use the global chart serviceAccount name
Failing that a serviceAccount will be generated automatically
*/}}
{{- define "wandb.serviceAccount.name" -}}
{{- coalesce .Values.serviceAccount.name .Values.global.serviceAccount.name ( include "fullname" . ) -}}
{{- end -}}
