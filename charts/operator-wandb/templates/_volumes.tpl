{{- define "wandb.caCertsVolumeMounts" -}}
- name: wandb-ca-certs-root
  mountPath: /usr/local/share/ca-certificates/
- name: wandb-ca-certs
  mountPath: /usr/local/share/ca-certificates/inline
- name: wandb-ca-certs-user
  mountPath: /usr/local/share/ca-certificates/configmap
- name: redis-ca
  mountPath: /etc/ssl/certs/{{ include "wandb.redis.certPath" (dict "Values" .Values "Release" .Release "redisName" "redis") }}
  subPath: {{ include "wandb.redis.certPath" (dict "Values" .Values "Release" .Release "redisName" "redis") }}
{{ if .Values.global.taskQueue.host }}
- name: redis-task-queue-ca
  mountPath: /etc/ssl/certs/{{ include "wandb.redis.certPath" (dict "Values" .Values "Release" .Release "redisName" "taskQueue") }}
  subPath: {{ include "wandb.redis.certPath" (dict "Values" .Values "Release" .Release "redisName" "taskQueue") }}
{{- end }}
{{ if .Values.global.metadataCache.host }}
- name: redis-metadata-cache-ca
  mountPath: /etc/ssl/certs/{{ include "wandb.redis.certPath" (dict "Values" .Values "Release" .Release "redisName" "metadataCache") }}
  subPath: {{ include "wandb.redis.certPath" (dict "Values" .Values "Release" .Release "redisName" "metadataCache") }}
{{- end }}
{{ if .Values.global.settingsCache.host }}
- name: redis-settings-cache-ca
  mountPath: /etc/ssl/certs/{{ include "wandb.redis.certPath" (dict "Values" .Values "Release" .Release "redisName" "settingsCache") }}
  subPath: {{ include "wandb.redis.certPath" (dict "Values" .Values "Release" .Release "redisName" "settingsCache") }}
{{- end }}
{{- end -}}

{{- define "wandb.caCertsVolumes" -}}
- name: wandb-ca-certs-root
  emptyDir: {}
- name: wandb-ca-certs
  configMap:
    name: "{{ .Release.Name }}-ca-certs"
- name: wandb-ca-certs-user
  configMap:
    name: '{{ .Values.global.caCertsConfigMap | default "noCertProvided" }}'
    optional: true
- name: redis-ca
  secret:
    secretName: '{{ include "wandb.redis.passwordSecret" (dict "Values" .Values "Release" .Release "redisName" "redis") }}'
    items:
      - key: REDIS_CA_CERT
        path: '{{ include "wandb.redis.certPath" (dict "Values" .Values "Release" .Release "redisName" "redis") }}'
    optional: true
{{ if .Values.global.taskQueue.host }}
- name: redis-task-queue-ca
  secret:
    secretName: '{{ include "wandb.redis.passwordSecret" (dict "Values" .Values "Release" .Release "redisName" "taskQueue") }}'
    items:
      - key: REDIS_TASK_QUEUE_CA_CERT
        path: '{{ include "wandb.redis.certPath" (dict "Values" .Values "Release" .Release "redisName" "taskQueue") }}'
    optional: true
{{- end }}
{{ if .Values.global.metadataCache.host }}
- name: redis-metadata-cache-ca
  secret:
    secretName: '{{ include "wandb.redis.passwordSecret" (dict "Values" .Values "Release" .Release "redisName" "metadataCache") }}'
    items:
      - key: REDIS_METADATA_CACHE_CA_CERT
        path: '{{ include "wandb.redis.certPath" (dict "Values" .Values "Release" .Release "redisName" "metadataCache") }}'
    optional: true
{{- end }}
{{ if .Values.global.settingsCache.host }}
- name: redis-settings-cache-ca
  secret:
    secretName: '{{ include "wandb.redis.passwordSecret" (dict "Values" .Values "Release" .Release "redisName" "settingsCache") }}'
    items:
      - key: REDIS_SETTINGS_CACHE_CA_CERT
        path: '{{ include "wandb.redis.certPath" (dict "Values" .Values "Release" .Release "redisName" "settingsCache") }}'
    optional: true
{{- end }}
{{- end -}}

{{- define "wandb.gcsFuseVolumeMounts" }}
{{- if .Values.fuse.enabled }}
- name: fuse
  mountPath: "/{{ (include "wandb.bucket" . | fromYaml).name }}"
{{- end }}
{{- end }}

{{- define "wandb.gcsFuseVolumes" }}
{{- if .Values.fuse.enabled }}
- name: fuse
{{- if and (eq (include "wandb.bucket" . | fromYaml).provider "gcs") (eq .Values.global.cloudProvider "gcp") }}
  csi:
    driver: gcsfuse.csi.storage.gke.io
    readOnly: true
    volumeAttributes:
      bucketName: {{ (include "wandb.bucket" . | fromYaml).name }}
      mountOptions: "implicit-dirs,file-cache:enable-parallel-downloads:true,metadata-cache:stat-cache-max-size-mb:-1,metadata-cache:type-cache-max-size-mb:-1,file-system:kernel-list-cache-ttl-secs:-1,metadata-cache:ttl-secs:-1"
      fileCacheCapacity: "{{ .Values.fuse.fileCacheCapacity }}"
      fileCacheForRangeRead: "true"
      gcsfuseMetadataPrefetchOnMount: "true"
{{- else }}
  emptyDir: {}
{{- end }}
{{- end }}
{{- end }}
