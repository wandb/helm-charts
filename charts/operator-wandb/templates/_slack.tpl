{{/* Slack Secret keys are the fixed application environment-variable names. */}}
{{- define "wandb.slack.secretName" -}}
  {{- $slack := .Values.global.slack | default dict -}}
  {{- $secret := $slack.slackSecret | default dict -}}
  {{- default (printf "%s-slack-secret" .Release.Name) $secret.name -}}
{{- end -}}
