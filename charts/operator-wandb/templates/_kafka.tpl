{{/*
Return the db host
*/}}
{{- define "wandb.kafka.brokers" -}}
{{- if eq .Values.global.kafka.brokers "" -}}
{{ printf "%s-%s" .Release.Name "kafka" }}
{{- else -}}
{{ .Values.global.kafka.brokers }}
{{- end -}}
{{- end -}}

{{/*
Return the kafka client username
*/}}
{{- define "wandb.kafka.client.username" -}}
{{- if eq .Values.global.kafka.client.username "" -}}
{{ print "wandb" }}
{{- else -}}
{{ .Values.global.kafka.client.username }}
{{- end -}}
{{- end -}}

{{/*
Return the kafka client password
*/}}
{{- define "wandb.kafka.client.password" -}}
{{- if eq .Values.global.kafka.client.password "" -}}
{{ print "wandb" }}
{{- else -}}
{{ .Values.global.kafka.client.password }}
{{- end -}}
{{- end -}}

{{/*
Return name of secret where kafka information is stored
*/}}
{{- define "wandb.kafka.client.passwordSecret" -}}
{{- print .Release.Name "-kafka" -}}
{{- end -}}
