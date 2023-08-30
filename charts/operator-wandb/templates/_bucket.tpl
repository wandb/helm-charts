{{/*
Return name of secret where bucket information is stored
*/}}
{{- define "wandb.bucket.secret" -}}
{{- print .Release.Name "-bucket" -}}
{{- end -}}
