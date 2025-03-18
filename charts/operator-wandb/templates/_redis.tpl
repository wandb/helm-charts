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
Return the redis port
*/}}
{{- define "wandb.redis.port" -}}
{{- print $.Values.global.redis.port -}}
{{- end -}}

{{/*
Return the redis host
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

{{/*
compute the query parameters for the redis connection string from a supplied dictionary
1. if a caCert is present, hardcode the caCertPath!
2. values from params/parameters dict, but ignore caCertPath
3. queryString in port, but ignore caCertPath
4. assume ttlInSeconds=604800, as a default
*/}}
{{- define "wandb.redis.parametersQuery" }}
{{- $params := merge $.Values.global.redis.params $.Values.global.redis.parameters }}
{{- $len := len $params }}
{{- $count := 1 }}
{{- range $key, $val := $params }}
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
redis://:$(REDIS_PASSWORD)@$(REDIS_HOST):$(REDIS_PORT)
{{- else }}
redis://$(REDIS_HOST):$(REDIS_PORT)
{{- end }}
{{- end }}

{{/*
Return the redis caCert
*/}}
{{- define "wandb.redis.caCert" -}}
{{- print $.Values.global.redis.caCert -}}
{{- end -}}

{{/*
This redis connection string includes the proprietary query parameters used by WandB.
The precedence order in which the query parameters are added is:
- if the connection string already has a query string *INSIDE* it, use only those query parameters
- else if the supplied parametersQuery is not empty, use only those for the query parameters
- else if the caCert is set, use the legacy default values for the query string
- else use the connection string as is
*/}}
{{- define "wandb.redis" -}}
{{- $cs := include "wandb.redis.connectionString" . }}
{{- $ca := include "wandb.redis.caCert" . }}
{{- $query := include "wandb.redis.parametersQuery" . }}
{{- if contains "?" $cs }}
{{- print $cs -}}
{{- else if $query }}
{{- printf "%s?%s" $cs $query -}}
{{- else if $ca }}
{{- printf "%s?tls=true&caCertPath=/etc/ssl/certs/redis_ca.pem&ttlInSeconds=604800" $cs -}}
{{- else }}
{{- print $cs -}}
{{- end }}
{{- end }}


{{- define "wandb.redis.taskQueue" -}}
{{- if .Values.global.executor.enabled }}
{{- include "wandb.redis" .}}
{{- else }}
{{- "noop://" }}
{{- end }}
{{- end }}
