{{/*
  Explicit opt-in only. More specific profiles override global settings, including
  false and empty lists. Deep copies keep one container/job from changing another.
*/}}
{{- define "wandb-base.securityProfile" -}}
  {{- $podData := default dict .podData -}}
  {{- $container := default dict .container -}}
  {{- $profile := deepCopy (default dict .root.Values.global.workloadSecurityProfile) -}}
  {{- $profile = mergeOverwrite $profile (deepCopy (default dict .root.Values.workloadSecurityProfile)) -}}
  {{- $profile = mergeOverwrite $profile (deepCopy (default dict $podData.workloadSecurityProfile)) -}}
  {{- $profile = mergeOverwrite $profile (deepCopy (default dict $container.workloadSecurityProfile)) -}}
  {{- if hasKey $profile "enabled" -}}
    {{- if not (kindIs "bool" $profile.enabled) -}}
      {{- fail "workloadSecurityProfile.enabled must be a boolean" -}}
    {{- end -}}
  {{- end -}}
  {{- if $profile.enabled -}}
    {{- $defaults := dict "automountServiceAccountToken" false "allowPrivilegeEscalation" false "privileged" false "capabilities" (dict "drop" (list "ALL") "add" list) "seccompProfile" (dict "type" "RuntimeDefault") -}}
    {{- $profile = mergeOverwrite $defaults $profile -}}
    {{- range $field := list "automountServiceAccountToken" "allowPrivilegeEscalation" "privileged" "runAsNonRoot" "readOnlyRootFilesystem" -}}
      {{- if and (hasKey $profile $field) (not (kindIs "bool" (get $profile $field))) -}}
        {{- fail (printf "workloadSecurityProfile.%s must be a boolean" $field) -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
  {{- toYaml $profile -}}
{{- end -}}

{{/* Existing contexts stay byte-for-byte equivalent when the profile is off. */}}
{{- define "wandb-base.containerSecurityProfile" -}}
  {{- $context := deepCopy (default dict .context) -}}
  {{- if .profile.enabled -}}
    {{- range $field := list "allowPrivilegeEscalation" "privileged" "capabilities" "seccompProfile" -}}
      {{- $_ := set $context $field (deepCopy (get $.profile $field)) -}}
    {{- end -}}
    {{- range $field := list "runAsNonRoot" "readOnlyRootFilesystem" -}}
      {{- if hasKey $.profile $field -}}
        {{- $_ := set $context $field (get $.profile $field) -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
  {{- toYaml $context -}}
{{- end -}}

{{- define "wandb-base.podSecurityProfile" -}}
  {{- $context := deepCopy (default dict .context) -}}
  {{- if .profile.enabled -}}
    {{- $_ := set $context "seccompProfile" (deepCopy .profile.seccompProfile) -}}
  {{- end -}}
  {{- toYaml $context -}}
{{- end -}}
