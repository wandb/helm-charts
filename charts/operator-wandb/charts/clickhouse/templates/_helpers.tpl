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
  {{- $secretName := .Values.bucket.secret.secretName -}}
  {{- $accessKey := .Values.bucket.secret.accessKeyName -}}
  {{- $secret := (lookup "v1" "Secret" .Release.Namespace $secretName) -}}
  {{- if and $secret $secret.data }}
    {{- $value := index $secret.data $accessKey | b64dec -}}
    {{- if $value }}
      {{- $value -}}
    {{- else }}
      {{- fail (printf "Key %s not found in Secret %s" $accessKey $secretName) -}}
    {{- end }}
  {{- else }}
    {{- fail (printf "Secret %s not found or has no data in namespace %s" $secretName .Release.Namespace) -}}
  {{- end }}
{{- end -}}


{{/*
Get S3 secret key from secret
*/}}
{{- define "clickhouse.s3.secretKey" -}}
  {{- include "clickhouse.validateS3Config" . -}}
  {{- $secretName := .Values.bucket.secret.secretName -}}
  {{- $secretKey := .Values.bucket.secret.secretKeyName -}}
  {{- $secret := (lookup "v1" "Secret" .Release.Namespace $secretName) -}}
  {{- if and $secret $secret.data }}
    {{- $value := index $secret.data $secretKey | b64dec -}}
    {{- if $value }}
      {{- $value -}}
    {{- else }}
      {{- fail (printf "Key %s not found in Secret %s" $secretKey $secretName) -}}
    {{- end }}
  {{- else }}
    {{- fail (printf "Secret %s not found or has no data in namespace %s" $secretName .Release.Namespace) -}}
  {{- end }}
{{- end -}}

{{/*
ClickHouse Server Configuration
*/}}
{{- define "clickhouse.serverConfig" -}}
{{- range $i, $e := until (.Values.replicas | int) }}
{{ include "clickhouse.fullname" $ }}-ch-server-{{ $i }}.xml: |
    <clickhouse replace="true">
        <default_database>{{ include "wandb.clickhouse.database" $ }}</default_database>
        <max_partition_size_to_drop>0</max_partition_size_to_drop>
        <profiles>
            <default></default>
        </profiles>
        <users>
            <default>
                <password>{{ include "wandb.clickhouse.password" $ }}</password>
                <access_management>1</access_management>
                <profile>{{ include "wandb.clickhouse.user" $ }}</profile>
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
        <http_port>{{ include "wandb.clickhouse.port" $ }}</http_port>
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
                    <endpoint>{{ index $.Values.bucket.endpoints $i }}</endpoint>
                    <region>{{ $.Values.bucket.region }}</region>
                    <access_key_id>{{ include "clickhouse.s3.accessKey" $ }}</access_key_id>
                    <secret_access_key>{{ include "clickhouse.s3.secretKey" $ }}</secret_access_key>
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
            <!-- log>/var/log/clickhouse-keeper/clickhouse-keeper.log</log>
            <errorlog>/var/log/clickhouse-keeper/clickhouse-keeper.err.log</errorlog>
            <size>1000M</size>
            <count>3</count -->
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
