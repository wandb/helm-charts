{{- define "wandb.ldapConnectionString" -}}
{{- $ldap := .Values.global.auth.ldap -}}
{{- if $ldap.enabled -}}
{{- $scheme := ternary "ldaps" "ldap" $ldap.tls -}}
{{- $tls := ternary "true" "false" $ldap.tls -}}
{{- $queryParams := printf "attributes=%s&userBaseDN=%s&groupBaseDN=%s&userObjectClass=%s&groupObjectClass=%s&groupAllowList=%s&tls=%s" $ldap.attributes $ldap.userBaseDN $ldap.groupBaseDN $ldap.userObjectClass $ldap.groupObjectClass $ldap.groupAllowList $tls -}}
{{- if $ldap.bindDN -}}
{{ $scheme }}://{{ $ldap.bindDN }}:$(LDAP_BIND_PW)@{{ $ldap.host }}:{{ $ldap.port }}/{{ $ldap.baseDN }}?{{ $queryParams }}
{{- else -}}
{{ $scheme }}://{{ $ldap.host }}:{{ $ldap.port }}/{{ $ldap.baseDN }}?{{ $queryParams }}
{{- end -}}
{{- end -}}
{{- end -}}
