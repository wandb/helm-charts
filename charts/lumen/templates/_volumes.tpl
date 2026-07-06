{{- define "wandb.lumenStagingVolumeMount" }}
- name: lumen-staging-dir
  mountPath: {{ include "wandb.lumen.stagingPath" . }}
{{- end }}

{{- define "wandb.lumenStagingVolume" }}
- name: lumen-staging-dir
  emptyDir: { }
{{- end }}