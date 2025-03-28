{{- define "wandb.bufstream.bucket.name" -}}
{{- $bucketName := (include "wandb.bucket" . | fromYaml).name -}}
{{- if contains "/" $bucketName -}}
  {{- $bucketName = regexSplit "/" $bucketName 2 | last -}}
{{- end -}}
{{ $bucketName }}
{{- end -}}

{{- define "wandb.bufstream.bucket.endpoint" -}}
{{- $endpoint := "" -}}
{{- $bucketName := (include "wandb.bucket" . | fromYaml).name -}}
{{- if contains "/" $bucketName -}}
  {{- $endpoint = regexSplit "/" $bucketName 2 | first -}}
{{- end -}}
http://{{ $endpoint }}
{{- end -}}