{{/* Direct requests take precedence over sizing requests for active containers. */}}
{{- define "wandb-base.hasDirectRequestOverride" -}}
  {{- $serviceResources := default dict .root.Values.resources }}
  {{- $serviceRequests := default dict $serviceResources.requests }}
  {{- $hasOverride := hasKey $serviceRequests .resource }}
  {{- range $container := .root.Values.containers }}
    {{- $enabled := true }}
    {{- if hasKey $container "enabled" }}
      {{- if kindIs "string" $container.enabled }}
        {{- $enabled = eq (tpl $container.enabled $.root | trim) "true" }}
      {{- else }}
        {{- $enabled = $container.enabled }}
      {{- end }}
    {{- end }}
    {{- if $enabled }}
      {{- $resources := default dict $container.resources }}
      {{- $requests := default dict $resources.requests }}
      {{- $hasOverride = or $hasOverride (hasKey $requests $.resource) }}
    {{- end }}
  {{- end }}
{{- $hasOverride -}}
{{- end }}

{{/* Convert only opted-in resource triggers; queue and controller settings pass through. */}}
{{- define "wandb-base.kedaResourceTriggers" -}}
  {{- $baselines := default dict .keda.resourceRequestBaseline }}
  {{- $triggers := deepCopy .keda.triggers }}
  {{- range $trigger := $triggers }}
    {{- $baselineKey := get (dict "cpu" "cpuMillicores" "memory" "memoryBytes") $trigger.type }}
    {{- $baseline := get $baselines $baselineKey }}
    {{- $hasOverride := eq (include "wandb-base.hasDirectRequestOverride" (dict "root" $.root "resource" $trigger.type)) "true" }}
    {{- $metadata := default dict $trigger.metadata }}
    {{- $metricType := default $metadata.type $trigger.metricType }}
    {{- $convert := and $baselineKey $baseline (not $hasOverride) (eq $metricType "Utilization") }}
    {{- if $convert }}
      {{- if $metadata.containerName }}
        {{- fail "KEDA resourceRequestBaseline describes the whole pod; clear that resource baseline before using containerName" }}
      {{- end }}
      {{- $baselineValue := float64 $baseline }}
      {{- if or (le $baselineValue 0.0) (ne $baselineValue (floor $baselineValue)) }}
        {{- fail "KEDA resourceRequestBaseline values must be positive whole numbers, or zero to disable conversion" }}
      {{- end }}
      {{- $percentage := tpl (toString $metadata.value) $.root }}
      {{- if not (regexMatch "^[1-9][0-9]*$" $percentage) }}
        {{- fail "KEDA resource utilization must be a positive integer percentage" }}
      {{- end }}
      {{- $target := divf (mulf $baselineValue (float64 $percentage)) 100 }}
      {{- $quantity := printf "%.0f" (ceil $target) }}
      {{- if eq $trigger.type "cpu" }}
        {{- $quantity = printf "%gm" $target }}
      {{- end }}
      {{- $_ := set $trigger "metricType" "AverageValue" }}
      {{- $_ = unset $metadata "type" }}
      {{- $_ = set $metadata "value" $quantity }}
    {{- end }}
  {{- end }}
{{- toYaml $triggers -}}
{{- end }}
