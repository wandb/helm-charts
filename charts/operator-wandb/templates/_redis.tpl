{{/*
Return name of secret where redis information is stored
*/}}
{{- define "wandb.redis.passwordSecret" -}}
{{- if .Values.global.redis.secret.secretName -}}
  {{ .Values.global.redis.secret.secretName }}
{{- else -}}
  {{- print .Release.Name "-redis-secret" -}}
{{- end -}}
{{- end -}}

{{/*
Return the redis port, if it contains a query string, only return the port
*/}}
{{- define "wandb.redis.port" -}}
{{- $port := $.Values.global.redis.port | toString -}}
{{- if contains "?" $port -}}
{{- $port = splitList "?" $port | first -}}
{{- end -}}
{{- print $port -}}
{{- end -}}

{{/*
Return the redis host, defaulting to the release name prefix if available.
*/}}
{{- define "wandb.redis.host" -}}
{{- if eq .Values.global.redis.host "" -}}
{{ printf "%s-%s" .Release.Name "redis-master" }}
{{- else -}}
{{ .Values.global.redis.host }}
{{- end -}}
{{- end -}}

{{/*
Return the redis password
*/}}
{{- define "wandb.redis.password" -}}
{{- print $.Values.global.redis.password -}}
{{- end -}}


{{- define "_portParams" }}
    {{- $rawPortVal := $.Values.global.redis.port | toString }}
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
    {{- $ca := include "wandb.redis.caCert" . }}
    {{- $result := dict }}
    {{- if $ca }}
        {{- $result = merge $result (dict "caCertPath" "/etc/ssl/certs/redis_ca.pem") }}
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
    {{- $count := 1 }}
    {{- if gt $len 0 }}
        {{- print "?" -}}
    {{- end }}
    {{- range $key, $val := $finalParams }}
        {{- $valStr := $val | toString }}
        {{- if $valStr }}
            {{- $count = add1 $count }}
            {{- if lt $count $len }}
                {{- printf "%s=%s&" $key $valStr -}}
            {{- else }}
                {{- printf "%s=%s" $key $valStr -}}
            {{- end }}
        {{- end }}
    {{- end }}
{{- end }}


{{/*
This redis connection string adheres to what redis exepcts and does not
include the proprietary query parameters used by WandB.
*/}}
{{- define "wandb.redis.connectionString" -}}
{{- $password := include "wandb.redis.password" . }}
{{- if or $password .Values.global.redis.secret.secretName }}
redis://:$(REDIS_PASSWORD)@$(REDIS_HOST):$(REDIS_PORT)$(REDIS_PARAMS)
{{- else }}
redis://$(REDIS_HOST):$(REDIS_PORT)$(REDIS_PARAMS)
{{- end }}
{{- end }}

{{/*
Return the redis caCert
*/}}
{{- define "wandb.redis.caCert" -}}
{{- print $.Values.global.redis.caCert -}}
{{- end -}}


{{- define "wandb.redis.taskQueue" -}}
{{- if .Values.global.executor.enabled }}
{{- include "wandb.redis.connectionString" .}}
{{- else }}
{{- "noop://" }}
{{- end }}
{{- end }}
