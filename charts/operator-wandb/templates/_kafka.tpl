{{/*
Return name of secret where information is stored
*/}}
{{- define "wandb.kafka.passwordSecret" -}}
{{- print .Release.Name "-kafka" -}}
{{- end -}}

{{/*
Return the kafka port
*/}}
{{- define "wandb.kafka.port" -}}
{{- print $.Values.global.kafka.port -}}
{{- end -}}

{{/*
Return the kafka host
*/}}
{{- define "wandb.kafka.consumerUrl" -}}
{{- if eq .Values.global.kafka.consumerUrl "" -}}
{{ printf "%s-%s" .Release.Name "kafka" }}
{{- else -}}
{{ .Values.global.kafka.consumerUrl }}
{{- end -}}
{{- end -}}

{{- define "wandb.kafka.producerUrl" -}}
{{- if eq .Values.global.kafka.producerUrl "" -}}
{{- $kafkaSlice := [] -}}
{{- range tuple "0" "1" "2" -}}
{{ $kafkaSlice := $kafkaSlice append(printf "%s-%s-%s:%s" .Release.Name "kafka-controller-headless" . .Values.global.kafka.port) }}
{{- end -}}
{{ join "," $kafkaSlice }}
{{- else -}}
{{ .Values.global.kafka.producerUrl }}
{{- end -}}
{{- end -}}

{{/*
Return the kafka queue
*/}}
{{- define "wandb.kafka.queue" -}}
{{- print $.Values.global.kafka.queue -}}
{{- end -}}

{{/*
Return the kafka user
*/}}
{{- define "wandb.kafka.user" -}}
{{- print $.Values.global.kafka.user -}}
{{- end -}}

{{/*
Return the kafka password
*/}}
{{- define "wandb.kafka.password" -}}
{{- print $.Values.global.kafka.password -}}
{{- end -}}