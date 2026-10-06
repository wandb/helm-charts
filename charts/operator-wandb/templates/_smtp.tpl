{{- define "wandb.smtp.secretName" -}}
  {{- printf "%s-smtp-secret" .Release.Name -}}
{{- end -}}

{{/* A valueFrom map stays on the pod; it is never copied into our Secret. */}}
{{- define "wandb.smtp.isExternal" -}}
  {{- if and (kindIs "map" .) (hasKey . "valueFrom") -}}
    true
  {{- end -}}
{{- end -}}

{{/* External connection fields require Kubernetes to assemble the SMTP URL. */}}
{{- define "wandb.smtp.hasConnectionRefs" -}}
  {{- $email := .Values.global.email | default dict -}}
  {{- $smtp := $email.smtp | default dict -}}
  {{- $externalHost := include "wandb.smtp.isExternal" $smtp.host -}}
  {{- $externalPort := include "wandb.smtp.isExternal" $smtp.port -}}
  {{- $externalUser := include "wandb.smtp.isExternal" $smtp.user -}}
  {{- $externalPassword := include "wandb.smtp.isExternal" $smtp.password -}}
  {{- if and $smtp.host (or $externalHost $externalPort $externalUser $externalPassword) -}}
    true
  {{- end -}}
{{- end -}}

{{/* Accept both scalar values and Kubernetes-style {value: ...} maps. */}}
{{- define "wandb.smtp.inlineValue" -}}
  {{- if kindIs "map" . -}}
    {{- if hasKey . "value" -}}
      {{- .value | toString -}}
    {{- end -}}
  {{- else -}}
    {{- . | default "" | toString -}}
  {{- end -}}
{{- end -}}

{{- define "wandb.smtpEnvs" -}}
  {{- $email := .Values.global.email | default dict -}}
  {{- $smtp := $email.smtp | default dict -}}
  {{- /* Inline fields are already loaded from the shared Secret via envFrom. */ -}}
  {{- if include "wandb.smtp.isExternal" $smtp.host }}
- name: SMTP_HOST
  {{- toYaml $smtp.host | nindent 2 }}
  {{- end }}
  {{- if include "wandb.smtp.isExternal" $smtp.port }}
- name: SMTP_PORT
  {{- toYaml $smtp.port | nindent 2 }}
  {{- end }}
  {{- if include "wandb.smtp.isExternal" $smtp.user }}
- name: SMTP_USER
  {{- toYaml $smtp.user | nindent 2 }}
  {{- end }}
  {{- if include "wandb.smtp.isExternal" $smtp.password }}
- name: SMTP_PASSWORD
  {{- toYaml $smtp.password | nindent 2 }}
  {{- end }}
  {{- if include "wandb.smtp.isExternal" $smtp.mailFrom }}
- name: GORILLA_EMAIL_FROM_ADDRESS
  {{- toYaml $smtp.mailFrom | nindent 2 }}
  {{- end }}
  {{- /* Kubernetes loads envFrom first, then expands env.value in order.
    Keep this URL after the external references so all SMTP fields are available.
  */ -}}
  {{- if include "wandb.smtp.hasConnectionRefs" . }}
- name: GORILLA_EMAIL_SINK
  value: "smtp://$(SMTP_USER):$(SMTP_PASSWORD)@$(SMTP_HOST):$(SMTP_PORT)"
  {{- end -}}
{{- end -}}
