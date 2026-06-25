
{{- define "operator-wandb.lumen.audience" -}}
{{- dig "lumen" "gcpWorkloadIdentity" "audience" "" .Values.global -}}
{{- end -}}

{{- define "operator-wandb.lumen.googleCredsPath" -}}
{{- if dig "lumen" "gcpWorkloadIdentity" "audience" "" .Values.global -}}
/var/secrets/gcp/credential-config.json
{{- end -}}
{{- end -}}

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
