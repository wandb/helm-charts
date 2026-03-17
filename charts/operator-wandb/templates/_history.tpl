{{- define "wandb.historyStore" -}}
    {{- $stores := list -}}
    {{- if .Values.global.olap.history.enabled -}}
        {{- $stores = append $stores "$(GORILLA_STORAGE_ENGINE_ADDRESS)" -}}
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
