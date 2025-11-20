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
- name: GORILLA_USAGE_METRICS_CACHE
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

{{- define "wandb.bucket.cwIdentity" -}}
- name: GORILLA_COREWEAVE_WANDB_INTEGRATION_ACCESS_ID
  valueFrom:
    secretKeyRef:
      name: "gorilla-coreweave-caios"
      key: "GORILLA_COREWEAVE_WANDB_INTEGRATION_ACCESS_ID"
      optional: true
- name: GORILLA_COREWEAVE_WANDB_INTEGRATION_SECRET_KEY
  valueFrom:
    secretKeyRef:
      name: "gorilla-coreweave-caios"
      key: "GORILLA_COREWEAVE_WANDB_INTEGRATION_SECRET_KEY"
      optional: true
{{- end -}}

{{- define "wandb.statsigEnvs" -}}
{{- if eq .Values.global.statsig.apiKey "" }}
- name: GORILLA_STATSIG_KEY
  valueFrom:
    secretKeyRef:
      name: "gorilla-statsig"
      key: "GORILLA_STATSIG_KEY"
      optional: true
{{- end }}
{{- end -}}

{{- define "wandb.mysqlConfigEnvs" -}}
{{- /*
  ATTENTION!
  
  MYSQL_PASSWORD, MYSQL_PORT, MYSQL_HOST, MYSQL_DATABASE, MYSQL_USER

  Are all set in the the values.yaml under global.mysql.(host,port,database,user,password)

  The following blocks are to enable values to be provided in one of two ways:

  AS STANDARD:
    mysql:
      host: "mysql.com"
      port: 3306
      database: "wandb_local"
      user: "wandb"
      password: "supersafe"

  AS K8s REFS:
    mysql:
      host:
       valueFrom:
        secretKeyRef:
          name: "mysql-settings-secret"
          key: "endpoint"
      port:
       valueFrom:
        secretKeyRef:
          name: "mysql-settings-secret"
          key: "port"
      database:
        ...
      user:
        ...
      password:
        ...
*/ -}}

{{- if kindIs "map" .Values.global.mysql.password }}
- name: MYSQL_PASSWORD
{{- toYaml .Values.global.mysql.password | nindent 2 }}
{{- else }}
- name: MYSQL_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "wandb.mysql.passwordSecret" . | quote}}
      key: "{{ .Values.global.mysql.passwordSecret.passwordKey }}"
{{- end }}

{{- if kindIs "map" .Values.global.mysql.port }}
- name: MYSQL_PORT
{{- toYaml .Values.global.mysql.port | nindent 2 }}
{{- else }}
- name: MYSQL_PORT
  value: "{{ include "wandb.mysql.port" . }}"
{{- end }}

{{- if kindIs "map" .Values.global.mysql.host }}
- name: MYSQL_HOST
{{- toYaml .Values.global.mysql.host | nindent 2 }}
{{- else }}
- name: MYSQL_HOST
  value: "{{ include "wandb.mysql.host" . }}"
{{- end }}

{{- if kindIs "map" .Values.global.mysql.database }}
- name: MYSQL_DATABASE
{{- toYaml .Values.global.mysql.database | nindent 2 }}
{{- else }}
- name: MYSQL_DATABASE
  value: "{{ include "wandb.mysql.database" . }}"
{{- end }}

{{- if kindIs "map" .Values.global.mysql.user }}
- name: MYSQL_USER
{{- toYaml .Values.global.mysql.user | nindent 2 }}
{{- else }}
- name: MYSQL_USER
  value: "{{ include "wandb.mysql.user" . }}"
{{- end -}}
{{- end -}}

{{- define "wandb.mysqlEnvs" -}}
{{ include "wandb.mysqlConfigEnvs" . }}
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
- name: GORILLA_HISTORY_STORE_SERVICE
  value: {{ include "wandb.historyStoreService" . | quote }}
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

{{- define "wandb.oidcEnvs" -}}
{{- if or .Values.global.auth.oidc.secret "" .Values.global.auth.oidc.oidcSecret.name }}
- name: GORILLA_OIDC_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ include "wandb.oidc.secretSecret" . | quote }}
      key: "{{ .Values.global.auth.oidc.oidcSecret.secretKey }}"
- name: OIDC_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ include "wandb.oidc.secretSecret" . | quote }}
      key: "{{ .Values.global.auth.oidc.oidcSecret.secretKey }}"
{{- end }}
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
- name: GOMAXPROCS
  valueFrom:
    resourceFieldRef:
      resource: limits.cpu
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
- name: GORILLA_TRACER
  value: '{{ include "wandb.otelTracesEndpoint" . | trim }}'
{{- end }}
{{- end -}}
