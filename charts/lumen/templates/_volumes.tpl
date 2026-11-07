{{- define "wandb.lumenStagingVolumeMount" }}
- name: {{ .Values.stagingDirectory.name }}
  mountPath: {{ include "wandb.lumen.stagingPath" . }}
{{- end }}

{{- define "wandb.lumenStagingVolume" }}
- name: {{ .Values.stagingDirectory.name }}
  ephemeral:
    volumeClaimTemplate:
      spec:
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: {{ .Values.global.lumen.stagingDirectorySize | quote }}
{{- end }}
