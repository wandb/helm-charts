{{/*
This template is used to generate the deployment for the app, and is used for both the non-glue and glue deployments.
*/}}
{{- define "app.deployment" -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "app.fullname" . }}{{ .suffix }}
  labels:
    {{- include "wandb.commonLabels" . | nindent 4 }}
    {{- include "app.commonLabels" . | nindent 4 }}
    {{- include "app.labels" . | nindent 4 }}
    {{- if .Values.deployment.labels }}
    {{-   toYaml .Values.deployment.labels | nindent 4 }}
    {{- end }}
  annotations:
    {{- include "wandb.deploymentAnnotations" . | nindent 4 }}
    {{- if .Values.deployment.annotations }}
    {{-   toYaml .Values.deployment.annotations | nindent 4 }}
    {{- end }}
spec:
  replicas: 1
  selector:
    matchLabels:
      {{- include "wandb.selectorLabels" . | nindent 6 }}
      {{- include "app.labels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "wandb.podLabels" . | nindent 8 }}
        {{- include "app.commonLabels" . | nindent 8 }}
        {{- include "app.podLabels" . | nindent 8 }}
        {{- include "app.labels" . | nindent 8 }}
      annotations:
        checksum/secret: {{ include (print $.Template.BasePath "/secrets.yaml") . | sha256sum }}
        {{- if .Values.pod.annotations }}
        {{-   toYaml .Values.pod.annotations | nindent 8 }}
        {{- end }}
    spec:
      serviceAccountName: {{ include "app.serviceAccountName" . }}
      {{- if .tolerations }}
      tolerations:
        {{- toYaml .tolerations | nindent 8 }}
      {{- end }}
      {{- include "wandb.nodeSelector" . | nindent 6 }}
      {{- include "wandb.priorityClassName" . | nindent 6 }}
      {{- include "wandb.podSecurityContext" .Values.pod.securityContext | nindent 6 }}
      terminationGracePeriodSeconds: 60
      initContainers:
        - name: init-db
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          env:
            - name: MYSQL_PORT
              value: "{{ include "wandb.mysql.port" . }}"
            - name: MYSQL_HOST
              value: "{{ include "wandb.mysql.host" . }}"
            - name: MYSQL_DATABASE
              value: "{{ include "wandb.mysql.database" . }}"
            - name: MYSQL_USER
              value: "{{ include "wandb.mysql.user" . }}"
            - name: MYSQL_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: {{ include "wandb.mysql.passwordSecret" . }}
                  key: {{ .Values.global.mysql.passwordSecret.passwordKey }}
          command: ['bash', '-c', "until mysql -h$MYSQL_HOST -u$MYSQL_USER -p$MYSQL_PASSWORD -D$MYSQL_DATABASE -P$MYSQL_PORT --execute=\"SELECT 1\"; do echo waiting for db; sleep 2; done"]
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          {{- include "wandb.containerSecurityContext" .Values.container.securityContext | nindent 10 }}
          volumeMounts:
            {{- if ne (include "wandb.redis.caCert" .) "" }}
            - name: {{ include "app.fullname" . }}-redis-ca
              mountPath: /etc/ssl/certs/redis_ca.pem
              subPath: redis_ca.pem
            {{- end }}
            {{- if .Values.global.caCertsConfigMap }}
            - name: wandb-ca-certs-user
              mountPath: /usr/local/share/ca-certificates/
            {{- end }}
            {{- if .Values.global.customCACerts }}
            {{- range $index, $v := .Values.global.customCACerts }}
            - name: wandb-ca-certs
              mountPath: /usr/local/share/ca-certificates/customCA{{$index}}.crt
              subPath: customCA{{$index}}.crt
            {{- end }}
            {{- end }}
          ports:
            - name: http
              containerPort: 8080
              protocol: TCP
            - name: prometheus
              containerPort: 8181
              protocol: TCP
            - name: gorilla-statsd
              containerPort: 8125
              protocol: TCP
          env:
            - name: GOMEMLIMIT
              valueFrom:
                resourceFieldRef:
                  resource: limits.memory
            - name: GLUE_ENABLED
              value: "{{ .glueSingletonEnabled }}"
            {{- if .onlyService }}
            - name: ONLY_SERVICE
              value: {{ .onlyService }}
            {{- end }}
            - name: HOST
              value: "{{ .Values.global.host }}"
            {{- if .Values.extraCors }}
            - name: GORILLA_CORS_ORIGINS
              value: "{{ join "," .Values.extraCors }}"
            {{- end }}
            - name: MYSQL_PORT
              value: "{{ include "wandb.mysql.port" . }}"
            - name: MYSQL_HOST
              value: "{{ include "wandb.mysql.host" . }}"
            - name: MYSQL_DATABASE
              value: "{{ include "wandb.mysql.database" . }}"
            - name: MYSQL_USER
              value: "{{ include "wandb.mysql.user" . }}"
            - name: MYSQL_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: {{ include "wandb.mysql.passwordSecret" . }}
                  key: {{ .Values.global.mysql.passwordSecret.passwordKey }}
            - name: MYSQL
              value: "mysql://$(MYSQL_USER):$(MYSQL_PASSWORD)@$(MYSQL_HOST):$(MYSQL_PORT)/$(MYSQL_DATABASE)"
            - name: WEAVE_SERVICE
              value: "{{ .Release.Name }}-weave:9994"
            - name: PARQUET_HOST
              value: "http://{{ .Release.Name }}-parquet:8087"
            - name: PARQUET_ENABLED
              value: "true"
            {{- if index .Values.global "weave-trace" "enabled" }}
            - name: WEAVE_TRACES_ENABLED
              value: "true"
            {{- end }}
            - name: REDIS_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: {{ include "wandb.redis.passwordSecret" . }}
                  optional: true
                  key: {{ .Values.global.redis.secretKey }}
            - name: REDIS_PORT
              value: "{{ include "wandb.redis.port" . }}"
            - name: REDIS_HOST
              value: "{{ include "wandb.redis.host" . }}"
            - name: REDIS
              value: "{{ include "app.redis" . | trim }}"
            - name: SLACK_CLIENT_ID
              value: {{ .Values.global.slack.clientId | quote }}
            - name: SLACK_SECRET
              valueFrom:
                secretKeyRef:
                  name: {{ include "app.fullname" . }}-config
                  key: SLACK_SECRET
                  optional: true
            {{- if ne .Values.global.email.smtp.host "" }}
            - name: GORILLA_EMAIL_SINK
              value: "smtp://{{ .Values.global.email.smtp.user }}:{{ .Values.global.email.smtp.password }}@{{ .Values.global.email.smtp.host }}:{{ .Values.global.email.smtp.port }}"
            {{- end }}
            {{- if and .Values.global.licenseSecret.name .Values.global.licenseSecret.key }}
            - name: LICENSE
              valueFrom:
                secretKeyRef:
                  name: {{ .Values.global.licenseSecret.name }}
                  key: {{ .Values.global.licenseSecret.key }}
                  optional: true
            - name: GORILLA_LICENSE
              valueFrom:
                secretKeyRef:
                  name: {{ .Values.global.licenseSecret.name }}
                  key: {{ .Values.global.licenseSecret.key }}
                  optional: true
            {{- else }}
            - name: LICENSE
              valueFrom:
                secretKeyRef:
                  name: {{ include "app.fullname" . }}-config
                  key: LICENSE
                  optional: true
            - name: GORILLA_LICENSE
              valueFrom:
                secretKeyRef:
                  name: {{ include "app.fullname" . }}-config
                  key: LICENSE
                  optional: true
            {{- end }}
            {{- if ne .Values.global.auth.oidc.clientId ""  }}
            - name: OIDC_CLIENT_ID            
              value: {{ .Values.global.auth.oidc.clientId }}
            - name: OIDC_AUTH_METHOD
              value: {{ .Values.global.auth.oidc.authMethod }}
            - name: OIDC_ISSUER
              value: {{ .Values.global.auth.oidc.issuer }}
            - name: OIDC_CLIENT_SECRET
              value: {{ .Values.global.auth.oidc.secret }}
            {{- end }}
            - name: GORILLA_SESSION_LENGTH
              value: "{{ .Values.global.auth.sessionLengthHours }}h"
            {{- if and .Values.global .Values.global.observability }}
            {{- if eq (default "custom" .Values.global.observability.mode) "otel" }}
            - name: GORILLA_STATSD_PORT
              value: "8125"
            - name: GORILLA_STATSD_HOST
              value: "0.0.0.0"
            {{- end }}
            {{- end }}
            - name: BUCKET
              value: "{{ include "app.bucket" . }}"
            - name: AWS_REGION
              value: {{ .Values.global.bucket.region | default .Values.global.defaultBucket.region }}
            - name: AWS_S3_KMS_ID
              value: "{{ .Values.global.bucket.kmsKey | default .Values.global.defaultBucket.kmsKey }}"
            - name: OPERATOR_ENABLED
              value: 'true'
            - name: LOGGING_ENABLED
              value: 'true'
            - name: AZURE_STORAGE_KEY
              valueFrom:
                secretKeyRef:
                  name: "{{ include "wandb.bucket.secret" . }}"
                  key: {{ .Values.global.bucket.accessKeyName }}
                  optional: true
            - name: GORILLA_CUSTOMER_SECRET_STORE_K8S_CONFIG_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
            - name: G_HOST_IP
              valueFrom:
                fieldRef:
                  fieldPath: status.hostIP
            - name: BANNERS
              value: {{ toJson .Values.global.banners | quote }}
            {{- if ne .Values.traceRatio 0.0 }}
            - name: GORILLA_TRACER
              value: "otlp+grpc://{{ .Release.Name }}-otel-daemonset:4317?trace_ratio={{ .Values.traceRatio }}"
            {{- end }}
            - name: OVERFLOW_BUCKET_ADDR
              value: "{{ include "app.bucket" .}}"
            {{- if not .Values.global.pubSub.enabled}}
            - name: KAFKA_BROKER_HOST
              value: "{{ include "wandb.kafka.brokerHost" . }}"
            - name: KAFKA_BROKER_PORT
              value: "{{ include "wandb.kafka.brokerPort" . }}"
            - name: KAFKA_CLIENT_USER
              value: "{{ include "wandb.kafka.user" . }}"
            - name: KAFKA_CLIENT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: {{ include "wandb.kafka.passwordSecret" . }}
                  key: KAFKA_CLIENT_PASSWORD
            - name: KAFKA_TOPIC_RUN_UPDATE_SHADOW_QUEUE
              value: {{ include "wandb.kafka.runUpdatesShadowTopic" .}}
            - name: KAFKA_RUN_UPDATE_SHADOW_QUEUE_NUM_PARTITIONS
              value: "{{ include "wandb.kafka.runUpdatesShadowNumPartitions" .}}"
            {{- end }}
            - name: GORILLA_RUN_UPDATE_SHADOW_QUEUE
              value: >
                {
                  "overflow-bucket": {
                    "store": "{{ include "app.bucket" .}}",
                    "name": "wandb",
                    "prefix": "wandb-overflow"
                  },
                  "addr": "{{ include "app.runUpdateShadowTopic" .}}"
                }
            - name: GORILLA_ARTIFACTS_GC_BATCH_SIZE
              value: {{ .Values.artifactsGc.BatchSize | quote }}
            - name: GORILLA_ARTIFACTS_GC_NUM_WORKERS
              value: {{ .Values.artifactsGc.NumWorkers | quote }}
            - name: GORILLA_ARTIFACTS_GC_DELETE_FILES_NUM_WORKERS
              value: {{ .Values.artifactsGc.DeleteFilesNumWorkers | quote }}

            {{- if .Values.global.executor.enabled }}
            - name: GORILLA_TASK_QUEUE
              value: "{{ include "app.redis" . | trim }}"
            - name: GORILLA_TASK_QUEUE_MONITOR_PORT
              value: "10000"
            - name: GORILLA_TASK_QUEUE_WORKER_ENABLED
              value: "false"
            {{- end }}

            {{- if index .Values.global "weave-trace" "enabled" }}
            - name: GORILLA_INTERNAL_JWT_SUBJECTS_TO_ISSUERS
              value: {{ tpl (include "app.internalJWTMap" .) . }}
            {{- end }}

            {{- include "app.extraEnv" (dict "global" $.Values.global "local" .Values) | nindent 12 }}
            {{- include "wandb.extraEnvFrom" (dict "root" $ "local" .) | nindent 12 }}
          {{- if .healthCheckEnabled }}
          livenessProbe:
            httpGet:
              path: /healthz
              port: http
          readinessProbe:
            httpGet:
              path: /ready
              port: http
            initialDelaySeconds: 20
            periodSeconds: 5
          startupProbe:
            httpGet:
              path: /ready
              port: http
            initialDelaySeconds: 20
            periodSeconds: 5
            failureThreshold: 120
          lifecycle:
            preStop:
              exec:
                command: ["sleep", "25"]
          {{- end }}
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
      volumes:
        {{- if ne (include "wandb.redis.caCert" .) "" }}
        - name: {{ include "app.fullname" . }}-redis-ca
          secret:
            secretName: "{{ .Release.Name }}-redis"
            items:
              - key: REDIS_CA_CERT
                path: redis_ca.pem
        {{- end }}
        {{- if .Values.global.caCertsConfigMap }}
        - name: wandb-ca-certs-user
          configMap:
            name: {{ .Values.global.caCertsConfigMap }}
        {{- end }}
        {{- if .Values.global.customCACerts }}
        - name: wandb-ca-certs
          configMap:
            name: {{ include "wandb.fullname" . }}-ca-certs
        {{- end }}
{{- end }}
