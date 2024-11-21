{{/*
Return name of secret where redis information is stored
*/}}
{{- define "wandb.redis.passwordSecret" -}}
{{- if .Values.global.redis.passwordSecret.name -}}
  {{ .Values.global.redis.passwordSecret.name }}
{{- else -}}
  {{- print .Release.Name "-redis" -}}
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
Return the redis to url
*/}}
{{- define "wandb.redis.parametersQuery" }}
{{- range $key, $val := $.Values.global.redis.parameters }}
{{- printf "%s=%s&" $key $val | urlquery }}
{{- end }}
{{- end }}


{{- define "wandb.redis.connectionString" -}}
{{- $password := include "wandb.redis.password" . }}
{{- if or $password .Values.global.redis.passwordSecret.name }}
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
