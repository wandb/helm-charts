{{- define "wandb.ownerReferences" -}}
ownerReferences:
{{- range .Values.global.ownerReferences }}
- apiVersion: {{ .apiVersion }}
  kind: {{ .kind }}
  name: {{ .name }}
  uid: {{ .uid }}
  controller: {{ .controller }}
  blockOwnerDeletion: {{ .blockOwnerDeletion }}
{{- end }}
{{- end -}}