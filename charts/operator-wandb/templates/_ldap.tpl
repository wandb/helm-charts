{{- define "wandb.ldapConnectionString" -}}
{{- $ldap := .Values.global.auth.ldap -}}
{{- if and $ldap.enabled $ldap.tls -}}
ldaps://{{ $ldap.bindDN }}:{{ $ldap.bindPW }}@{{ $ldap.host }}:{{ $ldap.port }}/{{ $ldap.baseDN }}?{{ $ldap.attributes }}
{{- else if $ldap.enabled -}}
ldap://{{ $ldap.bindDN }}:{{ $ldap.bindPW }}@{{ $ldap.host }}:{{ $ldap.port }}/{{ $ldap.baseDN }}?{{ $ldap.attributes }}
{{- end -}}
{{- end -}}
