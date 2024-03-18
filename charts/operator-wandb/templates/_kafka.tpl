{{/*
These are the variables a service can expect
            - name: KAFKA_BROKER_URL
              value: "{{ include "wandb.kafka.brokerUrl" . }}"
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
{{- print .Release.Name "-kafka" -}}
{{- end -}}

{{/*
Return the kafka broker url port
*/}}
{{- define "wandb.kafka.brokerUrl" -}}
{{- if eq .Values.global.redis.host "" -}}
{{ printf "%s-%s" .Release.Name "kafka" }}
{{- else -}}
{{ .Values.global.kafka.brokerUrl }}
{{- end -}}
{{- end -}}

{{/*
Return kafka broker url port
*/}}
{{- define "wandb.kafka.brokerPort" -}}
{{- print .Values.global.kafka.brokerPort -}}
{{- end -}}
