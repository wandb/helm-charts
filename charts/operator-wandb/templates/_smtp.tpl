{{- define "wandb.smtp.secretName" -}}
  {{- printf "%s-smtp-secret" .Release.Name -}}
{{- end -}}

{{/* Resolve inline values or existing Secret/ConfigMap keys into the SMTP Secret.
Required references must already exist in the release namespace at render time.
*/}}
{{- define "wandb.smtp.resolveValue" -}}
  {{- $value := .value -}}
  {{- if not (kindIs "map" $value) -}}
    {{- $value | default "" | toString -}}
  {{- else if hasKey $value "value" -}}
    {{- $value.value | toString -}}
  {{- else -}}
    {{- $source := $value.valueFrom | default dict -}}
    {{- $kind := "ConfigMap" -}}
    {{- $ref := $source.configMapKeyRef | default dict -}}
    {{- if $source.secretKeyRef -}}
      {{- $kind = "Secret" -}}
      {{- $ref = $source.secretKeyRef -}}
    {{- end -}}
    {{- if not (and $ref.name $ref.key) -}}
      {{- fail (printf "SMTP %s must be an inline value, secretKeyRef, or configMapKeyRef" .field) -}}
    {{- end -}}
    {{- $resource := lookup "v1" $kind .root.Release.Namespace $ref.name | default dict -}}
    {{- $data := $resource.data | default dict -}}
    {{- if hasKey $data $ref.key -}}
      {{- if eq $kind "Secret" -}}
        {{- get $data $ref.key | b64dec -}}
      {{- else -}}
        {{- get $data $ref.key -}}
      {{- end -}}
    {{- else if not $ref.optional -}}
      {{- fail (printf "SMTP %s references missing %s %s key %s in namespace %s" .field $kind $ref.name $ref.key .root.Release.Namespace) -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
