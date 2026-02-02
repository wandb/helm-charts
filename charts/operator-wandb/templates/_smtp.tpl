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

{{- define "wandb.smtp.passwordSecretName" -}}
{{- print .Release.Name "-smtp-secret" -}}
{{- end -}}

{{- define "wandb.smtp.passwordSecretKey" -}}
{{- print "SMTP_PASSWORD" -}}
{{- end -}}

{{- define "wandb.emailSink" -}}
{{- if ne .Values.global.email.smtp.host "" -}}
smtp://$(SMTP_USER):$(SMTP_PASSWORD)@$(SMTP_HOST):$(SMTP_PORT)
{{- else -}}
https://api.wandb.ai/email/dispatch
{{- end -}}
{{- end -}}
