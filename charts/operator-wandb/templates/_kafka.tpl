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
Return the kafka sasl mechanism
*/}}
{{- define "wandb.kafka.sasl.mechanism" -}}
{{- if eq .Values.global.kafka.sasl.mechanism "" -}}
{{ printf "PLAIN" }}
{{- else -}}
{{ .Values.global.kafka.sasl.mechanism }}
{{- end -}}
{{- end -}}

{{/*
Return the kafka sasl username
*/}}
{{- define "wandb.kafka.sasl.username" -}}
{{- if eq .Values.global.kafka.sasl.username "" -}}
{{ print "wandb" }}
{{- else -}}
{{ .Values.global.kafka.sasl.username }}
{{- end -}}
{{- end -}}

{{/*
Return the kafka sasl password
*/}}
{{- define "wandb.kafka.sasl.password" -}}
{{- if eq .Values.global.kafka.sasl.password "" -}}
{{ print "wandb" }}
{{- else -}}
{{ .Values.global.kafka.sasl.password }}
{{- end -}}
{{- end -}}
