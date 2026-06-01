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


{{- define "wandb.internalSignerVolumeMounts" }}
{{- if .Values.global.localService.bypass }}
- name: wandb-internal-signer-root
  mountPath: /vol/env
{{- end }}
{{- end }}

{{- define "wandb.internalSignerVolumes" }}
{{- if .Values.global.localService.bypass }}
- name: wandb-internal-signer-root
  secret:
    secretName: "{{ .Release.Name }}-internal-signer"
{{- end }}
{{- end }}


{{- define "wandb.lumenStagingVolumeMount" }}
- name: lumen-staging-dir
  mountPath: {{ include "wandb.lumen.stagingPath" . }}
{{- end }}

{{- define "wandb.lumenStagingVolume" }}
- name: lumen-staging-dir
  emptyDir: { }
{{- end }}

{{- define "wandb.lumenWifVolumes" }}
{{- if .Values.global.lumen.dataRoot }}
- name: gcp-ksa
  projected:
    sources:
      - serviceAccountToken:
          path: token
          expirationSeconds: 3600
          audience: {{ include "operator-wandb.lumen.audience" . }}
- name: gcp-wif-config
  configMap:
    name: "{{ .Release.Name }}-lumen-gcp-wif"
{{- end }}
{{- end }}

{{- define "wandb.lumenWifVolumeMounts" }}
{{- if .Values.global.lumen.dataRoot }}
- name: gcp-ksa
  mountPath: /var/run/secrets/tokens/gcp-ksa
  readOnly: true
- name: gcp-wif-config
  mountPath: /var/secrets/gcp
  readOnly: true
{{- end }}
{{- end }}

{{- define "wandb.lumenRulesVolume" }}
- name: lumen-managed-install
  configMap:
    name: "{{ .Release.Name }}-lumen-rules"
{{- end }}

{{- define "wandb.lumenRulesVolumeMount" }}
- name: lumen-managed-install
  mountPath: {{ include "wandb.lumen.rulePath" . }}
  subPath: managed-install.yaml
  readOnly: true
{{- end }}