
{{- define "wandb.lumen.audience" -}}
{{- dig "lumen" "gcpWorkloadIdentity" "audience" "" .Values.global -}}
{{- end -}}

{{- define "wandb.lumen.googleCredsPath" -}}
{{- if dig "lumen" "gcpWorkloadIdentity" "audience" "" .Values.global -}}
/var/secrets/gcp/credential-config.json
{{- end -}}
{{- end -}}

{{- define "wandb.lumen.dataRoot" -}}
{{- dig "lumen" "dataRoot" "" .Values.global -}}
{{- end -}}

{{- define "wandb.lumen.stagingPath" -}}
/vol/staging
{{- end -}}

{{- define "wandb.lumen.rulePath" -}}
/app/definitions/collector/managed-install.yaml
{{- end -}}

{{- define "wandb.lumen.publish.envVars" -}}
{{- if eq (dig "lumen" "publish" "envVars" false .Values.global | toString) "true" -}}
true
{{- end -}}
{{- end -}}

{{- define "wandb.lumen.customer" -}}
{{- dig "lumen" "customer" "" .Values.global -}}
{{- end -}}

{{- define "wandb.lumen.installed" -}}
{{- $agent := eq (dig "install" false (index .Values "lumen-agent" | default dict) | toString) "true" -}}
{{- $processor := eq (dig "install" false (index .Values "lumen-processor" | default dict) | toString) "true" -}}
{{- $notebook := eq (dig "install" false (index .Values "lumen-notebook" | default dict) | toString) "true" -}}
{{- if or $agent $processor $notebook -}}
true
{{- end -}}
{{- end -}}
