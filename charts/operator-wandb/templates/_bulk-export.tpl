{{/* Non-secret selection for a preconfigured ClickHouse writer collection. */}}
{{- define "wandb.bulkExportConfig" -}}
  {{- index .Values.global "weave-trace" "bulkExport" | default dict | toYaml -}}
{{- end }}

{{- define "wandb.bulkExportStorageURI" -}}
  {{- $config := include "wandb.bulkExportConfig" . | fromYaml -}}
  {{- if $config.storageURI -}}
    {{- $config.storageURI -}}
  {{- else -}}
    {{- $explicit := get (.Values.global.extraEnv | default dict) "WF_FILE_STORAGE_URI" | default "" -}}
    {{- $media := include "wandb.weaveTraceFileStorageURI" . -}}
    {{- if and (kindIs "string" $explicit) (not (empty $explicit)) -}}
      {{- $explicit -}}
    {{- else if $media -}}
      {{- $media -}}
    {{- else -}}
      {{- $bucket := .Values.global.defaultBucket -}}
      {{- if not (empty .Values.global.bucket.provider) -}}
        {{- $bucket = .Values.global.bucket -}}
      {{- end -}}
      {{- if eq $bucket.provider "s3" -}}
        {{- printf "s3://%s" $bucket.name -}}
      {{- else if has $bucket.provider (list "gcs" "gs") -}}
        {{- printf "gs://%s" $bucket.name -}}
      {{- else if eq $bucket.provider "az" -}}
        {{- printf "az://%s/%s" $bucket.name (first (splitList "/" (trimAll "/" $bucket.path))) -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end }}

{{- define "wandb.bulkExportConfigMapName" -}}
  {{- $config := include "wandb.bulkExportConfig" . | fromYaml -}}
  {{- if $config.configMapName -}}
    {{- $config.configMapName -}}
  {{- else -}}
    {{- $content := dict "settings" $config "storageURI" (include "wandb.bulkExportStorageURI" .) -}}
    {{- printf "%s-weave-export-%s" .Release.Name (toJson $content | sha256sum | trunc 10) -}}
  {{- end -}}
{{- end }}

{{- define "wandb.bulkExportVolumes" -}}
  {{- $config := include "wandb.bulkExportConfig" . | fromYaml -}}
  {{- if $config.enabled }}
- name: weave-export-config
  configMap:
    name: {{ include "wandb.bulkExportConfigMapName" . }}
    optional: true
  {{- end }}
{{- end }}

{{- define "wandb.bulkExportVolumeMounts" -}}
  {{- $config := include "wandb.bulkExportConfig" . | fromYaml -}}
  {{- if $config.enabled }}
- name: weave-export-config
  mountPath: /etc/weave
  readOnly: true
  {{- end }}
{{- end }}
