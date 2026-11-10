{{/*
  Assorted bucket related helpers.
*/}}
{{/*
Resolve the bucket once for all consumers. A valid Console snapshot takes
precedence over a customer bucket in values, which takes precedence over the
default bucket. All consumers must use this configuration.
*/}}
{{- define "wandb.bucket.effective" -}}
  {{- $globalBucket := default (dict) .Values.global.bucket -}}
  {{- $consoleSettings := dict -}}
  {{- $secret := lookup "v1" "Secret" .Release.Namespace (printf "%s-bucket" .Release.Name) | default dict -}}
  {{- $metadata := default (dict) $secret.metadata -}}
  {{- $annotations := default (dict) $metadata.annotations -}}
  {{- $isConsoleManaged := eq (get $annotations "wandb.ai/console-managed") "true" -}}
  {{- if $isConsoleManaged -}}
    {{- $settings := fromJson (get $annotations "wandb.ai/bucket-settings" | default "") -}}
    {{- $hasValidSettings := and (kindIs "map" $settings) (not (hasKey $settings "Error")) (not (empty (get $settings "provider"))) (not (empty (get $settings "name"))) -}}
    {{- if $hasValidSettings -}}
      {{- $consoleSettings = $settings -}}
    {{- end -}}
  {{- end -}}

  {{- $bucket := default (dict) .Values.global.defaultBucket -}}
  {{- $customerBucket := false -}}
  {{- if not (empty $consoleSettings) -}}
    {{- $bucket = $consoleSettings -}}
    {{- $customerBucket = true -}}
  {{- else if not (empty $globalBucket.name) -}}
    {{- $bucket = $globalBucket -}}
    {{- $customerBucket = true -}}
  {{- end -}}

  {{- $secretRef := default (dict) $globalBucket.secret -}}
  {{- if not (empty $consoleSettings) -}}
    {{- $secretRef = dict "secretName" "" "accessKeyName" "ACCESS_KEY" "secretKeyName" "SECRET_KEY" -}}
  {{- else -}}
    {{- $hasInlineCredentials := and $bucket.accessKey $bucket.secretKey -}}
    {{- if eq $bucket.provider "az" -}}
      {{- $hasInlineCredentials = $bucket.accessKey -}}
    {{- end -}}
    {{- if and $secretRef.secretName $hasInlineCredentials -}}
      {{- $secretRef = dict "secretName" "" "accessKeyName" "ACCESS_KEY" "secretKeyName" "SECRET_KEY" -}}
    {{- end -}}
  {{- end -}}

  {{- $effectiveSecret := dict
  "secretName" (default "" $secretRef.secretName)
  "accessKeyName" (default "" $secretRef.accessKeyName)
  "secretKeyName" (default "" $secretRef.secretKeyName)
  -}}
  {{- $accessKey := default "" $bucket.accessKey -}}
  {{- $secretKey := default "" $bucket.secretKey -}}
  {{- if not (empty $consoleSettings) -}}
    {{- $accessKey = "" -}}
    {{- $secretKey = "" -}}
  {{- end -}}
  {{- $effectiveBucket := dict
  "provider" (default "" $bucket.provider)
  "name" (default "" $bucket.name)
  "path" (default "" $bucket.path)
  "region" (default "" $bucket.region)
  "kmsKey" (default "" $bucket.kmsKey)
  "accessKey" $accessKey
  "secretKey" $secretKey
  "azureTenantId" (default "" $bucket.azureTenantId)
  "azureClientId" (default "" $bucket.azureClientId)
  "azureAuthMethod" (default "" $bucket.azureAuthMethod)
  "customerBucket" $customerBucket
  "secret" $effectiveSecret
  -}}
{{- $effectiveBucket | toYaml -}}
{{- end }}

{{/*
Return the bucket credential Secret reference. Inline keys on the effective
bucket win over global.bucket.secret: a managed spec derives that reference
from Terraform's bucket, while a user spec can select another bucket with its
own key. The chart then owns the Secret with its default key names. Azure
needs only accessKey; other providers need the full key pair.
*/}}
{{- define "wandb.bucket.secretRef" -}}
  {{- $bucket := include "wandb.bucket.effective" . | fromYaml -}}
{{- $bucket.secret | toYaml -}}
{{- end }}

{{- define "wandb.bucket.secret" -}}
  {{- $secretRef := include "wandb.bucket.secretRef" . | fromYaml -}}
  {{- if $secretRef.secretName -}}
  {{ $secretRef.secretName }}
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
  {{- $hasCustomerBucket := $bucket.customerBucket -}}
  {{- $globalIdentity := default (dict) .Values.global.azureStorageIdentity -}}
  {{- $globalTenantId := default "" $globalIdentity.tenantId -}}
  {{- $globalClientId := default "" $globalIdentity.clientId -}}
  {{- $tenantId := default "" $bucket.azureTenantId -}}
  {{- $clientId := default "" $bucket.azureClientId -}}
  {{- $globalConfigured := and (not (empty $globalTenantId)) (not (empty $globalClientId)) -}}
  {{- $bucketIdentityConfigured := and (not (empty $tenantId)) (not (empty $clientId)) -}}
  {{- $authMethod := default "" $bucket.azureAuthMethod -}}
  {{- $bucketConfigPath := "global.defaultBucket" -}}
  {{- if $hasCustomerBucket -}}
    {{- $bucketConfigPath = "global.bucket" -}}
  {{- end -}}
  {{- if ne (empty $globalTenantId) (empty $globalClientId) -}}
    {{- fail "global.azureStorageIdentity.tenantId and clientId must be provided together" -}}
  {{- end -}}
  {{- if and (eq $bucket.provider "az") (ne (empty $tenantId) (empty $clientId)) -}}
    {{- fail "Azure bucket azureTenantId and azureClientId must be provided together" -}}
  {{- end -}}
  {{- if and (not (empty $authMethod)) (not (has $authMethod (list "accessKey" "workloadIdentity"))) -}}
    {{- fail (printf "%s.azureAuthMethod must be accessKey or workloadIdentity" $bucketConfigPath) -}}
  {{- end -}}
  {{- $enabled := false -}}
  {{- if and (eq $bucket.provider "az") (eq $authMethod "workloadIdentity") -}}
    {{- if not $globalConfigured -}}
      {{- fail (printf "global.azureStorageIdentity.tenantId and clientId are required when %s.azureAuthMethod is workloadIdentity" $bucketConfigPath) -}}
    {{- end -}}
    {{- $tenantId = $globalTenantId -}}
    {{- $clientId = $globalClientId -}}
    {{- $enabled = true -}}
  {{- else if eq $authMethod "accessKey" -}}
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
Return whether workloads can use the deployment-wide Azure storage account.
Legacy bucket-scoped identities deliberately retain their component accounts.
*/}}
{{- define "wandb.azureStorageServiceAccountEnabled" -}}
  {{- $identity := include "wandb.azureStorageIdentity" . | fromYaml -}}
  {{- $globalIdentity := default (dict) .Values.global.azureStorageIdentity -}}
  {{- $serviceAccount := default (dict) $globalIdentity.serviceAccount -}}
  {{- $mode := default "shared" $serviceAccount.mode -}}
  {{- if not (has $mode (list "shared" "component" "grouped")) -}}
    {{- fail "global.azureStorageIdentity.serviceAccount.mode must be shared, component, or grouped" -}}
  {{- end -}}
  {{- $globalConfigured := and (not (empty $globalIdentity.tenantId)) (not (empty $globalIdentity.clientId)) -}}
  {{- $weaveUsesDefaultBucket := include "wandb.weaveTraceUsesAzureWorkloadIdentity" . | trim | eq "true" -}}
{{- and $globalConfigured (or $identity.enabled $weaveUsesDefaultBucket) (ne $mode "component") -}}
{{- end }}

{{- define "wandb.azureStorageServiceAccountName" -}}
  {{- $identity := default (dict) .Values.global.azureStorageIdentity -}}
  {{- $serviceAccount := default (dict) $identity.serviceAccount -}}
{{- default "wandb-bucket-access" $serviceAccount.name -}}
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

{{/*
Name of the shared Weave Trace ServiceAccount, owned at the umbrella level by
templates/weave-trace-serviceaccount.yaml. Must stay identical to
"wandb-base.weaveTraceServiceAccountName" in charts/wandb-base/templates/_helpers.tpl.
*/}}
{{- define "wandb.weaveTraceServiceAccountName" -}}
  {{- printf "%s-weave-trace" .Release.Name -}}
{{- end }}


{{- define "wandb.bucket" -}}
  {{- $bucket := include "wandb.bucket.effective" . | fromYaml -}}
  {{- $secretRef := $bucket.secret -}}
  {{- $url := "" -}}
  {{- $path := $bucket.path -}}
  {{- $provider := $bucket.provider -}}
  {{- $accessKey := $bucket.accessKey -}}
  {{- $secretKey := $bucket.secretKey -}}
name: {{ $bucket.name }}
region: {{ $bucket.region }}
kmsKey: {{ $bucket.kmsKey }}
provider: {{ $bucket.provider }}
path: {{ $bucket.path }}
accessKey: {{ $bucket.accessKey }}
secretKey: {{ $bucket.secretKey }}
azureTenantId: {{ $bucket.azureTenantId | toJson }}
azureClientId: {{ $bucket.azureClientId | toJson }}
azureAuthMethod: {{ $bucket.azureAuthMethod | toJson }}
accessKeyName: {{ $secretRef.accessKeyName }}
secretKeyName: {{ $secretRef.secretKeyName }}
secretName: {{ include "wandb.bucket.secret" . }}
customerBucket: {{ $bucket.customerBucket }}
  {{- if not $path -}}

    {{- if eq $provider "cw" -}}
      {{- if or (and $accessKey $secretKey) $secretRef.secretName -}}
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
      {{- if or (and $accessKey $secretKey) $secretRef.secretName -}}
        {{- $url = "s3://$(BUCKET_ACCESS_KEY):$(BUCKET_SECRET_KEY)@$(BUCKET_NAME)" -}}
      {{- else -}}
        {{- $url = "s3://$(BUCKET_NAME)" -}}
      {{- end -}}
    {{- end -}}

  {{- else -}}

    {{- if eq $provider "cw" -}}
      {{- if or (and $accessKey $secretKey) $secretRef.secretName -}}
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
      {{- if or (and $accessKey $secretKey) $secretRef.secretName -}}
        {{- $url = "s3://$(BUCKET_ACCESS_KEY):$(BUCKET_SECRET_KEY)@$(BUCKET_NAME)/$(BUCKET_PATH)" -}}
      {{- else -}}
        {{- $url = "s3://$(BUCKET_NAME)/$(BUCKET_PATH)" -}}
      {{- end -}}
    {{- end -}}

  {{- end -}}
  {{- $url = trimSuffix "/" $url }}
url: {{ $url }}
{{- end -}}


{{/* Percent-encode URL userinfo; urlquery's "+" for spaces decodes as a literal plus in userinfo. */}}
{{- define "wandb.bucket.userinfoEscape" -}}
  {{- . | toString | urlquery | replace "+" "%20" -}}
{{- end -}}

{{/* Build the chart-owned Secret's URL from the effective bucket. External
Secrets retain their existing runtime interpolation and are never copied here.
*/}}
{{- define "wandb.bucket.connectionString" -}}
  {{- $bucket := include "wandb.bucket.effective" . | fromYaml -}}
  {{- $scheme := $bucket.provider -}}
  {{- if eq $scheme "gcs" -}}
    {{- $scheme = "gs" -}}
  {{- end -}}
  {{- if has $bucket.provider (list "s3" "cw" "az" "gcs") -}}
    {{- $credentials := "" -}}
    {{- $usesKeyPair := and (has $scheme (list "s3" "cw")) $bucket.accessKey $bucket.secretKey -}}
    {{- if $usesKeyPair -}}
      {{- $credentials = printf "%s:%s@" (include "wandb.bucket.userinfoEscape" $bucket.accessKey) (include "wandb.bucket.userinfoEscape" $bucket.secretKey) -}}
    {{- end -}}
    {{- $path := "" -}}
    {{- if $bucket.path -}}
      {{- $path = printf "/%s" $bucket.path -}}
    {{- end -}}
    {{- printf "%s://%s%s%s" $scheme $credentials ($bucket.name | default "" | toString) $path -}}
  {{- end -}}
{{- end -}}

{{/* Chart-owned connection strings are already named for their application consumers. */}}
{{- define "wandb.bucket.envFrom" -}}
  {{- if not (include "wandb.bucket.secretRef" . | fromYaml).secretName }}
- secretRef:
    name: {{ include "wandb.bucket.secret" . | quote }}
  {{- end }}
{{- end -}}

{{/* External credentials retain the original runtime interpolation. */}}
{{- define "wandb.bucket.externalConnectionEnv" -}}
  {{- if (include "wandb.bucket.secretRef" .root | fromYaml).secretName }}
- name: {{ .name }}
  value: {{ (include "wandb.bucket" .root | fromYaml).url | quote }}
  {{- end }}
{{- end -}}

{{/* Only chart-owned bucket resources participate in Console ownership. Preserve
all saved data, including intentional removals, rather than merging stale values.
External Secrets and their existing interpolation path remain spec-controlled.
*/}}
{{- define "wandb.bucket.consoleOwnedResource" -}}
  {{- if not (include "wandb.bucket.secretRef" .root | fromYaml).secretName -}}
    {{- $existing := lookup "v1" .kind .root.Release.Namespace .name | default dict -}}
    {{- $metadata := $existing.metadata | default dict -}}
    {{- $annotations := $metadata.annotations | default dict -}}
    {{- if eq (get $annotations "wandb.ai/console-managed") "true" -}}
      {{- dict "data" ($existing.data | default dict) "annotations" (mergeOverwrite (deepCopy $annotations) (dict "helm.sh/resource-policy" "keep")) | toYaml -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/* Before ownership, spec edits still roll workloads. After ownership, hash the
saved URL so stale spec values cannot drive the bucket rollout checksum.
*/}}
{{- define "wandb.bucket.podAnnotations" -}}
  {{- if not (include "wandb.bucket.secretRef" . | fromYaml).secretName -}}
    {{- $owned := include "wandb.bucket.consoleOwnedResource" (dict "root" . "kind" "Secret" "name" (include "wandb.bucket.secret" .)) | fromYaml -}}
    {{- $connectionString := "" -}}
    {{- if $owned -}}
      {{- $connectionString = get $owned.data "BUCKET" | default "" | b64dec -}}
    {{- else -}}
      {{- $connectionString = include "wandb.bucket.connectionString" . -}}
    {{- end }}
checksum/bucket: {{ $connectionString | sha256sum | quote }}
  {{- end -}}
{{- end -}}
