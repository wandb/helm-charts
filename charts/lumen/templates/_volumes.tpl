{{- define "wandb.lumenStagingVolumeMount" }}
- name: lumen-staging-dir
  mountPath: {{ include "wandb.lumen.stagingPath" . }}
{{- end }}

{{- define "wandb.lumenStagingVolume" }}
- name: lumen-staging-dir
  emptyDir: { }
{{- end }}

{{- define "wandb.lumenUISecretVolume" }}
{{- if .Values.secretProviderClass.enabled }}
- name: lumen-ui-secrets
  csi:
    driver: secrets-store-gke.csi.k8s.io
    readOnly: true
    volumeAttributes:
      secretProviderClass: {{ printf "%s-ui" .Release.Name | quote }}
{{- end }}
{{- end }}

{{- define "wandb.lumenUISecretVolumeMount" }}
{{- if .Values.secretProviderClass.enabled }}
- name: lumen-ui-secrets
  mountPath: /var/run/secrets/lumen-ui
  readOnly: true
{{- end }}
{{- end }}
