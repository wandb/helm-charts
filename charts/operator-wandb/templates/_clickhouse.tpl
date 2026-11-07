{{/*
Return name of secret where clickhouse information is stored
*/}}
{{- define "wandb.clickhouse.passwordSecret" -}}
  {{- if .Values.global.clickhouse.passwordSecret.name }}
  {{- .Values.global.clickhouse.passwordSecret.name -}}
  {{- else -}}
  {{- print .Release.Name "-clickhouse" -}}
  {{- end -}}
{{- end }}

{{- define "wandb.clickhouse.host" -}}
  {{- tpl .Values.global.clickhouse.host . -}}
{{- end }}

{{- define "wandb.clickhouse.port" -}}
  {{- if .Values.global.clickhouse.port }}
  {{- print $.Values.global.clickhouse.port -}}
  {{- else -}}
    {{- $host := (include "wandb.clickhouse.host" .) -}}
    {{- if eq $host (print .Release.Name "-clickhouse-headless") }}
    {{- print "8123" -}}
    {{- else -}}
    {{- print "8443" -}}
    {{- end -}}
  {{- end -}}
{{- end }}

{{/*
Return the database name
*/}}
{{- define "wandb.clickhouse.database" -}}
{{- print $.Values.global.clickhouse.database -}}
{{- end -}}

{{/*
Return the database user
*/}}
{{- define "wandb.clickhouse.user" -}}
  {{- if kindIs "map" $.Values.global.clickhouse.user -}}
    {{- print "default" -}}
  {{- else -}}
    {{- print $.Values.global.clickhouse.user -}}
  {{- end -}}
{{- end -}}

{{/*
Return the database password
*/}}
{{- define "wandb.clickhouse.password" -}}
{{- print $.Values.global.clickhouse.password -}}
{{- end -}}

{{/*
Helm fills global.clickhouse with chart defaults even when no legacy connection
was configured. Ignore those defaults and empty fields; preserve any nonempty
customization, including valueFrom maps and password Secret overrides.
Keep this baseline aligned with global.clickhouse in values.yaml. The automatic
selection tests verify that untouched chart defaults do not count as enrollment.
*/}}
{{- define "wandb.weaveTraceLegacyClickhouseConfigured" -}}
  {{- $defaults := dict
  "host" "{{ .Release.Name }}-clickhouse-headless"
    "port" ""
    "password" ""
    "passwordSecret" (dict "name" "" "passwordKey" "CLICKHOUSE_PASSWORD")
    "database" "weave_trace_db"
    "user" "default"
    "replicated" false
  -}}
  {{- $configured := false -}}
  {{- range $key, $value := default (dict) .Values.global.clickhouse -}}
    {{- if and (not (empty $value)) (not (deepEqual $value (get $defaults $key))) -}}
      {{- $configured = true -}}
    {{- end -}}
  {{- end -}}
{{- $configured -}}
{{- end -}}

{{/*
Resolve one source for Weave runtime containers and its migration init container.
Auto selects an enabled OLAP profile only without legacy or bundled ClickHouse.
Explicit legacy/olap values remain available for opt-out and deliberate cutover.
*/}}
{{- define "wandb.weaveTraceClickhouseSource" -}}
  {{- $source := default "auto" .Values.global.weaveTrace.clickhouseSource -}}
  {{- if not (has $source (list "auto" "legacy" "olap")) -}}
    {{- fail (printf "global.weaveTrace.clickhouseSource must be one of: auto, legacy, olap; got %q" $source) -}}
  {{- end -}}
  {{- $config := include "wandb.olapConfig" (dict "root" . "featureName" "weaveTrace") | fromYaml -}}
  {{- if eq $source "auto" -}}
    {{- $legacyConfigured := eq (include "wandb.weaveTraceLegacyClickhouseConfigured" .) "true" -}}
    {{- $bundled := default false .Values.global.weaveTrace.bundledClickhouse -}}
    {{- $useOlap := and $config.enabled (not $legacyConfigured) (not $bundled) -}}
    {{- $source = ternary "olap" "legacy" $useOlap -}}
  {{- end -}}
  {{- if and (eq $source "olap") (not $config.enabled) -}}
    {{- fail "global.olap.weaveTrace.enabled must be true when global.weaveTrace.clickhouseSource is olap" -}}
  {{- end -}}
{{- $source -}}
{{- end -}}
