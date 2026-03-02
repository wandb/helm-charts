{{/*
Return the Registry Search ClickHouse host
*/}}
{{- define "wandb.registrySearch.host" -}}
{{- print $.Values.global.registrySearch.host -}}
{{- end -}}

{{/*
Return the Registry Search ClickHouse port
*/}}
{{- define "wandb.registrySearch.port" -}}
{{- print $.Values.global.registrySearch.port -}}
{{- end -}}

{{/*
Return the Registry Search ClickHouse user
*/}}
{{- define "wandb.registrySearch.user" -}}
{{- print $.Values.global.registrySearch.user -}}
{{- end -}}

{{/*
Return the Registry Search ClickHouse password
*/}}
{{- define "wandb.registrySearch.password" -}}
{{- print $.Values.global.registrySearch.password -}}
{{- end -}}

{{/*
Return the Registry Search ClickHouse database
*/}}
{{- define "wandb.registrySearch.database" -}}
{{- print $.Values.global.registrySearch.database -}}
{{- end -}}

{{/*
Const: Internal secret name for the password
*/}}
{{- define "wandb.registrySearch.internalSecretName" -}}
{{- print .Release.Name "-registry-search-secret" -}}
{{- end -}}

{{- define "wandb.registrySearch.internalSecretKey" -}}
{{- print "REGISTRY_SEARCH_CH_PASSWORD" -}}
{{- end -}}

{{/*
Compose the full clickhouse:// connection URL from individual env var references.
Only rendered when registrySearch is enabled.
*/}}
{{- define "wandb.registrySearchAddress" -}}
{{- if .Values.global.registrySearch.enabled -}}
clickhouse://$(REGISTRY_SEARCH_CH_USER):$(REGISTRY_SEARCH_CH_PASSWORD)@$(REGISTRY_SEARCH_CH_HOST):$(REGISTRY_SEARCH_CH_PORT)/$(REGISTRY_SEARCH_CH_DATABASE)?fail-fast=true&tls=true
{{- end -}}
{{- end -}}
