{{- define "wandb.historyStore" -}}
  {{- $stores := list -}}
  {{- if .Values.global.historyStore.historyReaderEnabled -}}
    {{- $stores = append $stores (printf "historyreader://%s-history-reader:9244" .Release.Name) -}}
  {{- end -}}
  {{- if .Values.global.historyStore.parquetUseGRPC -}}
    {{- $stores = append $stores (printf "grpc://%s-parquet-grpc:8088" .Release.Name) -}}
  {{- end -}}
  {{- $stores = append $stores (printf "http://%s-parquet:8087/_goRPC_" .Release.Name) -}}

  {{- if not .Values.global.historyStore.parquetOnly -}}
    {{- if .Values.global.bigtable.v3.enabled -}}
      {{- $stores = append $stores (printf "bigtablev3://%s/%s" .Values.global.bigtable.project .Values.global.bigtable.instance) -}}
    {{- end -}}

    {{- if .Values.global.bigtable.v2.enabled -}}
      {{- $stores = append $stores (printf "bigtablev2://%s/%s" .Values.global.bigtable.project .Values.global.bigtable.instance) -}}
    {{- end -}}

    {{- if not (or .Values.global.bigtable.v2.enabled .Values.global.bigtable.v3.enabled) -}}
      {{- $stores = append $stores (include "wandb.mysql" .) -}}
    {{- end -}}
  {{- end -}}

    {{- join "," $stores -}}
{{- end -}}

{{- define "wandb.liveHistoryStoreIsClickhouse" -}}
  {{- /* toString lets history-validation.yaml reject non-string values instead of eq failing first. */ -}}
{{- eq (toString .Values.global.historyStore.liveStore) "clickhouse" -}}
{{- end -}}

{{- define "wandb.liveHistoryStore" -}}
  {{- if eq (include "wandb.liveHistoryStoreIsClickhouse" .) "true" -}}
    {{- $config := include "wandb.olapConfig" (dict "root" . "featureName" "history") | fromYaml -}}
    {{- /*
      Uses the HISTORY_* parts from wandb.historyEnvs, which must precede
      wandb.historyStoreEnvs, rather than GORILLA_HISTORY_STORAGE_ENGINE_ADDRESS:
      an explicit env override of that address renders after this value.
    */ -}}
{{- include "wandb.olapConnectionUrl" (dict "type" $config.type "envVarPrefix" "HISTORY") -}}
  {{- else -}}
    {{- $historyStore := include "wandb.mysql" . -}}
    {{- if or .Values.global.bigtable.v2.enabled .Values.global.bigtable.v3.enabled -}}
      {{- $stores := list -}}

      {{- if .Values.global.bigtable.v3.enabled -}}
        {{- $stores = append $stores (printf "bigtablev3://%s/%s" .Values.global.bigtable.project .Values.global.bigtable.instance) -}}
      {{- end -}}

      {{- if .Values.global.bigtable.v2.enabled -}}
        {{- $stores = append $stores (printf "bigtablev2://%s/%s" .Values.global.bigtable.project .Values.global.bigtable.instance) -}}
      {{- end -}}

      {{- $historyStore = join "," $stores -}}
    {{- end -}}
{{- $historyStore -}}
  {{- end -}}
{{- end -}}

{{- define "wandb.fileStreamWorkerStore" -}}
  {{- $stores := list -}}

  {{- if .Values.global.bigtable.v2.enabled -}}
    {{- $stores = append $stores (printf "bigtablev2://%s/%s" .Values.global.bigtable.project .Values.global.bigtable.instance) -}}
  {{- end -}}

  {{- if .Values.global.bigtable.v3.enabled -}}
    {{- $stores = append $stores (printf "bigtablev3://%s/%s" .Values.global.bigtable.project .Values.global.bigtable.instance) -}}
  {{- end -}}

    {{- join "," $stores -}}
{{- end -}}
