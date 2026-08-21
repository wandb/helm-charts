{{/*
Expand the name of the chart.
*/}}
{{- define "orchestrator.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Return the unique hostnames accepted by authentication. global.fqdn is
canonical and global.additionalHosts adds auth-aware alternate names.
*/}}
{{- define "orchestrator.authHosts" -}}
  {{- $hosts := list -}}
  {{- $fqdn := .Values.global.fqdn | trimPrefix "https://" | trimPrefix "http://" | trimSuffix "/" -}}
  {{- if $fqdn -}}
    {{- $hosts = append $hosts $fqdn -}}
  {{- end -}}
  {{- $additionalHosts := default (list) .Values.global.additionalHosts -}}
  {{- $protocol := "https" -}}
  {{- if hasPrefix "http://" .Values.global.fqdn -}}
    {{- $protocol = "http" -}}
  {{- end -}}
  {{- range $additionalHosts -}}
    {{- $configuredHost := . -}}
    {{- if or (and (hasPrefix "http://" $configuredHost) (ne $protocol "http")) (and (hasPrefix "https://" $configuredHost) (ne $protocol "https")) -}}
      {{- fail "global.additionalHosts protocols must match global.fqdn" -}}
    {{- end -}}
    {{- $host := $configuredHost | trimPrefix "https://" | trimPrefix "http://" | trimSuffix "/" -}}
    {{- if and $host (not (has $host $hosts)) -}}
      {{- $hosts = append $hosts $host -}}
    {{- end -}}
  {{- end -}}
{{- toYaml $hosts -}}
{{- end }}

{{/*
Return the hostnames routed by the ingress. Deprecated ingress.additionalHosts
remain routing-only and cannot expand the authentication trust boundary.
*/}}
{{- define "orchestrator.applicationHosts" -}}
  {{- $hosts := include "orchestrator.authHosts" . | fromYamlArray -}}
  {{- range (default (list) .Values.ingress.additionalHosts) -}}
    {{- $host := . | trimPrefix "https://" | trimPrefix "http://" | trimSuffix "/" -}}
    {{- if and $host (not (has $host $hosts)) -}}
      {{- $hosts = append $hosts $host -}}
    {{- end -}}
  {{- end -}}
  {{- if eq (len $hosts) 0 -}}
    {{- $hosts = list "" -}}
  {{- end -}}
{{- toYaml $hosts -}}
{{- end }}

{{/*
Return the application origins used as valid JWT issuers. Alternate hosts use
the canonical fqdn's protocol because Better Auth's dynamic base URL accepts a
single protocol for every allowed host.
*/}}
{{- define "orchestrator.applicationOrigins" -}}
  {{- $protocol := "https" -}}
  {{- if hasPrefix "http://" .Values.global.fqdn -}}
    {{- $protocol = "http" -}}
  {{- end -}}
  {{- $origins := list -}}
  {{- range (include "orchestrator.authHosts" . | fromYamlArray) -}}
    {{- $origins = append $origins (printf "%s://%s" $protocol .) -}}
  {{- end -}}
{{- toYaml $origins -}}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "orchestrator.fullname" -}}
  {{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
  {{- else }}
    {{- $name := default .Chart.Name .Values.nameOverride }}
    {{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
    {{- else }}
      {{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
    {{- end }}
  {{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "orchestrator.chart" -}}
  {{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "orchestrator.labels" -}}
helm.sh/chart: {{ include "orchestrator.chart" . }}
{{ include "orchestrator.selectorLabels" . }}
  {{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
  {{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "orchestrator.selectorLabels" -}}
app.kubernetes.io/name: {{ include "orchestrator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "orchestrator.serviceAccountName" -}}
  {{- if .Values.serviceAccount.create }}
{{- default (include "orchestrator.fullname" .) .Values.serviceAccount.name }}
  {{- else }}
{{- default "default" .Values.serviceAccount.name }}
  {{- end }}
{{- end }}
