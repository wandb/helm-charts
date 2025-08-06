{{- define "wandb-base.pod" }}
metadata:
  {{- if or .podData.podAnnotations .podData.podAnnotationsTpls }}
  annotations:
    {{- range .podData.podAnnotationsTpls }}
      {{- tpl . $.root | nindent 4 }}
    {{- end }}
    {{- if .podData.podAnnotations }}
      {{- tpl (toYaml .podData.podAnnotations | nindent 4) .root }}
    {{- end }}
    {{- tpl (include "wandb-base.podAnnotations" $.root | nindent 4) .root }}
  {{- end }}
  labels:
    {{- tpl (include "wandb-base.labels" $.root | nindent 4) $.root }}
    {{- with .podData.podLabels }}
    {{- tpl (toYaml . | nindent 4) $.root }}
    {{- end }}
spec:
  {{- with .podData.affinity }}
  affinity:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  containers:
    {{- include "wandb-base.containers" (dict "containers" .podData.containers "root" $.root "source" "containers") | nindent 4 }}
  {{- $combinedSecrets := concat (default list $.root.Values.imagePullSecrets) (default list $.root.Values.global.imagePullSecrets) }}
  {{- $secretNames := list }}
  {{- range $secret := $combinedSecrets }}
    {{- if kindIs "string" $secret }}
      {{- $secretNames = append $secretNames $secret }}
    {{- else if kindIs "map" $secret }}
      {{- if hasKey $secret "name" }}
        {{- $secretNames = append $secretNames $secret.name }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- $uniqueSecretNames := uniq (compact $secretNames) }}
  {{- if $uniqueSecretNames }}
  imagePullSecrets:
    {{- range $name := $uniqueSecretNames }}
    - name: {{ tpl $name $.root }}
    {{- end }}
  {{- end }}
  {{- if .podData.initContainers }}
  initContainers:
    {{- include "wandb-base.containers" (dict "containers" .podData.initContainers "root" $.root "source" "initContainers") | nindent 4 }}
  {{- end }}
  {{- with .podData.nodeSelector }}
  nodeSelector:
    {{- tpl (toYaml . | nindent 4) $.root }}
  {{- end }}
  {{- if .podData.restartPolicy }}
  restartPolicy: {{ .podData.restartPolicy }}
  {{- end }}
  serviceAccountName: {{ include "wandb-base.serviceAccountName" $.root }}
  securityContext:
   {{- tpl (toYaml .podData.podSecurityContext | nindent 4) $.root }}
  {{- with .podData.terminationGracePeriodSeconds }}
  terminationGracePeriodSeconds: {{ . }}
  {{- end }}
  {{- with .podData.tolerations }}
  tolerations:
    {{- tpl (toYaml . | nindent 4) $.root }}
  {{- end }}
  topologySpreadConstraints:
    {{- include "wandb-base.topologySpreadConstraints" $.root | nindent 4 }}
  {{- if or .podData.volumes .podData.volumesTpls  }}
  volumes:
    {{- range .podData.volumesTpls }}
    {{- tpl . $.root | nindent 4 }}
    {{- end }}
    {{- if $.root.Values.volumes }}
    {{- tpl (toYaml $.root.Values.volumes | nindent 4) $.root }}
    {{- end }}
  {{- end }}
{{ end }}