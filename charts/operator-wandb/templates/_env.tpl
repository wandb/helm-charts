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

{{- if and .Values.global.mysql.caCert (ne .Values.global.mysql.caCert "") }}
- name: MYSQL_CA_CERT_PATH
  value: "/etc/ssl/certs/{{ include "wandb.mysql.certFileName" . }}"
{{- end }}
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

{{- define "wandb.clickhouseConfigEnvs" -}}
{{- /*
  ATTENTION!
  
  WF_CLICKHOUSE_HOST, WF_CLICKHOUSE_PORT, WF_CLICKHOUSE_DATABASE, 
  WF_CLICKHOUSE_USER, WF_CLICKHOUSE_REPLICATED, CLICKHOUSE_PASSWORD

  Are all set in the values.yaml under global.clickhouse.(host,port,database,user,password,replicated)

  The following blocks are to enable values to be provided in one of two ways:

  AS STANDARD:
    clickhouse:
      host: "clickhouse.example.com"
      port: 8443
      database: "weave_trace_db"
      user: "default"
      password: "supersafe"
      replicated: false

  AS K8s REFS:
    clickhouse:
      host:
        valueFrom:
          secretKeyRef:
            name: "clickhouse-settings-secret"
            key: "endpoint"
      port:
        valueFrom:
          secretKeyRef:
            name: "clickhouse-settings-secret"
            key: "port"
      database:
        ...
      user:
        ...
      password:
        ...
*/ -}}

{{- if kindIs "map" .Values.global.clickhouse.host }}
- name: WF_CLICKHOUSE_HOST
{{- toYaml .Values.global.clickhouse.host | nindent 2 }}
{{- else }}
- name: WF_CLICKHOUSE_HOST
  value: "{{ include "wandb.clickhouse.host" . }}"
{{- end }}

{{- if kindIs "map" .Values.global.clickhouse.port }}
- name: WF_CLICKHOUSE_PORT
{{- toYaml .Values.global.clickhouse.port | nindent 2 }}
{{- else }}
- name: WF_CLICKHOUSE_PORT
  value: "{{ include "wandb.clickhouse.port" . }}"
{{- end }}

{{- if kindIs "map" .Values.global.clickhouse.database }}
- name: WF_CLICKHOUSE_DATABASE
{{- toYaml .Values.global.clickhouse.database | nindent 2 }}
{{- else }}
- name: WF_CLICKHOUSE_DATABASE
  value: "{{ include "wandb.clickhouse.database" . }}"
{{- end }}

{{- if kindIs "map" .Values.global.clickhouse.user }}
- name: WF_CLICKHOUSE_USER
{{- toYaml .Values.global.clickhouse.user | nindent 2 }}
{{- else }}
- name: WF_CLICKHOUSE_USER
  value: "{{ include "wandb.clickhouse.user" . }}"
{{- end }}

{{- if kindIs "map" .Values.global.clickhouse.replicated }}
- name: WF_CLICKHOUSE_REPLICATED
{{- toYaml .Values.global.clickhouse.replicated | nindent 2 }}
{{- else }}
- name: WF_CLICKHOUSE_REPLICATED
  value: "{{ .Values.global.clickhouse.replicated }}"
{{- end }}

{{- if kindIs "map" .Values.global.clickhouse.password }}
- name: WF_CLICKHOUSE_PASS
{{- toYaml .Values.global.clickhouse.password | nindent 2 }}
{{- else }}
- name: WF_CLICKHOUSE_PASS
  valueFrom:
    secretKeyRef:
      name: {{ include "wandb.clickhouse.passwordSecret" . | quote}}
      key: "{{ .Values.global.clickhouse.passwordSecret.passwordKey }}"
{{- end -}}
{{- end -}}

{{- define "wandb.clickhouseEnvs" -}}
{{ include "wandb.clickhouseConfigEnvs" . }}
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

{{- define "wandb.smtpEnvs" -}}
- name: SMTP_PASSWORD
  valueFrom:
    secretKeyRef:
      name: "{{ include "wandb.smtp.passwordSecret" . }}"
      key: "{{ .Values.global.email.smtp.passwordSecret.passwordKey }}"
      optional: true
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

{{- define "wandb.sslCertEnvs" -}}
- name: SSL_CERT_FILE
  value: "/etc/ssl/certs/ca-certificates.crt"
- name: SSL_CERT_DIR
  value: "/etc/ssl/certs"
- name: REQUESTS_CA_BUNDLE
  value: "/etc/ssl/certs/ca-certificates.crt"
{{- end -}}

{{- /*
  ATTENTION!
  the `wandb.rateLimitEnvs` is dependent on interpolated envs for redis
  to form the connection string and must appear after the redis envs
  in a pod's env section to work porperly.

  Using the wandb-base chart that means that:
    `{{ include "wandb.ratelimitEnvs" . }}`
  MUST appear after:
    `{{ include "wandb.redisEnvs" . }}`
  in the `envTpls` section.
*/ -}}
{{- define "wandb.rateLimitEnvs" -}}
{{- if and .Values.global.api.enabled .Values.global.api.rateLimits.enabled}}
- name: GORILLA_LIMITER
  value: "{{ include "wandb.redis.connectionString" . | trim }}"
- name: GORILLA_DEFAULT_RATE_LIMITS_FILESTREAM_COUNT
  value: "{{ .Values.global.api.rateLimits.filestreamCount }}"
- name: GORILLA_DEFAULT_RATE_LIMITS_FILESTREAM_SIZE
  value: "{{ .Values.global.api.rateLimits.filestreamSize }}"
- name: GORILLA_DEFAULT_RATE_LIMITS_FILESTREAM_PER_RUN_COUNT
  value: "{{ .Values.global.api.rateLimits.fileStreamPerRunCount }}"
- name: GORILLA_DEFAULT_RATE_LIMITS_RUN_UPDATE_COUNT
  value: "{{ .Values.global.api.rateLimits.runUpdateCount }}"
- name: GORILLA_DEFAULT_RATE_LIMITS_SDK_GRAPHQL_QUERY_SECONDS
  value: "{{ .Values.global.api.rateLimits.sdkGraphqlQuerySeconds }}"
- name: GORILLA_DEFAULT_RATE_LIMITS_CREATE_ARTIFACTS
  value: "{{ .Values.global.api.rateLimits.createArtifacts }}"
- name: GORILLA_DEFAULT_RATE_LIMITS_CREATE_ARTIFACTS_TIME_WINDOW
  value: "{{ .Values.global.api.rateLimits.createArtifactsTimeWindow }}"
{{- else }}
- name: GORILLA_LIMITER
  value: "noop://"
{{- end }}
{{- end -}}
