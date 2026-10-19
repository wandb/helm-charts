{{/* Explicit storage and init-only credentials for bulk export. */}}
{{- define "wandb.bulkExportConfig" -}}
  {{- index .Values.global "weave-trace" "bulkExport" | default dict | toYaml -}}
{{- end }}

{{- define "wandb.bulkExportStorageURI" -}}
  {{- $config := include "wandb.bulkExportConfig" . | fromYaml -}}
  {{- $explicit := get (.Values.global.extraEnv | default dict) "WF_FILE_STORAGE_URI" | default "" -}}
  {{- if and (kindIs "string" $explicit) (not (empty $explicit)) -}}
    {{- $explicit -}}
  {{- else if $config.storageURI -}}
    {{- $config.storageURI -}}
  {{- else -}}
    {{- include "wandb.weaveTraceFileStorageURI" . -}}
  {{- end -}}
{{- end }}

{{- define "wandb.bulkExportInitEnvs" -}}
  {{- $config := include "wandb.bulkExportConfig" . | fromYaml -}}
  {{- $secret := required "bulkExport.provisioner.clickhouseCredentialsSecret is required for init provisioning" $config.provisioner.clickhouseCredentialsSecret -}}
- name: WF_EXPORT_CLICKHOUSE_USER
  valueFrom:
    secretKeyRef:
      name: {{ $secret | quote }}
      key: username
- name: WF_EXPORT_CLICKHOUSE_PASS
  valueFrom:
    secretKeyRef:
      name: {{ $secret | quote }}
      key: password
{{- end }}

{{- define "wandb.bulkExportWriterSecret" -}}
  {{- $config := include "wandb.bulkExportConfig" . | fromYaml -}}
- secretRef:
    name: {{ required "bulkExport.provisioner.writerCredentialsSecret is required for init provisioning" $config.provisioner.writerCredentialsSecret | quote }}
{{- end }}
