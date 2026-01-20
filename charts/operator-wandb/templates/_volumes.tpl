{{- define "wandb.caCertsVolumeMounts" -}}
- name: wandb-ca-certs-root
  mountPath: /usr/local/share/ca-certificates/
- name: wandb-ca-certs
  mountPath: /usr/local/share/ca-certificates/inline
- name: wandb-ca-certs-user
  mountPath: /usr/local/share/ca-certificates/configmap
- name: redis-ca
  mountPath: /etc/ssl/certs/redis_ca.pem
  subPath: redis_ca.pem
{{ include "wandb.mysql.caCertVolumeMount" . }}
{{ include "wandb.datadogSocketVolumeMounts" . }}
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
    secretName: '{{ include "wandb.redis.passwordSecret" . }}'
    items:
      - key: REDIS_CA_CERT
        path: redis_ca.pem
    optional: true
{{ include "wandb.mysql.caCertVolume" . }}
{{ include "wandb.datadogSocketVolumes" . }}
{{- end -}}

{{- define "wandb.datadogSocketVolumeMounts" -}}
{{- if dig "global" "datadog" "dogstatsd" "uds" "enabled" false .Values }}
{{- $uds := dig "global" "datadog" "dogstatsd" "uds" (dict) .Values -}}
{{- $hostPath := default "/var/run/datadog" $uds.hostPath -}}
{{- $mountPath := default $hostPath $uds.mountPath -}}
- name: datadog-socket
  mountPath: {{ $mountPath | quote }}
{{- end }}
{{- end -}}

{{- define "wandb.datadogSocketVolumes" -}}
{{- if dig "global" "datadog" "dogstatsd" "uds" "enabled" false .Values }}
{{- $uds := dig "global" "datadog" "dogstatsd" "uds" (dict) .Values -}}
{{- $hostPath := default "/var/run/datadog" $uds.hostPath -}}
{{- $hostPathType := default "DirectoryOrCreate" $uds.hostPathType -}}
- name: datadog-socket
  hostPath:
    path: {{ $hostPath | quote }}
    type: {{ $hostPathType | quote }}
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
