{{/*
Shared ConfigMap data for the primary Parquet and optional parquet-headless subcharts
(parquet metadata cache address is added when that subchart is installed).
*/}}
{{- define "operator-wandb.parquetConfigMapData" -}}
# Port configuration
GORILLA_PARQUET_PORT: "8087"
# RPC path configuration
GORILLA_PARQUET_RPC_PATH: "/_goRPC_"
# Task queue configuration
GORILLA_TASK_QUEUE_WORKER_ENABLED: "false"
# Parquet-specific configuration
GORILLA_USE_PARQUET_HISTORY_STORE: "true"
GORILLA_PARQUET_ARROW_BUFFER_SIZE: "2147483648" # 2GB
GORILLA_COLLECT_AUDIT_LOGS: "true"
# Parquet metadata cache configuration
{{- if index .Values "parquet-metadata-cache" "install" }}
GORILLA_PARQUET_READER_REMOTE_METADATA_CACHE_ADDR: "{{ .Release.Name }}-parquet-metadata-cache:9091"
{{- end }}
{{- end }}
