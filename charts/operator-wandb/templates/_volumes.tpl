{{- define "wandb.caCertsVolumeMounts" -}}
- name: wandb-ca-certs
  mountPath: /usr/local/share/ca-certificates/inline
- name: wandb-ca-certs-user
  mountPath: /usr/local/share/ca-certificates/configmap
- name: redis-ca
  mountPath: /etc/ssl/certs/redis_ca.pem
  subPath: redis_ca.pem
{{- end -}}

{{- define "wandb.caCertsVolumes" -}}
- name: wandb-ca-certs
  configMap:
    name: "{{ .Release.Name }}-ca-certs"
- name: wandb-ca-certs-user
  configMap:
    name: '{{ .Values.global.caCertsConfigMap | default "noCertProvided" }}'
    optional: true
- name: redis-ca
  secret:
    secretName: '{{ include "wandb.redis.passwordSecret" . }}'
    items:
      - key: REDIS_CA_CERT
        path: redis_ca.pem
    optional: true
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