{{/*
Return name of secret where redis information is stored
*/}}
{{- define "wandb.redis.passwordSecret" -}}
{{- print .Release.Name "-redis" -}}
{{- end -}}

{{/*
Return the redis port
*/}}
{{- define "wandb.redis.port" -}}
{{- print $.Values.global.redis.port -}}
{{- end -}}

{{/*
Return the db host
*/}}
{{- define "wandb.redis.host" -}}
{{- if eq .Values.global.redis.host "" -}}
{{ printf "%s-%s" .Release.Name "redis" }}
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
Return the redis to url
*/}}
{{- define "wandb.redis.parametersQuery" }}
{{- range $key, $val := $.Values.global.redis.parameters }}
{{- printf "%s=%s&" $key $val | urlquery }}
{{- end }}
{{- end }}


{{- define "wandb.redis.connectionString" -}}
{{- $password := include "wandb.redis.password" . }}
{{- if $password }}
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
