{{/*
  GCP WIF audience for the lumen agent + processor. The cloud-specific
  audience URL is provided by terraform per-environment (see the
  aws-gcp-audience / azure-gcp-audience terraform variables) and lands in
  global.lumen.gcpWorkloadIdentity.audience via the WeightsAndBiases CR.

  Empty value means no WIF (e.g. GCP-direct deployments that use ADC) —
  callers should treat empty as "skip WIF resources / use ADC fallback".

  Usage:  {{ include "operator-wandb.lumen.audience" . }}
*/}}
{{- define "operator-wandb.lumen.audience" -}}
{{- dig "lumen" "gcpWorkloadIdentity" "audience" "" .Values.global -}}
{{- end -}}

{{/*
  Path passed to GOOGLE_APPLICATION_CREDENTIALS. Empty when there's no WIF
  audience (the GCP/ADC path) — the Go GCP SDK treats empty/unset identically
  and falls back to ADC via the metadata server.

  Usage:  {{ include "operator-wandb.lumen.googleCredsPath" . }}
*/}}
{{- define "operator-wandb.lumen.googleCredsPath" -}}
{{- if dig "lumen" "gcpWorkloadIdentity" "audience" "" .Values.global -}}
/var/secrets/gcp/credential-config.json
{{- end -}}
{{- end -}}

{{/*
  Data root URL for the lumen agent + processor (LUMEN_DATA_ROOT). When
  global.lumen.dataRoot is set, use it verbatim. Otherwise fall back to the
  wandb operator's standard bucket (global.bucket / global.defaultBucket via
  the wandb.bucket helper) so on-prem installs that don't supply a separate
  lumen bucket still get a working path. The scheme is derived from the
  bucket's provider.

  Usage:  {{ include "wandb.lumen.dataRoot" . }}
*/}}
{{- define "wandb.lumen.dataRoot" -}}
{{- $explicit := dig "lumen" "dataRoot" "" .Values.global -}}
{{- if $explicit -}}
{{- $explicit -}}
{{- else -}}
{{- $b := (include "wandb.bucket" . | fromYaml) -}}
{{- $schemes := dict "s3" "s3" "gcs" "gs" "az" "azure" "cw" "s3" "local" "file" -}}
{{- $scheme := index $schemes ($b.provider | default "") -}}
{{- if not $scheme }}{{ fail (printf "wandb.lumen.dataRoot: unknown bucket provider %q" $b.provider) }}{{ end -}}
{{- $path := $b.path | default "" | trimSuffix "/" -}}
{{- printf "%s://%s%s/lumen" $scheme $b.name $path -}}
{{- end -}}
{{- end -}}

{{- define "wandb.lumen.stagingPath" -}}
/vol/staging
{{- end -}}

{{- define "wandb.lumen.rulePath" -}}
/app/definitions/collector/managed-install.yaml
{{- end -}}
