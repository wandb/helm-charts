{{- define "wandb.historyStore" -}}
    {{- $stores := list -}}
    {{- /*
        history-reader is a gRPC service backed by ClickHouse (via the
        history-updater write path). When enabled it is queried first so
        ClickHouse-resident runs are served from it; parquet + bigtable/mysql
        remain as fallbacks for runs not yet migrated.
    */ -}}
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

{{- define "wandb.liveHistoryStore" -}}
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
