
{{/*
Return the db port
*/}}
{{- define "wandb.mysql.port" -}}
{{- print $.Values.global.mysql.port -}}
{{- end -}}

{{/*
Return the db host
*/}}
{{- define "wandb.mysql.host" -}}
{{- print $.Values.global.mysql.host -}}
{{- end -}}

{{/*
Return the db database
*/}}
{{- define "wandb.mysql.database" -}}
{{- print $.Values.global.mysql.auth.database -}}
{{- end -}}

{{/*
Return the db user
*/}}
{{- define "wandb.mysql.user" -}}
{{- print $.Values.global.mysql.auth.user -}}
{{- end -}}

{{/*
Return the db password secret name

TODO figure out why $name := include "wandb.fullname" $ doesnt work
*/}}
{{- define "wandb.mysql.password.secret" -}}
{{- if (eq $.Values.global.mysql.auth.existingSecret "") -}}
{{- printf "%s-%s" .Release.Name "mysql-passwords" -}}
{{- else -}}
{{- print $.Values.global.mysql.auth.existingSecret -}}
{{- end -}}
{{- end -}}


