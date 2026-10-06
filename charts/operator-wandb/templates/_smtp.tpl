{{- define "wandb.smtp.secretName" -}}
  {{- printf "%s-smtp-secret" .Release.Name -}}
{{- end -}}

{{/* Map-valued fields retain their existing Kubernetes env source. */}}
{{- define "wandb.smtp.hasReferences" -}}
  {{- $email := .Values.global.email | default dict -}}
  {{- $smtp := $email.smtp | default dict -}}
  {{- if or (kindIs "map" $smtp.host) (kindIs "map" $smtp.port) (kindIs "map" $smtp.user) (kindIs "map" $smtp.password) (kindIs "map" $smtp.mailFrom) -}}
    true
  {{- end -}}
{{- end -}}

{{/* Select a supplied env source or the fixed key in our SMTP Secret. */}}
{{- define "wandb.smtp.env" -}}
- name: {{ .envName }}
  {{- if kindIs "map" .value }}
    {{- toYaml .value | nindent 2 }}
  {{- else }}
  valueFrom:
    secretKeyRef:
      name: {{ include "wandb.smtp.secretName" .root | quote }}
      key: {{ .envName }}
    {{- if .optional }}
      optional: true
    {{- end }}
  {{- end }}
{{- end -}}

{{- define "wandb.smtpEnvs" -}}
  {{- $email := .Values.global.email | default dict -}}
  {{- $smtp := $email.smtp | default dict -}}
{{ include "wandb.smtp.env" (dict "root" . "envName" "SMTP_HOST" "value" $smtp.host) }}
{{ include "wandb.smtp.env" (dict "root" . "envName" "SMTP_PORT" "value" $smtp.port) }}
{{ include "wandb.smtp.env" (dict "root" . "envName" "SMTP_USER" "value" $smtp.user) }}
{{ include "wandb.smtp.env" (dict "root" . "envName" "SMTP_PASSWORD" "value" $smtp.password) }}
{{ include "wandb.smtp.env" (dict "root" . "envName" "GORILLA_EMAIL_FROM_ADDRESS" "value" $smtp.mailFrom "optional" true) }}
  {{- if include "wandb.smtp.hasReferences" . }}
    {{- /* Kubernetes expands the preceding env values when the pod starts.
    Never bake external credentials into the chart-managed Secret.
    */}}
- name: GORILLA_EMAIL_SINK
    {{- if or (kindIs "map" $smtp.host) (not (empty $smtp.host)) }}
  value: "smtp://$(SMTP_USER):$(SMTP_PASSWORD)@$(SMTP_HOST):$(SMTP_PORT)"
    {{- else }}
  value: "https://api.wandb.ai/email/dispatch"
    {{- end }}
  {{- else }}
    {{- /* Console updates the complete URL atomically with inline settings,
    including enabling SMTP or returning to the default email service.
    */}}
{{ include "wandb.smtp.env" (dict "root" . "envName" "GORILLA_EMAIL_SINK") }}
  {{- end }}
{{- end -}}

{{/* Keep chart/user-spec edits effective before Console takes ownership.
Moving inline env values into a Secret must not remove the pod rollout trigger.
*/}}
{{- define "wandb.smtp.podAnnotations" -}}
  {{- $email := .Values.global.email | default dict -}}
  {{- $smtp := $email.smtp | default dict -}}
checksum/smtp: {{ $smtp | toJson | sha256sum | quote }}
{{- end -}}
