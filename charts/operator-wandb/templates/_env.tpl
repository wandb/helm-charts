{{- define "wandb.extraEnvFrom" -}}
{{- $global := deepCopy (get .root.Values.global "extraEnvFrom" | default (dict)) -}}
{{- $values := deepCopy (get .root.Values "extraEnvFrom" | default (dict)) -}}
{{- $local  := deepCopy (get .local "extraEnvFrom" | default (dict)) -}}
{{- $allExtraEnvFrom := mergeOverwrite $global $values $local -}}
{{- range $key, $value := $allExtraEnvFrom }}
- name: {{ $key }}
  valueFrom: 
{{ toYaml $value | nindent 4 }}
{{- end -}}
{{- end -}}

{{/*
Returns the extraEnv keys and values to inject into containers.

Global values will override any chart-specific values.
*/}}
{{- define "wandb.extraEnv" -}}
{{- $allExtraEnv := merge (default (dict) .Values.extraEnv) .Values.global.extraEnv -}}
{{- range $key, $value := $allExtraEnv }}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- end -}}
{{- end -}}

{{- define "wandb.redisEnvs" -}}
- name: REDIS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: "{{ include "wandb.redis.passwordSecret" . }}"
      key: "{{ .Values.global.redis.secret.secretKey }}"
      optional: true
- name: REDIS
  value: "{{ include "wandb.redis.connectionString" . | trim }}"
- name: GORILLA_ACTIVITY_STORE_CACHE_ADDRESS
  value: {{ include "wandb.redis.connectionString" . | trim | quote }}
- name: GORILLA_AUDITOR_CACHE
  value: {{ include "wandb.redis.connectionString" . | trim | quote }}
- name: GORILLA_CACHE
  value: {{ include "wandb.redis.connectionString" . | trim | quote }}
- name: GORILLA_FILE_METADATA_SOURCE
  value: {{ include "wandb.redis.connectionString" . | trim | quote }}
- name: GORILLA_LOCKER
  value: {{ include "wandb.redis.connectionString" . | trim | quote }}
- name: GORILLA_METADATA_CACHE
  value: {{ include "wandb.redis.connectionString" . | trim | quote }}
- name: GORILLA_SETTINGS_CACHE
  value: {{ include "wandb.redis.connectionString" . | trim | quote }}
- name: GORILLA_TASK_QUEUE
  value: {{ include "wandb.redis.taskQueue" . | trim | quote }}
{{- end -}}

{{- define "wandb.bucketEnvs" -}}
- name: AZURE_STORAGE_KEY
  valueFrom:
    secretKeyRef:
      name: {{ (include "wandb.bucket" . | fromYaml).secretName | quote }}
      key: {{ (include "wandb.bucket" . | fromYaml).accessKeyName | quote }}
      optional: true
- name: BUCKET_ACCESS_KEY
  valueFrom:
    secretKeyRef:
      name: {{ (include "wandb.bucket" . | fromYaml).secretName | quote }}
      key: {{ (include "wandb.bucket" . | fromYaml).accessKeyName | quote }}
      optional: true
- name: BUCKET_SECRET_KEY
  valueFrom:
    secretKeyRef:
      name: {{ (include "wandb.bucket" . | fromYaml).secretName | quote }}
      key: {{ (include "wandb.bucket" . | fromYaml).secretKeyName | quote }}
      optional: true
- name: BUCKET
  value: {{ (include "wandb.bucket" . | fromYaml).url | quote }}
- name: GORILLA_FILE_STORE
  value: {{ (include "wandb.bucket" . | fromYaml).url | quote }}
- name: GORILLA_RUN_UPDATE_SHADOW_QUEUE_OVERFLOW_BUCKET_STORE
  value: {{ (include "wandb.bucket" . | fromYaml).url | quote }}
- name: GORILLA_STORAGE_BUCKET
  value: {{ (include "wandb.bucket" . | fromYaml).url | quote }}
{{- end -}}

{{- define "wandb.mysqlEnvs" -}}
- name: MYSQL_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "wandb.mysql.passwordSecret" . | quote}}
      key: "{{ .Values.global.mysql.passwordSecret.passwordKey }}"
- name: MYSQL
  value: {{ include "wandb.mysql" . | trim | quote }}
- name: GORILLA_ANALYTICS_SINK
  value: {{ include "wandb.mysql" . | trim | quote }}
- name: GORILLA_METADATA_STORE
  value: {{ include "wandb.mysql" . | trim | quote }}
- name: GORILLA_RUN_STORE
  value: {{ include "wandb.mysql" . | trim | quote }}
- name: GORILLA_USAGE_STORE
  value: {{ include "wandb.mysql" . | trim | quote }}
{{- end -}}

{{- define "wandb.historyStoreEnvs" -}}
- name: GORILLA_HISTORY_STORE
  value: {{ include "wandb.historyStore" . | quote }}
- name: GORILLA_PARQUET_LIVE_HISTORY_STORE
  value: {{ include "wandb.liveHistoryStore" . | quote }}
- name: GORILLA_FILE_STREAM_WORKER_STORE_ADDRESS
  value: {{ include "wandb.fileStreamWorkerStore" . | quote }}
{{- end -}}

{{- define "wandb.queueEnvs" -}}
- name: KAFKA_CLIENT_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "wandb.kafka.passwordSecret" . | quote }}
      key: {{ include "wandb.kafka.passwordSecret.passwordKey" . | quote }}
      optional: true
- name: GORILLA_FILE_STREAM_STORE_ADDRESS
  value: {{ include "wandb.fileStreamStoreProducer" . | quote }}
- name: GORILLA_RUN_UPDATE_SHADOW_QUEUE_ADDR
  value: {{ include "wandb.runUpdateShadowTopicProducer" . | quote }}
{{- end -}}

{{- define "wandb.downwardEnvs" -}}
- name: G_HOST_IP
  valueFrom:
    fieldRef:
      fieldPath: status.hostIP
- name: GOMEMLIMIT
  valueFrom:
    resourceFieldRef:
      resource: limits.memory
- name: POD_NAME
  valueFrom:
    fieldRef:
      fieldPath: metadata.name
- name: GORILLA_CUSTOMER_SECRET_STORE_K8S_CONFIG_NAMESPACE
  valueFrom:
    fieldRef:
      fieldPath: metadata.namespace
{{- end -}}

{{- define "wandb.observabilityEnvs" -}}
{{- if and .Values.traceRatio (ne .Values.traceRatio 0.0) }}
- name: GORILLA_TRACER:
  values: '{{ include "wandb.otelTracesEndpoint" . | trim }}'
{{- end }}
{{- end -}}