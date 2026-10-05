{{- define "wandb.smtp.secretName" -}}
  {{- printf "%s-smtp-secret" .Release.Name -}}
{{- end -}}

{{/* External connection fields need pod-time expansion of the SMTP URL. */}}
{{- define "wandb.smtp.hasConnectionRefs" -}}
  {{- $email := .Values.global.email | default dict -}}
  {{- $smtp := $email.smtp | default dict -}}
  {{- if $smtp.host -}}
    {{- range $field := list "host" "port" "user" "password" -}}
      {{- $value := get $smtp $field -}}
      {{- if and (kindIs "map" $value) (hasKey $value "valueFrom") -}}
      true
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/* Inline values seed the shared Secret; external references remain on pods. */}}
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
  {{- $fields := list (dict "field" "host" "env" "SMTP_HOST") (dict "field" "port" "env" "SMTP_PORT") (dict "field" "user" "env" "SMTP_USER") (dict "field" "password" "env" "SMTP_PASSWORD") (dict "field" "mailFrom" "env" "GORILLA_EMAIL_FROM_ADDRESS") -}}
  {{- range $fields -}}
    {{- $value := get $smtp .field -}}
    {{- if and (kindIs "map" $value) (hasKey $value "valueFrom") }}
- name: {{ .env }}
  {{- toYaml $value | nindent 2 }}
    {{- end -}}
  {{- end -}}
  {{- if include "wandb.smtp.hasConnectionRefs" . }}
- name: GORILLA_EMAIL_SINK
  value: "smtp://$(SMTP_USER):$(SMTP_PASSWORD)@$(SMTP_HOST):$(SMTP_PORT)"
  {{- end -}}
{{- end -}}
