{{/*
These are the variables a service can expect
            - name: KAFKA_BROKER_HOST
              value: "{{ include "wandb.kafka.brokerHost" . }}"
            - name: KAFKA_BROKER_PORT
              value: "{{ include "wandb.kafka.brokerPort" . }}"
            - name: KAFKA_CLIENT_USER
              value: "{{ include "wandb.kafka.user" . }}"
            - name: KAFKA_CLIENT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: {{ include "wandb.kafka.passwordSecret" . }}
                  key: KAFKA_CLIENT_PASSWORD
*/}}

{{/*
Return the kafka client user
*/}}
{{- define "wandb.kafka.user" -}}
{{ .Values.global.kafka.user }}
{{- end -}}

{{/*
Return the kafka client password
*/}}
{{- define "wandb.kafka.password" -}}
{{ .Values.global.kafka.password }}
{{- end -}}

{{/*
Return name of secret where kafka information is stored
*/}}
{{- define "wandb.kafka.passwordSecret" -}}
{{- if .Values.global.kafka.passwordSecret.name }}
  {{- .Values.global.kafka.passwordSecret.name -}}
{{- else -}}
  {{- print .Release.Name "-kafka" -}}
{{- end -}}
{{- end }}

{{/*
Return the kafka broker url port
*/}}
{{- define "wandb.kafka.brokerHost" -}}
{{- if eq .Values.global.kafka.brokerHost "" -}}
{{ printf "%s-%s" .Release.Name "kafka" }}
{{- else -}}
{{ .Values.global.kafka.brokerHost }}
{{- end -}}
{{- end -}}

{{/*
Return kafka broker url port
*/}}
{{- define "wandb.kafka.brokerPort" -}}
{{- print .Values.global.kafka.brokerPort -}}
{{- end -}}


{{/*
Return the kafka topic name for run-updates-shadow
*/}}
{{- define "wandb.kafka.runUpdatesShadowTopic" -}}
{{ printf "%s-%s" .Release.Name "run-updates-shadow" | trunc 63 | trimSuffix "-" }}
{{- end -}}

{{/*
Return the number of partitions for run-updates-shadow
*/}}
{{- define "wandb.kafka.runUpdatesShadowNumPartitions" -}}
{{- print .Values.global.kafka.runUpdatesShadowNumPartitions -}}
{{- end -}}
