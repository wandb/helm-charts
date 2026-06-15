{{- define "otel.podTemplate" }}
    metadata:
      labels:
        {{- include "otel.commonLabels" . | nindent 8 }}
        {{- include "otel.podLabels" . | nindent 8 }}
        {{- include "otel.labels" . | nindent 8 }}
      annotations:
        checksum/configmap: {{ include (print .Template.BasePath "/configmap.yaml") . | sha256sum | trunc 63 }}
        {{- if .Values.pod.annotations }}
        {{-   toYaml .Values.pod.annotations | nindent 8 }}
        {{- end }}
    spec:
      serviceAccountName: {{ include "otel.serviceAccountName" . }}
      {{- if .Values.tolerations }}
      tolerations:
        {{- toYaml .Values.tolerations | nindent 8 }}
      {{- end }}
      {{- include "orchestrator.nodeSelector" . | nindent 6 }}
      {{- include "orchestrator.priorityClassName" . | nindent 6 }}
      {{- include "orchestrator.podSecurityContext" .Values.pod.securityContext | nindent 6 }}
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          command:
            - /otelcol-contrib
            - --config=/conf/config.yaml
          ports:
            - name: otlp
              containerPort: 4317
              protocol: TCP
            - name: otlp-http
              containerPort: 4318
              protocol: TCP
            - name: prometheus
              containerPort: 9109
              protocol: TCP
            - name: statsd
              containerPort: 8125
              protocol: TCP
          env:
            - name: K8S_NODE_NAME
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
            - name: POD_IP
              valueFrom:
                fieldRef:
                  apiVersion: v1
                  fieldPath: status.podIP
            {{- range $name, $ref := .Values.extraEnvFrom }}
            - name: {{ $name }}
              valueFrom:
                {{- toYaml $ref | nindent 16 }}
            {{- end }}
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
          volumeMounts:
            - mountPath: /conf
              name: config
      volumes:
        - name: config
          configMap:
            name: {{ include "otel.fullname" . }}
            items:
              - key: config
                path: config.yaml
      hostNetwork: false
{{- end }}
