
{{- define "wandb.lumen.gorilla.containerPort" -}}
- name: lumen
  containerPort: 16060
  protocol: TCP
{{- end -}}
