{{/*
Expand the name of the chart.
*/}}
{{- define "clickhouse.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "clickhouse.fullname" -}}
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
{{- define "clickhouse.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Returns common labels
*/}}
{{- define "clickhouse.commonLabels" -}}
{{- range $key, $value := (default dict .Values.common.labels) }}
{{ $key }}: {{ $value | quote }}
{{- end }}
{{- end }}

{{/*
Returns a list of _pod_ labels to be shared across all
app deployments.
*/}}
{{- define "clickhouse.podLabels" -}}
{{- range $key, $value := .Values.pod.labels }}
{{ $key }}: {{ $value | quote }}
{{- end }}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "clickhouse.labels" -}}
helm.sh/chart: {{ include "clickhouse.chart" . }}
{{ include "clickhouse.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
wandb.com/app-name: {{ include "clickhouse.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "clickhouse.selectorLabels" -}}
app.kubernetes.io/name: {{ include "clickhouse.name" . }}{{ .suffix }}
app.kubernetes.io/instance: {{ .Release.Name }}{{ .suffix }}
{{- end }}

{{/*
Clickhouse Server Service Port
*/}}
{{- define "clickhouse.servicePorts" -}}
- name: http
  targetPort: http
  port: {{ include "wandb.clickhouse.port" . }}
  protocol: TCP
- name: tcp
  targetPort: tcp
  port: {{ .Values.server.tcpPort }}
  protocol: TCP
- name: intrsrvhttp
  targetPort: intrsrvhttp
  port: {{ .Values.server.intrsrvhttpPort }}
  protocol: TCP
{{- end }}

{{/*
Clickhouse Keeper Service Port
*/}}
{{- define "clickhouse.keeper.servicePorts" -}}
- name: http
  targetPort: http
  port: {{ .Values.keeper.httpPort }}
  protocol: TCP
- name: tcp
  targetPort: tcp
  port: {{ .Values.keeper.tcpPort }}
  protocol: TCP
- name: raft
  targetPort: raft
  port: {{ .Values.keeper.raftPort }}
  protocol: TCP
{{- end }}

{{/*
ClickHouse Server Nodes
*/}}
{{- define "clickhouse.serverNodes.replicas" }}
{{- range $i, $e := until (.Values.replicas | int) }}
<replica>
    <host>{{- include "clickhouse.fullname" $ }}-ch-server-{{ $i }}.{{- include "clickhouse.fullname" $ }}-ch-server-headless.{{ $.Release.Namespace }}.svc.cluster.local</host>
    <port>{{ $.Values.server.tcpPort }}</port>
</replica>
{{- end }}
{{- end }}

{{/*
Clickhouse Keeper Nodes 
*/}}
{{- define "clickhouse.keeperNodes" -}}
{{- range $i, $e := until 3 }}
<node>
    <host>{{- include "clickhouse.fullname" $ }}-ch-keeper-{{ $i }}.{{- include "clickhouse.fullname" $ }}-ch-keeper-headless.{{ $.Release.Namespace }}.svc.cluster.local</host>
    <port>{{ $.Values.server.zookeeperPort }}</port></node>
{{- end }}
{{- end }}

{{/*
ClickHouse Keeper Raft Configuration
*/}}
{{- define "clickhouse.raftNodes" -}}
{{- range $i, $e := until 3 }}
<server>
    <id>{{ $i }}</id>
    <hostname>{{ include "clickhouse.fullname" $ }}-ch-keeper-{{ $i }}.{{ include "clickhouse.fullname" $ }}-ch-keeper-headless.{{ $.Release.Namespace }}.svc.cluster.local</hostname>
    <port>{{ $.Values.keeper.raftPort }}</port>
</server>
{{- end }}
{{- end }}

{{/*
Validate required S3 configuration
*/}}
{{- define "clickhouse.validateS3Config" -}}
{{- if not .Values.bucket.region -}}
{{- fail "buckets.region is required" -}}
{{- end -}}
{{- if not .Values.bucket.endpoints -}}
{{- fail "buckets.endpoints is required" -}}
{{- end -}}
{{- end -}}

{{/*
Get S3 access key from secret
*/}}
{{- define "clickhouse.s3.accessKey" -}}
  {{- if .Values.bucket.accessKeyId -}}
    {{- .Values.bucket.accessKeyId -}}
  {{- else if .Values.bucket.useInstanceMetadata -}}
    instance-metadata
  {{- else -}}
    {{- $secretName := .Values.bucket.secret.secretName -}}
    {{- $accessKey := .Values.bucket.secret.accessKeyName -}}
    {{- if and (not .Release.IsInstall) (not .Release.IsUpgrade) -}}
      {{- /* Return a dummy value for lint/template */ -}}
      dummy-access-key-lint-only
    {{- else -}}
      {{- $secret := (lookup "v1" "Secret" .Release.Namespace $secretName) -}}
      {{- if and $secret $secret.data }}
        {{- $value := index $secret.data $accessKey | b64dec -}}
        {{- if $value }}
          {{- $value -}}
        {{- else }}
          {{- printf "missing-access-key-%s" (randAlphaNum 8) | quote -}}
        {{- end }}
      {{- else }}
        {{- printf "missing-secret-%s" (randAlphaNum 8) | quote -}}
      {{- end }}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
Get S3 secret key from secret
*/}}
{{- define "clickhouse.s3.secretKey" -}}
  {{- if .Values.bucket.secretAccessKey -}}
    {{- .Values.bucket.secretAccessKey -}}
  {{- else if .Values.bucket.useInstanceMetadata -}}
    instance-metadata
  {{- else -}}
    {{- $secretName := .Values.bucket.secret.secretName -}}
    {{- $secretKey := .Values.bucket.secret.secretKeyName -}}
    {{- if and (not .Release.IsInstall) (not .Release.IsUpgrade) -}}
      {{- /* Return a dummy value for lint/template */ -}}
      dummy-secret-key-lint-only
    {{- else -}}
      {{- $secret := (lookup "v1" "Secret" .Release.Namespace $secretName) -}}
      {{- if and $secret $secret.data }}
        {{- $value := index $secret.data $secretKey | b64dec -}}
        {{- if $value }}
          {{- $value -}}
        {{- else }}
          {{- printf "missing-secret-key-%s" (randAlphaNum 8) | quote -}}
        {{- end }}
      {{- else }}
        {{- printf "missing-secret-%s" (randAlphaNum 8) | quote -}}
      {{- end }}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
Get ClickHouse password for S3 configuration
*/}}
{{- define "clickhouse.s3.password" -}}
{{- include "wandb.clickhouse.password" . -}}
{{- end -}}

{{/*
ClickHouse Server Configuration
*/}}
{{- define "clickhouse.serverConfig" -}}
{{- range $i, $e := until (.Values.replicas | int) }}
{{ include "clickhouse.fullname" $ }}-ch-server-{{ $i }}.xml: |
    <clickhouse replace="true">
        <default_database>{{ include "clickhouse.local.database" $ }}</default_database>
        <max_partition_size_to_drop>0</max_partition_size_to_drop>
        <profiles>
            <default></default>
        </profiles>
        <users>
            <default>
                <password>{{ include "clickhouse.local.password" $ }}</password>
                <access_management>1</access_management>
                <profile>{{ include "clickhouse.local.user" $ }}</profile>
            </default>
        </users>
        <user_directories>
            <users_xml>
                <path>/etc/clickhouse-server/users.xml</path>
            </users_xml>
        </user_directories>
        <path>/var/lib/clickhouse/</path>
        <tmp_path>/var/lib/clickhouse/tmp/</tmp_path>
        <user_files_path>/var/lib/clickhouse/user_files/</user_files_path>
        <format_schema_path>/var/lib/clickhouse/format_schemas/</format_schema_path>
        <logger>
            <level>debug</level>
            <console>true</console>
            <log remove="remove"/>
            <errorlog remove="remove"/>
        </logger>
        <display_name>wandb_weave node_{{ $i }}</display_name>
        <listen_host>0.0.0.0</listen_host>
        <http_port>{{ include "clickhouse.local.port" $ }}</http_port>
        <tcp_port>{{ $.Values.server.tcpPort }}</tcp_port>
        <interserver_http_port>{{ $.Values.server.intrsrvhttpPort }}</interserver_http_port>
        <distributed_ddl>
            <path>/clickhouse/task_queue/ddl</path>
        </distributed_ddl>
        <remote_servers>
            <wandb_weave>
                <shard>
                    <internal_replication>true</internal_replication>
                    {{- include "clickhouse.serverNodes.replicas" $ | nindent 20 }}
                </shard>
            </wandb_weave>
        </remote_servers>
        <zookeeper>
            {{- include "clickhouse.keeperNodes" $ | nindent 16 }}
        </zookeeper>
        <macros>
            <shard>01</shard>
            <replica>0{{ $i }}</replica>
            <cluster>{{ $.Values.server.cluster }}</cluster>
        </macros>
        <merge_tree>
            <storage_policy>s3_main</storage_policy>
        </merge_tree>
        <storage_configuration>
            <disks>
                <s3_express>
                    <type>s3</type>
                    {{- if $.Values.bucket.useSingleBucket }}
                    {{- /* Single bucket mode */}}
                    <endpoint>{{ $.Values.bucket.endpoint }}</endpoint>
                    {{- if $.Values.bucket.usePathStyle }}
                    <use_path_style_endpoint>true</use_path_style_endpoint>
                    {{- end }}
                    <region>{{ $.Values.bucket.region }}</region>
                    {{- if $.Values.bucket.useInstanceMetadata }}
                    <use_instance_metadata>true</use_instance_metadata>
                    {{- else }}
                    <access_key_id>{{ include "clickhouse.s3.accessKey" $ }}</access_key_id>
                    <secret_access_key>{{ include "clickhouse.s3.secretKey" $ }}</secret_access_key>
                    {{- end }}
                    <path_prefix>{{ $.Values.bucket.path }}/replica-{{ $i }}</path_prefix>
                    {{- else }}
                    {{- /* Multiple bucket mode */}}
                    {{- $endpoint := index $.Values.bucket.endpoints $i }}
                    {{- if kindIs "string" $endpoint }}
                    {{- /* Simple string endpoint */}}
                    <endpoint>{{ $endpoint }}</endpoint>
                    {{- if $.Values.bucket.usePathStyle }}
                    <use_path_style_endpoint>true</use_path_style_endpoint>
                    {{- end }}
                    <region>{{ $.Values.bucket.region }}</region>
                    {{- if $.Values.bucket.useInstanceMetadata }}
                    <use_instance_metadata>true</use_instance_metadata>
                    {{- else }}
                    <access_key_id>{{ include "clickhouse.s3.accessKey" $ }}</access_key_id>
                    <secret_access_key>{{ include "clickhouse.s3.secretKey" $ }}</secret_access_key>
                    {{- end }}
                    {{- else }}
                    {{- /* Object with custom credentials */}}
                    <endpoint>{{ $endpoint.url }}</endpoint>
                    {{- if $.Values.bucket.usePathStyle }}
                    <use_path_style_endpoint>true</use_path_style_endpoint>
                    {{- end }}
                    <region>{{ $.Values.bucket.region }}</region>
                    {{- if $endpoint.useInstanceMetadata }}
                    <use_instance_metadata>true</use_instance_metadata>
                    {{- else if and $endpoint.accessKeyId $endpoint.secretAccessKey }}
                    <access_key_id>{{ $endpoint.accessKeyId }}</access_key_id>
                    <secret_access_key>{{ $endpoint.secretAccessKey }}</secret_access_key>
                    {{- else if $endpoint.secretName }}
                    {{- $secretName := $endpoint.secretName }}
                    {{- $accessKeyName := default "ACCESS_KEY" $endpoint.accessKeyName }}
                    {{- $secretKeyName := default "SECRET_KEY" $endpoint.secretKeyName }}
                    {{- $secret := (lookup "v1" "Secret" $.Release.Namespace $secretName) }}
                    {{- if and $secret $secret.data }}
                    <access_key_id>{{ index $secret.data $accessKeyName | b64dec }}</access_key_id>
                    <secret_access_key>{{ index $secret.data $secretKeyName | b64dec }}</secret_access_key>
                    {{- else }}
                    <access_key_id>{{ include "clickhouse.s3.accessKey" $ }}</access_key_id>
                    <secret_access_key>{{ include "clickhouse.s3.secretKey" $ }}</secret_access_key>
                    {{- end }}
                    {{- else }}
                    {{- /* Fall back to global credentials */}}
                    {{- if $.Values.bucket.useInstanceMetadata }}
                    <use_instance_metadata>true</use_instance_metadata>
                    {{- else }}
                    <access_key_id>{{ include "clickhouse.s3.accessKey" $ }}</access_key_id>
                    <secret_access_key>{{ include "clickhouse.s3.secretKey" $ }}</secret_access_key>
                    {{- end }}
                    {{- end }}
                    {{- end }}
                    {{- end }}
                </s3_express>
            </disks>
            <policies>
                <s3_express>
                    <volumes>
                        <main>
                            <disk>s3_express</disk>
                        </main>
                    </volumes>
                </s3_express>
            </policies>
        </storage_configuration>
    </clickhouse>
{{- end }}
{{- end }}

{{/*
ClickHouse Keeper Instance Configuration
*/}}
{{- define "clickhouse.keeperConfig" -}}
{{- range $i, $e := until 3 }}
  {{ include "clickhouse.fullname" $ }}-ch-keeper-{{ $i }}.xml: |
    <clickhouse replace="true">
        <path>/var/lib/clickhouse/coordination/keeper</path>
        <logger>
            <level>information</level>
            <console>true</console>
            <log remove="remove"/>
            <errorlog remove="remove"/>
        </logger>
        <listen_host>0.0.0.0</listen_host>
        <keeper_server>
            <tcp_port>{{ $.Values.keeper.tcpPort }}</tcp_port>
            <http_control>
              <port>{{ $.Values.keeper.httpPort }}</port>
              <readiness><endpoint>/ready</endpoint></readiness>
              <liveness><endpoint>/health</endpoint></liveness>
            </http_control>
            <server_id>{{ $i }}</server_id>
            <log_storage_path>/var/lib/clickhouse/coordination/log</log_storage_path>
            <snapshot_storage_path>/var/lib/clickhouse/coordination/snapshots</snapshot_storage_path>
            <coordination_settings>
                <operation_timeout_ms>10000</operation_timeout_ms>
                <session_timeout_ms>30000</session_timeout_ms>
                <raft_logs_level>information</raft_logs_level>
            </coordination_settings>
            <raft_configuration>
            {{- include "clickhouse.raftNodes" $ | nindent 20 }}
            </raft_configuration>
        </keeper_server>
    </clickhouse>
{{- end }}
{{- end }}

{{/*
Calculate the total storage size needed based on cache size + 10Gi
*/}}
{{- define "clickhouse.calculateStorageSize" -}}
{{- $cacheSize := .Values.cache.size | default "20Gi" -}}
{{- $numericSize := regexReplaceAll "([0-9]+)([A-Za-z]+)" $cacheSize "${1}" | int -}}
{{- $unit := regexReplaceAll "([0-9]+)([A-Za-z]+)" $cacheSize "${2}" -}}
{{- $totalSize := add $numericSize 10 -}}
{{- printf "%d%s" $totalSize $unit -}}
{{- end -}}

{{/*
Helper to determine if ClickHouse should be installed
*/}}
{{- define "clickhouse.shouldInstall" -}}
{{- if .Values.clickhouse.install -}}true{{- else -}}false{{- end -}}
{{- end -}}

{{/*
Helper for ClickHouse installation */}}
{{- define "clickhouse.useInstalledClickhouse" -}}false{{- end -}}

{{/*
Helper functions to provide fallbacks when parent chart functions aren't available
*/}}

{{/*
Get ClickHouse password secret name with fallback
*/}}
{{- define "clickhouse.local.passwordSecret" -}}
wandb-clickhouse
{{- end -}}

{{/*
Get ClickHouse password with fallback
*/}}
{{- define "clickhouse.local.password" -}}
{{- randAlphaNum 16 -}}
{{- end -}}

{{/*
Get ClickHouse database with fallback
*/}}
{{- define "clickhouse.local.database" -}}
{{- .Values.clickhouse.database | default "weave_trace_db" -}}
{{- end -}}

{{/*
Get ClickHouse user with fallback
*/}}
{{- define "clickhouse.local.user" -}}
{{- .Values.clickhouse.user | default "wandb-user" -}}
{{- end -}}

{{/*
Get ClickHouse port with fallback
*/}}
{{- define "clickhouse.local.port" -}}
{{- .Values.clickhouse.server.httpPort | default 8123 -}}
{{- end -}}

{{/*
Helper for common labels with fallback
*/}}
{{- define "clickhouse.local.commonLabels" -}}
helm.sh/chart: {{ include "clickhouse.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: wandb
{{- end -}}
