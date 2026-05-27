
{{- define "operator-wandb.lumen.audience" -}}
{{- $cloud := .Values.global.cloudProvider | default "" | lower -}}
{{- if eq $cloud "aws" -}}
  //iam.googleapis.com/projects/281760294016/locations/global/workloadIdentityPools/default-pool/providers/default-provider
{{- else if eq $cloud "azure" -}}
  //iam.googleapis.com/projects/281760294016/locations/global/workloadIdentityPools/aks-default-pool/providers/aks-default-provider
{{- else if eq $cloud "gcp" -}}
  lumen-gcp-adc-unused
{{- else -}}
  {{- fail (printf "lumen: unknown global.cloudProvider=%q (expected aws|azure|gcp)" $cloud) -}}
{{- end -}}
{{- end -}}

{{- define "operator-wandb.lumen.googleCredsPath" -}}
{{- $cloud := .Values.global.cloudProvider | default "" | lower -}}
{{- if eq $cloud "gcp" -}}
{{/* empty: rely on ADC */}}
{{- else -}}
/var/secrets/gcp/credential-config.json
{{- end -}}
{{- end -}}

{{- define "wandb.lumen.stagingPath" -}}
/vol/staging
{{- end -}}

{{- define "wandb.lumen.rulePath" -}}
/app/definitions/collector/managed-install.yaml
{{- end -}}
