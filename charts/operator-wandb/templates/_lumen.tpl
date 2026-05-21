{{/*
  Resolve the GCP Workload Identity Federation audience for the lumen agent /
  processor. Picks the wandb-managed WIF pool based on global.cloudProvider.
  - aws   → EKS-trusting wandb WIF pool
  - azure → AKS-trusting wandb WIF pool
  - gcp   → empty (no WIF; pods use ADC or a key secret instead)
  - other → fail with a clear message

*/}}
{{- define "operator-wandb.lumen.audience" -}}
{{- $cloud := .Values.global.cloudProvider | default "" | lower -}}
{{- if eq $cloud "aws" -}}
  //iam.googleapis.com/projects/281760294016/locations/global/workloadIdentityPools/default-pool/providers/default-provider
{{- else if eq $cloud "azure" -}}
  //iam.googleapis.com/projects/281760294016/locations/global/workloadIdentityPools/aks-default-pool/providers/aks-default-provider
{{- else if eq $cloud "gcp" -}}
{{/* intentionally empty: GCP uses ADC / key file, not WIF */}}
{{- else -}}
  {{- fail (printf "lumen: unknown global.cloudProvider=%q (expected aws|azure|gcp)" $cloud) -}}
{{- end -}}
{{- end -}}
