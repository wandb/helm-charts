
{{/*
Return the db port
*/}}
{{- define "wandb.mysql.port" -}}
{{- if $.Values.mysql.install -}}
{{- print $.Values.mysql.port -}}
{{- else -}}
{{- print $.Values.global.mysql.port -}}
{{- end -}}
{{- end -}}

{{/*
Return the db host
*/}}
{{- define "wandb.mysql.host" -}}
{{- if $.Values.mysql.install -}}
{{- print $.Values.mysql.host -}}
{{- else -}}
{{- print $.Values.global.mysql.host -}}
{{- end -}}
{{- end -}}

{{/*
Return the db database
*/}}
{{- define "wandb.mysql.database" -}}
{{- if $.Values.mysql.install -}}
{{- print $.Values.mysql.auth.database -}}
{{- else -}}
{{- print $.Values.global.mysql.auth.database -}}
{{- end -}}
{{- end -}}

{{/*
Return the db user
*/}}
{{- define "wandb.mysql.user" -}}
{{- if $.Values.mysql.install -}}
{{- print $.Values.mysql.auth.user -}}
{{- else -}}
{{- print $.Values.global.mysql.auth.user -}}
{{- end -}}
{{- end -}}

{{/*
Return the db password secret name

TODO figure out why $name := include "wandb.fullname" $ doesn't work
*/}}
{{- define "wandb.mysql.password.secret" -}}
{{- if or ($.Values.mysql.install) (eq $.Values.global.mysql.auth.existingSecret "") -}}
{{- print "wandb-mysql" -}}
{{- else -}}
{{- print $.Values.global.mysql.auth.existingSecret -}}
{{- end -}}
{{- end -}}


