{{/*
  Assorted bucket related helpers.
*/}}
{{- define "wandb.bucket.secret" -}}
{{- if .Values.global.bucket.secret.secretName -}}
  {{ .Values.global.bucket.secret.secretName }}
{{- else }}
  {{- print .Release.Name "-bucket" -}}
{{- end -}}
{{- end }}

{{- define "wandb.bucket.config" -}}
{{ .Release.Name }}-bucket-configmap
{{- end -}}


{{/*
  THIS IS FOR INTERNAL USE ONLY
  any end user attempting to set these may experience undefined behavior 
*/}}
{{- define "wandb.bucket.cwIdentity" -}}
- name: COREWEAVE_WANDB_INTEGRATION_ACCESS_ID
  valueFrom:
    secretKeyRef:
      name: "wandb-internal-cw-identity"
      key: "accessKeyId"
      optional: true
- name: COREWEAVE_WANDB_INTEGRATION_SECRET_KEY
  valueFrom:
    secretKeyRef:
      name: "wandb-internal-cw-identity"
      key: "secretKey"
      optional: true
{{- end -}}

{{- define "wandb.bucket" -}}
{{- $url := "" -}}
{{- $path := "" -}}
{{- $provider := "" -}}
{{- $accessKey := "" -}}
{{- $secretKey := "" -}}
{{- if .Values.global.bucket.name -}}
{{- $provider = .Values.global.bucket.provider -}}
{{- $path = .Values.global.bucket.path -}}
{{- $accessKey = default "" .Values.global.bucket.accessKey -}}
{{- $secretKey = default "" .Values.global.bucket.secretKey -}}
name: {{ .Values.global.bucket.name }}
region: {{ .Values.global.bucket.region }}
kmsKey: {{ .Values.global.bucket.kmsKey }}
{{- else -}}
{{- $provider = .Values.global.defaultBucket.provider -}}
{{- $path = .Values.global.defaultBucket.path -}}
{{- $accessKey = default "" .Values.global.defaultBucket.accessKey -}}
{{- $secretKey = default "" .Values.global.defaultBucket.secretKey -}}
name: {{ .Values.global.defaultBucket.name }}
region: {{ .Values.global.defaultBucket.region }}
kmsKey: {{ .Values.global.defaultBucket.kmsKey }}
{{- end }}
provider: {{ $provider }}
path: {{ $path }}
accessKey: {{ $accessKey }}
secretKey: {{ $secretKey }}
accessKeyName: {{ .Values.global.bucket.secret.accessKeyName }}
secretKeyName: {{ .Values.global.bucket.secret.secretKeyName }}
secretName: {{ include "wandb.bucket.secret" . }}
{{- if eq $path "" -}}

{{- if eq $provider "cw" -}}
  {{- if or (and $accessKey $secretKey) .Values.global.bucket.secret.secretName -}}
    {{- $url = "cw://$(BUCKET_ACCESS_KEY):$(BUCKET_SECRET_KEY)@$(BUCKET_NAME)" -}}
  {{- else -}}
    {{- $url = "cw://$(BUCKET_NAME)" -}}
  {{- end -}}
{{- end -}}

{{- if eq $provider "az" -}}
  {{- $url = "az://$(BUCKET_NAME)" -}}
{{- end -}}

{{- if eq $provider "gcs" -}}
  {{- $url = "gs://$(BUCKET_NAME)" -}}
{{- end -}}

{{- if eq $provider "s3" -}}
  {{- if or (and $accessKey $secretKey) .Values.global.bucket.secret.secretName -}}
    {{- $url = "s3://$(BUCKET_ACCESS_KEY):$(BUCKET_SECRET_KEY)@$(BUCKET_NAME)" -}}
  {{- else -}}
    {{- $url = "s3://$(BUCKET_NAME)" -}}
  {{- end -}}
{{- end -}}

{{- else -}}

{{- if eq $provider "cw" -}}
  {{- if or (and $accessKey $secretKey) .Values.global.bucket.secret.secretName -}}
    {{- $url = "cw://$(BUCKET_ACCESS_KEY):$(BUCKET_SECRET_KEY)@$(BUCKET_NAME)/$(BUCKET_PATH)" -}}
  {{- else -}}
    {{- $url = "cw://$(BUCKET_NAME)/$(BUCKET_PATH)" -}}
  {{- end -}}
{{- end -}}

{{- if eq $provider "az" -}}
  {{- $url = "az://$(BUCKET_NAME)/$(BUCKET_PATH)" -}}
{{- end -}}

{{- if eq $provider "gcs" -}}
  {{- $url = "gs://$(BUCKET_NAME)/$(BUCKET_PATH)" -}}
{{- end -}}

{{- if eq $provider "s3" -}}
  {{- if or (and $accessKey $secretKey) .Values.global.bucket.secret.secretName -}}
    {{- $url = "s3://$(BUCKET_ACCESS_KEY):$(BUCKET_SECRET_KEY)@$(BUCKET_NAME)/$(BUCKET_PATH)" -}}
  {{- else -}}
    {{- $url = "s3://$(BUCKET_NAME)/$(BUCKET_PATH)" -}}
  {{- end -}}
{{- end -}}

{{- end -}}
{{- $url = trimSuffix "/" $url }}
url: {{ $url }}
{{- end -}}
