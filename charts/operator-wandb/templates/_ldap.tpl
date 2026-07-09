{{- define "wandb.ldapConnectionString" -}}
{{- $ldap := .Values.global.auth.ldap -}}
{{- if $ldap.enabled -}}
{{- $scheme := ternary "ldaps" "ldap" $ldap.tls -}}
{{- $tls := ternary "true" "false" $ldap.tls -}}
{{- $queryParams := printf "attributes=%s&userBaseDN=%s&groupBaseDN=%s&userObjectClass=%s&groupObjectClass=%s&groupAllowList=%s&tls=%s" $ldap.attributes $ldap.userBaseDN $ldap.groupBaseDN $ldap.userObjectClass $ldap.groupObjectClass $ldap.groupAllowList $tls -}}
{{- $hostPort := $ldap.host -}}
{{- if $ldap.port -}}
{{- $hostPort = printf "%s:%v" $ldap.host $ldap.port -}}
{{- end -}}
{{- if and $ldap.bindDN $ldap.bindPW -}}
{{ $scheme }}://{{ $ldap.bindDN }}:$(LDAP_BIND_PW)@{{ $hostPort }}/{{ $ldap.baseDN }}?{{ $queryParams }}
{{- else -}}
{{ $scheme }}://{{ $hostPort }}/{{ $ldap.baseDN }}?{{ $queryParams }}
{{- end -}}
{{- end -}}
{{- end -}}
