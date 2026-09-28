{{- define "wandb.lumenStagingVolumeMount" }}
- name: lumen-staging-dir
  mountPath: {{ include "wandb.lumen.stagingPath" . }}
{{- end }}

{{- define "wandb.lumenStagingVolume" }}
- name: lumen-staging-dir
  ephemeral:
    volumeClaimTemplate:
      spec:
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: {{ .Values.global.lumen.stagingDirectorySize | quote }}
{{- end }}
