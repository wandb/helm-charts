{{/* An explicitly configured global.env namespace takes precedence, including an empty string. */}}
{{- define "wandb.rum.customerNamespace" -}}
  {{- $extraEnv := .Values.global.extraEnv | default dict -}}
  {{- $env := .Values.global.env | default dict -}}
  {{- if hasKey $env "TAG_CUSTOMER_NS" -}}
    {{- index $env "TAG_CUSTOMER_NS" | default "" -}}
  {{- else -}}
    {{- index $extraEnv "TAG_CUSTOMER_NS" | default "" -}}
  {{- end -}}
{{- end -}}

{{- define "wandb.rum.validate" -}}
  {{- $rum := .Values.global.datadog.rum -}}
  {{- if not (kindIs "bool" $rum.enabled) -}}
    {{- fail "global.datadog.rum.enabled must be a boolean" -}}
  {{- end -}}
  {{- if $rum.enabled -}}
    {{- range $name := list "profilingSampleRate" "sessionReplaySampleRate" "sessionSampleRate" "traceSampleRate" -}}
      {{- $rate := index $rum $name -}}
      {{- if not (or (kindIs "int" $rate) (kindIs "int64" $rate) (kindIs "float64" $rate)) -}}
        {{- fail (printf "global.datadog.rum.%s must be a whole number between 0 and 100" $name) -}}
      {{- end -}}
      {{- $numericRate := float64 $rate -}}
      {{- if or (ne $numericRate (floor $numericRate)) (lt $numericRate 0.0) (gt $numericRate 100.0) -}}
        {{- fail (printf "global.datadog.rum.%s must be a whole number between 0 and 100" $name) -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
