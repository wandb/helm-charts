{{- define "wandb.redis.getRedisConfig" -}}
{{- $redisName := default "redis" .redisName }}
{{- $localConfig := dig $redisName (dict) .Values.AsMap }}
{{- $globalConfig := dig $redisName (dict) .Values.global }}
{{- $defaultConfig := .Values.global.redis }}
{{- if $localConfig.host }}
{{ $localConfig | toYaml }}
{{- else if $globalConfig.host }}
{{ $globalConfig | toYaml }}
{{- else }}
{{ $defaultConfig | toYaml }}
{{- end }}
{{- end -}}

{{/*
Return name of secret where redis information is stored
*/}}
{{- define "wandb.redis.passwordSecret" -}}
{{- $redisConfig := fromYaml (include "wandb.redis.getRedisConfig" .) -}}
{{- if $redisConfig.secret.secretName -}}
  {{ $redisConfig.secret.secretName }}
{{- else -}}
  {{- print .Release.Name "-redis-secret" -}}
{{- end -}}
{{- end -}}

{{/*
Return the redis port, if it contains a query string, only return the port
*/}}
{{- define "wandb.redis.port" -}}
{{- $redisConfig := fromYaml (include "wandb.redis.getRedisConfig" .) -}}
{{- $port := $redisConfig.port | toString -}}
{{- if contains "?" $port -}}
{{- $port = splitList "?" $port | first -}}
{{- end -}}
{{- print $port -}}
{{- end -}}

{{/*
Return the redis host, defaulting to the release name prefix if available.
*/}}
{{- define "wandb.redis.host" -}}
{{- $redisConfig := fromYaml (include "wandb.redis.getRedisConfig" .) -}}
{{- if eq $redisConfig.host "" -}}
{{ printf "%s-%s" .Release.Name "redis-master" }}
{{- else -}}
{{ $redisConfig.host }}
{{- end -}}
{{- end -}}

{{/*
Return the redis password
*/}}
{{- define "wandb.redis.password" -}}
{{- $redisConfig := fromYaml (include "wandb.redis.getRedisConfig" .) -}}
{{- print $redisConfig.password -}}
{{- end -}}


{{- define "_portParams" }}
    {{- $redisConfig := fromYaml (include "wandb.redis.getRedisConfig" .) -}}
    {{- $rawPortVal := $redisConfig.port | toString }}
    {{- $queryParams := dict }}
    {{- if contains "?" $rawPortVal }}
        {{- $queryString := splitList "?" $rawPortVal | last }}
        {{- $pairs := splitList "&" $queryString }}
        {{- range $pairs }}
            {{- $pair := splitList "=" . }}
            {{- $queryParams = merge $queryParams (dict (index $pair 0) (index $pair 1)) }}
        {{- end }}
    {{- end }}
    {{- $queryParams | toJson -}}
{{- end }}

{{/*
if a caCert is present, hardcode the caCertPath!
*/}}
{{- define "_caParams" }}
    {{- $redisConfig := fromYaml (include "wandb.redis.getRedisConfig" .) -}}
    {{- $ca := include "wandb.redis.caCert" . }}
    {{- $result := dict }}
    {{- if $ca }}
        {{- $result = merge $result (dict "caCertPath" ( printf "/etc/ssl/certs/%s" $redisConfig.certPath)) }}
    {{- end }}
    {{- $result | toJson -}}
{{- end }}

{{- define "_defaultParams" }}
    {{- $ca := include "wandb.redis.caCert" . }}
        {{- if $ca }}
            {{- (dict "ttlInSeconds" 604800 "tls" "true") | toJson -}}
        {{- else }}
            {{- (dict "ttlInSeconds" 604800) | toJson -}}
        {{- end }}
{{- end }}


{{/*
Compute the query parameters for the redis connection string from a supplied dictionary.
The precedence order (highest to lowest) in which the query parameters are chosen:
1. if a caCert is present, hardcode the caCertPath!
2. values from params/parameters dict
3. queryString in port
4. defaults: ttlInSeconds=604800, also tls=true only if caCert is present
*/}}
{{- define "wandb.redis.parametersQuery" }}
    {{- $caParams := include "_caParams" . | fromJson }}
    {{/* Both `params` and `parameters` have been used, historically */}}
    {{- $valueParams := merge $.Values.global.redis.params $.Values.global.redis.parameters }}
    {{- $portParams := include "_portParams" . | fromJson }}
    {{- $defaultParams := include "_defaultParams" . | fromJson }}

    {{- $finalParams := merge $defaultParams $portParams $valueParams $caParams }}

    {{- $len := len $finalParams }}
    {{- $count := 0 }}
    {{- if gt $len 0 }}
        {{- print "?" -}}
    {{- end }}
    {{- range $key, $val := $finalParams }}
        {{- $count = add $count 1 }}
        {{- $valStr := $val | toString }}
        {{- if $valStr }}
            {{- if gt $len $count  }}
                {{- printf "%s=%s&" $key $valStr -}}
            {{- else }}
                {{- printf "%s=%s" $key $valStr -}}
            {{- end }}
        {{- end }}
    {{- end }}
{{- end }}

{{/*
Return the redis caCert
*/}}
{{- define "wandb.redis.caCert" -}}
{{- $redisConfig := fromYaml (include "wandb.redis.getRedisConfig" .) -}}
{{- print (default "" $redisConfig.caCert) -}}
{{- end -}}


{{- define "wandb.redis.certPath" -}}
{{- $redisConfig := fromYaml (include "wandb.redis.getRedisConfig" .) -}}
{{- print (default "" $redisConfig.certPath) -}}
{{- end -}}

{{/*
This redis connection string adheres to what redis exepcts and does not
include the proprietary query parameters used by WandB.
*/}}
{{- define "wandb.redis.connectionString" -}}
{{- $redisConfig := fromYaml (include "wandb.redis.getRedisConfig" .) -}}
{{- if or $redisConfig.password $redisConfig.secret.secretName -}}
redis://:$(REDIS_PASSWORD)@$(REDIS_HOST):$(REDIS_PORT)$(REDIS_PARAMS)
{{- else -}}
redis://$(REDIS_HOST):$(REDIS_PORT)$(REDIS_PARAMS)
{{- end }}
{{- end }}

{{- define "wandb.redis.settingsCache.connectionString" -}}
{{- $redisConfig := fromYaml (include "wandb.redis.getRedisConfig" (dict "Values" .Values "Release" .Release "redisName" "settingsCache")) -}}
{{- if or $redisConfig.password $redisConfig.secret.secretName -}}
redis://:$(REDIS_SETTINGS_CACHE_PASSWORD)@$(REDIS_SETTINGS_CACHE_HOST):$(REDIS_SETTINGS_CACHE_PORT)$(REDIS_SETTINGS_CACHE_PARAMS)
{{- else -}}
redis://$(REDIS_SETTINGS_CACHE_HOST):$(REDIS_SETTINGS_CACHE_PORT)$(REDIS_SETTINGS_CACHE_PARAMS)
{{- end }}
{{- end }}

{{- define "wandb.redis.metadataCache.connectionString" -}}
{{- $redisConfig := fromYaml (include "wandb.redis.getRedisConfig" (dict "Values" .Values "Release" .Release "redisName" "metadataCache")) -}}
{{- if or $redisConfig.password $redisConfig.secret.secretName -}}
redis://:$(REDIS_METADATA_CACHE_PASSWORD)@$(REDIS_METADATA_CACHE_HOST):$(REDIS_METADATA_CACHE_PORT)$(REDIS_METADATA_CACHE_PARAMS)
{{- else -}}
redis://$(REDIS_METADATA_CACHE_HOST):$(REDIS_METADATA_CACHE_PORT)$(REDIS_METADATA_CACHE_PARAMS)
{{- end }}
{{- end }}

{{- define "wandb.redis.taskQueue" -}}
{{- if .Values.global.executor.enabled }}
{{- $redisConfig := fromYaml (include "wandb.redis.getRedisConfig" (dict "Values" .Values "Release" .Release "redisName" "taskQueue")) -}}
{{- if or $redisConfig.password $redisConfig.secret.secretName -}}
redis://:$(REDIS_TASK_QUEUE_PASSWORD)@$(REDIS_TASK_QUEUE_HOST):$(REDIS_TASK_QUEUE_PORT)$(REDIS_TASK_QUEUE_PARAMS)
{{- else -}}
redis://$(REDIS_TASK_QUEUE_HOST):$(REDIS_TASK_QUEUE_PORT)$(REDIS_TASK_QUEUE_PARAMS)
{{- end }}
{{- else }}
{{- "noop://" }}
{{- end }}
{{- end }}

{{- define "wandb.executor.taskQueue" -}}
{{- $cs := include "wandb.redis.taskQueue" . }}
{{- $params := include "wandb.redis.parametersQuery" (dict "Values" .Values "Release" .Release "redisName" "taskQueue") }}
{{- $concur := .Values.workerConcurrency }}
{{- if $concur -}}
  {{- if $params }}
    {{- $cs = printf "%s&" $cs -}}
  {{- else }}
    {{- $cs = printf "%s?" $cs -}}
  {{- end }}
  {{- $cs = printf "%sconcurrency=%s" $cs ($concur | toString) -}}
{{- end }}
{{- print $cs }}
{{- end }}