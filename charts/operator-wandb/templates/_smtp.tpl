{{/*
Return the name of the secret where SMTP password is stored, considering if the custom secret is defined
*/}}
{{- define "wandb.smtp.passwordSecret" -}}
{{- if .Values.global.email.smtp.passwordSecret.name }}
  {{- .Values.global.email.smtp.passwordSecret.name -}}
{{- else }}
  {{- print .Release.Name "-smtp-secret" -}}
{{- end -}}
{{- end -}}

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
