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