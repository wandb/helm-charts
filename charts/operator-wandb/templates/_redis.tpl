{{/*
Return name of secret where redis information is stored or fallback if not present
*/}}
{{- define "wandb.redis.passwordSecret" -}}
{{- if .Values.global.redis.secretName -}}
  {{ .Values.global.redis.secretName }}
{{- else -}}
  {{- print .Release.Name "-redis" -}}
{{- end -}}
{{- end }}

{{/*
Return the redis port
*/}}
{{- define "wandb.redis.port" -}}
{{- $redisPort := .Values.global.redis.port -}}
{{- if .Values.global.redis.secretName -}}
  {{- $secret := lookup "v1" "Secret" .Release.Namespace .Values.global.redis.secretName -}}
  {{- if $secret -}}
    {{- $redisPort = (index $secret.data "REDIS_PORT") | b64dec -}}
  {{- end -}}
{{- end -}}
{{- $redisPort -}} 
{{- end -}}

{{/*
Return the redis host
*/}}
{{- define "wandb.redis.host" -}}
{{- $redisHost := .Values.global.redis.host -}}
{{- if .Values.global.redis.secretName -}}
  {{- $secret := lookup "v1" "Secret" .Release.Namespace .Values.global.redis.secretName -}}
  {{- if $secret -}}
    {{- $redisHost = (index $secret.data "REDIS_HOST") | b64dec -}}
  {{- end -}}
{{- else -}}
  {{- if eq $redisHost "" -}}
    {{- $redisHost = printf "%s-%s" .Release.Name "redis-master" -}}
  {{- end -}}
{{- end -}}
{{- $redisHost -}}
{{- end -}}

{{/*
Return the redis password
*/}}
{{- define "wandb.redis.password" -}}
{{- $redisPassword := .Values.global.redis.password -}}
{{- if .Values.global.redis.secretName -}}
  {{- $secret := lookup "v1" "Secret" .Release.Namespace .Values.global.redis.secretName -}}
  {{- if $secret -}}
    {{- $redisPassword = (index $secret.data "REDIS_PASSWORD") | b64dec -}}
  {{- end -}}
{{- end -}}
{{- $redisPassword -}}
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
{{- $redisCaCert := .Values.global.redis.caCert -}}
{{- if .Values.global.redis.secretName -}}
  {{- $secret := lookup "v1" "Secret" .Release.Namespace .Values.global.redis.secretName -}}
  {{- if $secret -}}
    {{- $redisCaCert = (index $secret.data "REDIS_CA_CERT") | b64dec -}}
  {{- end -}}
{{- end -}}
{{- $redisCaCert -}}
{{- end -}}
