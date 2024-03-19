{{/*
Create a helper template for common labels in the Prometheus subchart.
*/}}
{{- define "prometheus.commonMetaLabels" -}}
{{- $globalCommonLabels := .Values.global.common.labels -}}
{{- if $globalCommonLabels }}
{{-   range $key, $value := $globalCommonLabels }}
{{ $key }}: {{ $value | quote }}
{{-   end }}
{{- end -}}
{{- end -}}