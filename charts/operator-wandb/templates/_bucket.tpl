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
Returns the Azure identity used to authenticate the effective bucket. The
global identity belongs to the deployment. Customer buckets retain the legacy
key path unless they explicitly select workload identity.
*/}}
{{- define "wandb.azureStorageIdentity" -}}
  {{- $bucket := include "wandb.bucket" . | fromYaml -}}
  {{- $hasCustomerBucket := not (empty .Values.global.bucket.name) -}}
  {{- $globalIdentity := default (dict) .Values.global.azureStorageIdentity -}}
  {{- $globalTenantId := default "" $globalIdentity.tenantId -}}
  {{- $globalClientId := default "" $globalIdentity.clientId -}}
  {{- $tenantId := default "" $bucket.azureTenantId -}}
  {{- $clientId := default "" $bucket.azureClientId -}}
  {{- $globalConfigured := and (not (empty $globalTenantId)) (not (empty $globalClientId)) -}}
  {{- $bucketIdentityConfigured := and (not (empty $tenantId)) (not (empty $clientId)) -}}
  {{- $authMethod := default "" .Values.global.bucket.azureAuthMethod -}}
  {{- if ne (empty $globalTenantId) (empty $globalClientId) -}}
    {{- fail "global.azureStorageIdentity.tenantId and clientId must be provided together" -}}
  {{- end -}}
  {{- if and (eq $bucket.provider "az") (ne (empty $tenantId) (empty $clientId)) -}}
    {{- fail "Azure bucket azureTenantId and azureClientId must be provided together" -}}
  {{- end -}}
  {{- if and (not (empty $authMethod)) (not (has $authMethod (list "accessKey" "workloadIdentity"))) -}}
    {{- fail "global.bucket.azureAuthMethod must be accessKey or workloadIdentity" -}}
  {{- end -}}
  {{- $enabled := false -}}
  {{- if and $hasCustomerBucket (eq $authMethod "workloadIdentity") -}}
    {{- if not $globalConfigured -}}
      {{- fail "global.azureStorageIdentity.tenantId and clientId are required when global.bucket.azureAuthMethod is workloadIdentity" -}}
    {{- end -}}
    {{- $tenantId = $globalTenantId -}}
    {{- $clientId = $globalClientId -}}
    {{- $enabled = true -}}
  {{- else if and $hasCustomerBucket (eq $authMethod "accessKey") -}}
    {{- $enabled = false -}}
  {{- else if and $hasCustomerBucket (eq $bucket.provider "az") $bucketIdentityConfigured -}}
    {{- /* Backward compatibility for existing bucket-scoped identity values. */ -}}
    {{- $enabled = true -}}
  {{- else if and (not $hasCustomerBucket) (eq $bucket.provider "az") $globalConfigured -}}
    {{- $tenantId = $globalTenantId -}}
    {{- $clientId = $globalClientId -}}
    {{- $enabled = true -}}
  {{- else if and (not $hasCustomerBucket) (eq $bucket.provider "az") $bucketIdentityConfigured -}}
    {{- $enabled = true -}}
  {{- end -}}
{{- dict "enabled" $enabled "tenantId" $tenantId "clientId" $clientId | toYaml -}}
{{- end }}

{{/*
Return whether Azure workload identity token injection is needed anywhere in
the deployment. Bucket authentication can still use a storage key.
*/}}
{{- define "wandb.azureStorageIdentityEnabled" -}}
  {{- $identity := include "wandb.azureStorageIdentity" . | fromYaml -}}
  {{- $globalIdentity := default (dict) .Values.global.azureStorageIdentity -}}
  {{- $globalConfigured := and (not (empty $globalIdentity.tenantId)) (not (empty $globalIdentity.clientId)) -}}
{{- or $globalConfigured $identity.enabled -}}
{{- end }}

{{/*
Return the URI used when Weave explicitly opts into the deployment bucket.
Weave accepts az://<account>/<container>; a W&B bucket path with a prefix
cannot be represented without changing Weave's object layout.
*/}}
{{- define "wandb.weaveTraceFileStorageURI" -}}
  {{- $weaveTrace := index .Values.global "weave-trace" | default dict -}}
  {{- $fileStorage := index $weaveTrace "fileStorage" | default dict -}}
  {{- if (index $fileStorage "useDefaultBucket" | default false) -}}
    {{- $bucket := .Values.global.defaultBucket -}}
    {{- $globalIdentity := default (dict) .Values.global.azureStorageIdentity -}}
    {{- $identityConfigured := and (not (empty $globalIdentity.tenantId)) (not (empty $globalIdentity.clientId)) -}}
    {{- if ne $bucket.provider "az" -}}
      {{- fail "global.weave-trace.fileStorage.useDefaultBucket currently requires an Azure bucket" -}}
    {{- end -}}
    {{- if not $identityConfigured -}}
      {{- fail "global.weave-trace.fileStorage.useDefaultBucket requires global.azureStorageIdentity" -}}
    {{- end -}}
    {{- $pathParts := splitList "/" (trimAll "/" $bucket.path) -}}
    {{- if or (empty $bucket.path) (ne (len $pathParts) 1) -}}
      {{- fail "global.weave-trace.fileStorage.useDefaultBucket requires global.defaultBucket.path to contain exactly one Azure container name and no object prefix" -}}
    {{- end -}}
    {{- printf "az://%s/%s" $bucket.name (first $pathParts) -}}
  {{- end -}}
{{- end }}

{{- define "wandb.weaveTraceUsesAzureWorkloadIdentity" -}}
  {{- $weaveTrace := index .Values.global "weave-trace" | default dict -}}
  {{- $fileStorage := index $weaveTrace "fileStorage" | default dict -}}
  {{- $globalIdentity := default (dict) .Values.global.azureStorageIdentity -}}
  {{- $identityConfigured := and (not (empty $globalIdentity.tenantId)) (not (empty $globalIdentity.clientId)) -}}
{{- and (index $fileStorage "useDefaultBucket" | default false) $identityConfigured -}}
{{- end }}


{{- define "wandb.bucket" -}}
  {{- $url := "" -}}
  {{- $path := "" -}}
  {{- $provider := "" -}}
  {{- $accessKey := "" -}}
  {{- $secretKey := "" -}}
  {{- $azureTenantId := "" -}}
  {{- $azureClientId := "" -}}
  {{- if .Values.global.bucket.name -}}
    {{- $provider = .Values.global.bucket.provider -}}
    {{- $path = .Values.global.bucket.path -}}
    {{- $accessKey = default "" .Values.global.bucket.accessKey -}}
    {{- $secretKey = default "" .Values.global.bucket.secretKey -}}
    {{- $azureTenantId = default "" .Values.global.bucket.azureTenantId -}}
    {{- $azureClientId = default "" .Values.global.bucket.azureClientId -}}
name: {{ .Values.global.bucket.name }}
region: {{ .Values.global.bucket.region }}
kmsKey: {{ .Values.global.bucket.kmsKey }}
  {{- else -}}
    {{- $provider = .Values.global.defaultBucket.provider -}}
    {{- $path = .Values.global.defaultBucket.path -}}
    {{- $accessKey = default "" .Values.global.defaultBucket.accessKey -}}
    {{- $secretKey = default "" .Values.global.defaultBucket.secretKey -}}
    {{- $azureTenantId = default "" .Values.global.defaultBucket.azureTenantId -}}
    {{- $azureClientId = default "" .Values.global.defaultBucket.azureClientId -}}
name: {{ .Values.global.defaultBucket.name }}
region: {{ .Values.global.defaultBucket.region }}
kmsKey: {{ .Values.global.defaultBucket.kmsKey }}
  {{- end }}
provider: {{ $provider }}
path: {{ $path }}
accessKey: {{ $accessKey }}
secretKey: {{ $secretKey }}
azureTenantId: {{ $azureTenantId | toJson }}
azureClientId: {{ $azureClientId | toJson }}
accessKeyName: {{ .Values.global.bucket.secret.accessKeyName }}
secretKeyName: {{ .Values.global.bucket.secret.secretKeyName }}
secretName: {{ include "wandb.bucket.secret" . }}
  {{- if not $path -}}

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
