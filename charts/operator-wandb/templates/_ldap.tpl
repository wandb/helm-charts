{{- define "wandb.ldapConnectionString" -}}
{{- $ldap := .Values.global.auth.ldap -}}
{{- if and $ldap.enabled -}}
ldap://{{ $ldap.host }}:{{$ldap.port}}/{{ $ldap.baseDN }}?{{ $ldap.attributes }}
{{- else -}}
ldap://ldap.example.com:389
{{- end -}}
{{- end -}}
