{{- define "yace.config" -}}
apiVersion: v1alpha1
discovery:
  jobs:
    - type: AWS/ElastiCache
      regions:
       {{- range .Values.regions }}
      - {{ . }}
      {{- end }}
      period: 300
      length: 300
      metrics:
        - name: CPUUtilization
          statistics: [Average]
        - name: FreeableMemory
          statistics: [Average]
        - name: NetworkBytesIn
          statistics: [Average]
        - name: NetworkBytesOut
          statistics: [Average]
        - name: NetworkPacketsIn
          statistics: [Average]
        - name: NetworkPacketsOut
          statistics: [Average]
        - name: SwapUsage
          statistics: [Average]
        - name: CPUCreditUsage
          statistics: [Average]
    - type: AWS/RDS
      regions:
        {{- range .Values.regions }}
      - {{ . }}
      {{- end }}
      period: 300
      length: 300
      metrics:
        - name: CPUUtilization
          statistics: [Maximum]
        - name: DatabaseConnections
          statistics: [Sum]
        - name: FreeableMemory
          statistics: [Average]
        - name: FreeStorageSpace
          statistics: [Average]
        - name: ReadThroughput
          statistics: [Average]
        - name: WriteThroughput
          statistics: [Average]
        - name: ReadLatency
          statistics: [Maximum]
        - name: WriteLatency
          statistics: [Maximum]
        - name: ReadIOPS
          statistics: [Average]
        - name: WriteIOPS
          statistics: [Average]
{{- end }}