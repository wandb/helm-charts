{{/*
Return the SMTP host
*/}}
{{- define "wandb.smtp.host" -}}
{{- print $.Values.global.email.smtp.host -}}
{{- end -}}

{{/*
Return the SMTP port
*/}}
{{- define "wandb.smtp.port" -}}
{{- print $.Values.global.email.smtp.port -}}
{{- end -}}

{{/*
Return the SMTP user
*/}}
{{- define "wandb.smtp.user" -}}
{{- print $.Values.global.email.smtp.user -}}
{{- end -}}

{{/*
Return the SMTP password
*/}}
{{- define "wandb.smtp.password" -}}
{{- print $.Values.global.email.smtp.password -}}
{{- end -}}
