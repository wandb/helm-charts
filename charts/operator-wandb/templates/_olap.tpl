{{/*
wandb.olapConfig merges global.olap.<featureName> over global.olap.default.

Usage:
  include "wandb.olapConfig" (dict "root" . "featureName" "registrySearch")

Returns: YAML string of the merged config map.

Sprig `merge` deep-merges nested maps (like params). Feature keys win,
missing keys fall through from default.
*/}}
{{- define "wandb.olapConfig" -}}
{{- $default := deepCopy (default (dict) (index .root.Values.global.olap "default")) -}}
{{- $feature := deepCopy (default (dict) (index .root.Values.global.olap .featureName)) -}}
{{- toYaml (merge $feature $default) -}}
{{- end -}}

{{/*
wandb.olapSecretName returns the internal K8s secret name for an OLAP feature.

Usage:
  include "wandb.olapSecretName" (dict "root" . "featureName" "registrySearch")

Returns: e.g. "myrelease-olap-registry-search"
*/}}
{{- define "wandb.olapSecretName" -}}
{{- $kebab := .featureName | snakecase | replace "_" "-" -}}
{{- printf "%s-olap-%s" .root.Release.Name $kebab -}}
{{- end -}}

{{/*
wandb.olapSecretKey returns the data key for the password within the OLAP secret.

Usage:
  include "wandb.olapSecretKey" (dict "envVarPrefix" "REGISTRY_SEARCH")

Returns: e.g. "REGISTRY_SEARCH_PASSWORD"
*/}}
{{- define "wandb.olapSecretKey" -}}
{{- printf "%s_PASSWORD" .envVarPrefix -}}
{{- end -}}

{{/*
wandb.olapFieldRef renders an OLAP env-var field that was supplied as a map
(a `valueFrom` K8s ref, or an inline `value`), injecting `optional: true` into
any secretKeyRef / configMapKeyRef.

Rationale: without `optional`, a missing Secret/ConfigMap (e.g. the ClickHouse
password secret not provisioned on an instance) makes the kubelet fail to
resolve the env var, so the pod never schedules (CreateContainerConfigError)
Marking the ref optional leaves the env var unset
instead, so Gorilla sees an invalid connection string and degrades gracefully
(registry search becomes a no-op) rather than the whole pod failing.

Usage:
  include "wandb.olapFieldRef" (dict "ref" $config.host)
*/}}
{{- define "wandb.olapFieldRef" -}}
{{- $ref := deepCopy .ref -}}
{{- if and (kindIs "map" $ref) (hasKey $ref "valueFrom") -}}
{{- if $ref.valueFrom.secretKeyRef -}}{{- $_ := set $ref.valueFrom.secretKeyRef "optional" true -}}{{- end -}}
{{- if $ref.valueFrom.configMapKeyRef -}}{{- $_ := set $ref.valueFrom.configMapKeyRef "optional" true -}}{{- end -}}
{{- end -}}
{{- toYaml $ref -}}
{{- end -}}

{{/*
wandb.olapParamsQuery serializes a params map into a URL query string.
Following the redis wandb.redis.parametersQuery pattern.

Usage:
  include "wandb.olapParamsQuery" (dict "params" $config.params)

Returns: "" (empty) or "?key=val&key=val"
*/}}
{{- define "wandb.olapParamsQuery" -}}
{{- $params := .params | default (dict) -}}
{{- $len := len $params -}}
{{- if gt $len 0 -}}
{{- $count := 0 -}}
{{- print "?" -}}
{{- range $key, $val := $params -}}
{{- $count = add $count 1 -}}
{{- printf "%s=%s" $key (toString $val) -}}
{{- if lt (int $count) $len -}}&{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
