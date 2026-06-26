
{{- define "wandb.lumen.gorilla.containerPort" -}}
{{- if include "wandb.lumen.publish.gorilla" . }}
- name: lumen
  containerPort: 16060
  protocol: TCP
{{- end }}
{{- end -}}
