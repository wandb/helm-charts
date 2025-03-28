{{- define "wandb.bufstream.bucket.name" -}}
{{- $bucketName := (include "wandb.bucket" . | fromYaml).name -}}
{{- if contains "/" $bucketName -}}
  {{- $bucketName = regexSplit "/" $bucketName 2 | last -}}
{{- end -}}
{{ $bucketName }}
{{- end -}}

{{- define "wandb.bufstream.bucket.endpoint" -}}
{{- $endpoint := "" -}}
{{- $queryParams := "" -}}
{{- $bucketName := (include "wandb.bucket" . | fromYaml).name -}}
{{- $bucketPath := (include "wandb.bucket" . | fromYaml).path -}}
{{- if contains "/" $bucketName -}}
  {{- $endpoint = regexSplit "/" $bucketName 2 | first -}}
{{- end -}}
{{- if contains "?" $bucketPath -}}
  {{- $queryParams = printf "?%s" (regexSplit "?" $bucketPath 2 | last) -}}
{{- end -}}
http://{{ $endpoint }}{{ $queryParams }}
{{- end -}}

{{- define "wandb.bufstream.bucket.prefix" -}}
{{- $bucketPath := (include "wandb.bucket" . | fromYaml).path -}}
{{- if contains "?" $bucketPath -}}
  {{- $bucketPath = regexSplit "?" $bucketPath 2 | first -}}
{{- end -}}
{{ $bucketPath }}
{{- end -}}