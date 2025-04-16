{{- define "wandb.historyStore" -}}
    {{- $stores := list -}}
    {{- $stores = append $stores (printf "http://%s-parquet:8087/_goRPC_" .Release.Name) -}}

    {{- if .Values.global.bigtable.v3.enabled -}}
        {{- $stores = append $stores (printf "bigtablev3://%s/%s" .Values.global.bigtable.project .Values.global.bigtable.instance) -}}
    {{- end -}}

    {{- if .Values.global.bigtable.v2.enabled -}}
        {{- $stores = append $stores (printf "bigtablev2://%s/%s" .Values.global.bigtable.project .Values.global.bigtable.instance) -}}
    {{- end -}}

    {{- if not (or .Values.global.bigtable.v2.enabled .Values.global.bigtable.v3.enabled) -}}
        {{- $stores = append $stores "mysql://$(MYSQL_USER):$(MYSQL_PASSWORD)@$(MYSQL_HOST):$(MYSQL_PORT)/$(MYSQL_DATABASE)?tls=preferred" -}}
    {{- end -}}

    {{- join "," $stores -}}
{{- end -}}
