cluster: {{ .Values.cluster }}

{{- with .Values.zone }}
zone: {{ . | quote }}
{{- end }}

{{- if eq .Values.storage.use "gcs" }}
storage:
  provider: GCS
  bucket: {{ tpl .Values.storage.gcs.bucket | required ".Values.storage.gcs.bucket is required when using gcs." }}
  {{- if .Values.storage.gcs.prefix }}
  prefix: {{ tpl .Values.storage.gcs.prefix }}
  {{- end }}
{{- else if eq .Values.storage.use "s3" }}
storage:
  provider: S3
  bucket: {{ tpl .Values.storage.s3.bucket | required ".Values.storage.s3.bucket is required when using s3." }}
  region: {{ tpl .Values.storage.s3.region | required ".Values.storage.s3.region is required when using s3." }}
  {{- if .Values.storage.s3.prefix }}
  prefix: {{ tpl .Values.storage.s3.prefix }}
  {{- end }}
  {{- if .Values.storage.s3.endpoint }}
  endpoint: {{ tpl .Values.storage.s3.endpoint }}
  {{- end }}
  {{- if .Values.storage.s3.accessKeyId }}
  access_key_id:
    string: {{ tpl .Values.storage.s3.accessKeyId . | quote }}
  secret_access_key:
    path: /config/secrets/storage/secret_access_key
  {{- end }}
  {{- if .Values.storage.s3.forcePathStyle }}
  force_path_style: {{ .Values.storage.s3.forcePathStyle }}
  {{- end }}
{{- end }}

{{- if eq .Values.metadata.use "etcd" }}
{{- if not .Values.metadata.etcd.addresses }}
{{- fail ".Values.metadata.etcd.addresses is required when using etcd" }}
{{- end }}
etcd:
  addresses:
{{- range .Values.metadata.etcd.addresses }}
  - host: {{ tpl .host $ | quote }}
    port: {{ .port }}
{{- end }}
{{- with .Values.metadata.etcd.tls }}
  tls:
    {{- if .insecureSkipVerify }}
    insecure_skip_verify: true
    {{- end }}
    {{- if .rootCaSecret }}
    root_cas:
    - path: /config/secrets/tls-etcd-client/ca.crt
    {{- end }}
{{- end }}
{{- end }}

{{- if .Values.dataEnforcement }}
data_enforcement:
  {{- toYaml .Values.dataEnforcement | nindent 2 }}
{{- end }}

kafka:
  {{- with .Values.kafka.address }}
  {{- if (or (not .host) (not .port)) }}
  {{- fail "When .Values.kafka.address is set, both .host and .port must be set" }}
  {{- end }}
  address:
    {{- with .host }}
    host: {{ . | quote }}
    {{- end }}
    {{- with .port }}
    port: {{ . }}
    {{- end }}
  {{- end }}
  {{- with .Values.kafka.publicAddress }}
  {{- if (or (not .host) (not .port)) }}
  {{- fail "When .Values.kafka.publicAddress is set, both .host and .port must be set" }}
  {{- end }}
  {{- end }}
  public_address:
    host: {{ .Values.kafka.publicAddress.host | default (printf "%s.%s.svc.cluster.local" (include "bufstream.name" .) (include "bufstream.namespace" .)) | quote }}
    port: {{ .Values.kafka.publicAddress.port | default (include "bufstream.containerPort" "kafka") }}
  {{ if .Values.kafka.tlsCertificateSecrets }}
  tls:
    {{ with .Values.kafka.tlsCertificateSecrets }}
    certificates:
      {{ range $index, $secretName := . }}
      - chain:
          path: /config/secrets/tls-{{ $index }}/tls.crt
        private_key:
          path: /config/secrets/tls-{{ $index }}/tls.key
      {{- end }}
    {{- end }}
    client_auth: {{ default .Values.kafka.tlsClientAuth "NO_CERT" }}
    {{ if .Values.kafka.tlsClientCas }}
    client_cas:
      path: /config/secrets/tls-client/tls.crt
    {{- end }}
  {{- end }}
  fetch_eager: {{ .Values.kafka.fetchEager }}
  fetch_sync: {{ .Values.kafka.fetchSync }}
  produce_concurrent: {{ .Values.kafka.produceConcurrent }}
  zone_balance_strategy: {{ .Values.kafka.zoneBalanceStrategy }}
  partition_balance_strategy: {{ .Values.kafka.partitionBalanceStrategy }}
  request_buffer_size: {{ .Values.kafka.requestBufferSize }}
  idle_timeout: {{ .Values.kafka.idleTimeout }}
  num_partitions: {{ .Values.kafka.numPartitions }}
  exact_log_sizes: {{ .Values.kafka.exactLogSizes }}
  exact_log_offsets: {{ .Values.kafka.exactLogOffsets }}
  group_consumer_session_timeout: {{ .Values.kafka.groupConsumerSessionTimeout }}
  group_consumer_session_timeout_max: {{ .Values.kafka.groupConsumerSessionTimeoutMax }}
  group_consumer_session_timeout_min: {{ .Values.kafka.groupConsumerSessionTimeoutMin }}

connect_address:
  host: 0.0.0.0
  port: {{ include "bufstream.containerPort" "connect" }}

{{- if or (.Values.connectTLS.server) (.Values.connectTLS.client) }}
connect_tls:
  {{ with .Values.connectTLS.server.certificateSecrets }}
  server:
    certificates:
      {{ range $index, $secretName := . }}
      - chain:
          path: /config/secrets/tls-ctrl-server-{{ $index }}/tls.crt
        private_key:
          path: /config/secrets/tls-ctrl-server-{{ $index }}/tls.key
      {{- end }}
    {{- end }}
  {{- with .Values.connectTLS.client }}
  client:
    {{- if .insecureSkipVerify }}
    insecure_skip_verify: true
    {{- end }}
    {{- if .rootCaSecret }}
    root_cas:
      - path: /config/secrets/tls-ctrl-client/ca.crt
    {{- end }}
  {{- end }}
{{- end }}

{{- if .Values.adminTLS }}
admin_tls:
  {{ with .Values.adminTLS.certificateSecrets }}
  certificates:
    {{ range $index, $secretName := . }}
    - chain:
        path: /config/secrets/tls-admin-{{ $index }}/tls.crt
      private_key:
        path: /config/secrets/tls-admin-{{ $index }}/tls.key
    {{- end }}
  {{- end }}
{{- end }}

{{- include "bufstream.observability" . }}
