{{/*
Return the temporal client password
*/}}
{{- define "wandb.temporal.password" -}}
{{ .Values.global.temporal.password }}
{{- end -}}

{{/*
Return name of secret where temporal information is stored
*/}}
{{- define "wandb.temporal.passwordSecret" -}}
{{- print .Release.Name "-temporal" -}}
{{- end -}}

{{/*
Return the temporal host
*/}}
{{- define "wandb.temporal.host" -}}
{{- if eq .Values.global.temporal.host "" -}}
{{ printf "%s-%s" .Release.Name "temporal" }}
{{- else -}}
{{ .Values.global.temporal.host }}
{{- end -}}
{{- end -}}

{{/*
Return the temporal port
*/}}
{{- define "wandb.temporal.port" -}}
{{- print .Values.global.temporal.port -}}
{{- end -}}

{{/*
Return the temporal namespace
*/}}
{{- define "wandb.temporal.namespace" -}}
{{- if eq .Values.global.temporal.namespace "" -}}
{{ .Release.Namespace }}
{{- else -}}
{{ .Values.global.temporal.namespace }}
{{- end -}}
{{- end -}}
