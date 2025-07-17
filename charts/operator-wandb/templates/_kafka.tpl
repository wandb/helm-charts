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
{{- if .Values.kafka.install -}}
{{ .Values.global.kafka.user }}
{{- end -}}
{{- end -}}

{{/*
Return the kafka client password
*/}}
{{- define "wandb.kafka.password" -}}
{{- if .Values.kafka.install -}}
{{ .Values.global.kafka.password }}
{{- end -}}
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
Return name of secret where kafka information is stored
*/}}
{{- define "wandb.kafka.passwordSecret.passwordKey" -}}
{{- if .Values.global.kafka.passwordSecret.name }}
  {{- .Values.global.kafka.passwordSecret.passwordKey -}}
{{- else -}}
  KAFKA_CLIENT_PASSWORD
{{- end -}}
{{- end }}

{{/*
Return the kafka broker url port
*/}}
{{- define "wandb.kafka.brokerHost" -}}
{{- if eq .Values.global.kafka.brokerHost "" -}}
{{- if .Values.kafka.install -}}
{{ printf "%s-%s" .Release.Name "kafka" }}
{{- else if .Values.bufstream.install -}}
bufstream
{{- end -}}
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

{{- define "wandb.runUpdateShadowTopicProducer" -}}
{{- if .Values.global.pubSub.enabled -}}
  {{- if .Values.global.pubSub.host -}}
pubsub://{{ .Values.global.pubSub.host }}/{{ .Values.global.pubSub.project }}/{{ .Values.global.pubSub.runUpdateShadowTopic }}
  {{- else }}
pubsub:/{{ .Values.global.pubSub.project }}/{{ .Values.global.pubSub.runUpdateShadowTopic }}
  {{- end -}}
{{- else if .Values.global.beta.bufstream.enabled -}}
kafka://$(KAFKA_BROKER_HOST):$(KAFKA_BROKER_PORT)/$(KAFKA_TOPIC_RUN_UPDATE_SHADOW_QUEUE)?producer_batch_bytes=524288&num_partitions=$(KAFKA_RUN_UPDATE_SHADOW_QUEUE_NUM_PARTITIONS)
{{- else -}}
kafka://$(KAFKA_CLIENT_USER):$(A_KAFKA_CLIENT_PASSWORD)@$(KAFKA_BROKER_HOST):$(KAFKA_BROKER_PORT)/$(KAFKA_TOPIC_RUN_UPDATE_SHADOW_QUEUE)?producer_batch_bytes=524288&num_partitions=$(KAFKA_RUN_UPDATE_SHADOW_QUEUE_NUM_PARTITIONS)
{{- end -}}
{{- end -}}

{{/*
TODO(Zachary B) - Check with dpanzella to see if this is correct. 
*/}}
{{- define "wandb.runUpdateShadowQueue" -}}
{{- if .Values.global.pubSub.enabled -}}
  {{- if .Values.global.pubSub.host -}}
pubsub://{{ .Values.global.pubSub.host }}/{{ .Values.global.pubSub.project }}/{{ .Values.global.pubSub.runUpdateShadowTopic }}/{{ .Values.pubSub.subscription }}
  {{- else }}
pubsub:/{{ .Values.global.pubSub.project }}/{{ .Values.global.pubSub.runUpdateShadowTopic }}/{{ .Values.pubSub.subscription }}
  {{- end -}}
{{- else if .Values.global.beta.bufstream.enabled -}}
kafka://$(KAFKA_BROKER_HOST):9092/$(KAFKA_TOPIC_RUN_UPDATE_SHADOW_QUEUE)?consumer_group_id={{ .Values.kafka.consumerGroup }}&num_partitions=$(KAFKA_RUN_UPDATE_SHADOW_QUEUE_NUM_PARTITIONS)
{{- else -}}
kafka://$(KAFKA_CLIENT_USER):$(A_KAFKA_CLIENT_PASSWORD)@$(KAFKA_BROKER_HOST):9092/$(KAFKA_TOPIC_RUN_UPDATE_SHADOW_QUEUE)?consumer_group_id={{ .Values.kafka.consumerGroup }}&num_partitions=$(KAFKA_RUN_UPDATE_SHADOW_QUEUE_NUM_PARTITIONS)
{{- end -}}
{{- end -}}

{{/* TODO(dpanzella) - Probably need to make this support kafka as well*/}}
{{- define "wandb.fileStreamStoreProducer" -}}
{{- if .Values.global.pubSub.enabled -}}
  {{- if .Values.global.pubSub.host -}}
pubsub://{{ .Values.global.pubSub.host }}/{{ .Values.global.pubSub.project }}/{{ .Values.global.pubSub.filestreamTopic }}
  {{- else }}
pubsub:/{{ .Values.global.pubSub.project }}/{{ .Values.global.pubSub.filestreamTopic }}
  {{- end -}}
{{- else -}}
mysql://$(MYSQL_USER):$(A_MYSQL_PASSWORD)@$(MYSQL_HOST):$(MYSQL_PORT)/$(MYSQL_DATABASE)?tls=preferred
{{- end -}}
{{- end -}}
