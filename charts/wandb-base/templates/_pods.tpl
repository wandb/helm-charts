{{- define "wandb-base.pod" }}
metadata:
  {{- if or .podData.podAnnotations .podData.podAnnotationsTpls (include "wandb-base.podAnnotations" $.root) (include "wandb-base.commonAnnotations" $.root) }}
  annotations:
    {{- range .podData.podAnnotationsTpls }}
      {{- tpl . $.root | nindent 4 }}
    {{- end }}
    {{- if .podData.podAnnotations }}
      {{- tpl (toYaml .podData.podAnnotations | nindent 4) .root }}
    {{- end }}
    {{- tpl (include "wandb-base.podAnnotations" $.root | nindent 4) .root }}
    {{- tpl (include "wandb-base.commonAnnotations" $.root | nindent 4) .root }}
  {{- end }}
  labels:
    {{- tpl (include "wandb-base.labels" $.root | nindent 4) $.root }}
    {{- tpl (include "wandb-base.podLabels" $.root | nindent 4) $.root }}
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
  {{- $nodeSelector := coalesce .podData.nodeSelector $.root.Values.nodeSelector $.root.Values.global.nodeSelector -}}
  {{- if $nodeSelector }}
  nodeSelector:
    {{- tpl (toYaml $nodeSelector | nindent 4) $.root }}
  {{- end }}
  {{- if .podData.restartPolicy }}
  restartPolicy: {{ .podData.restartPolicy }}
  {{- end }}
  {{- $priorityClassName := coalesce .podData.priorityClassName $.root.Values.priorityClassName $.root.Values.global.priorityClassName -}}
  {{- if $priorityClassName }}
  priorityClassName: {{ tpl $priorityClassName $.root }}
  {{- end }}
  serviceAccountName: {{ include "wandb-base.serviceAccountName" $.root }}
  securityContext:
   {{- tpl (toYaml (merge (default dict .podData.podSecurityContext) $.root.Values.podSecurityContext) | nindent 4) $.root }}
  {{- with .podData.terminationGracePeriodSeconds }}
  terminationGracePeriodSeconds: {{ . }}
  {{- end }}
  {{- $tolerations := coalesce .podData.tolerations $.root.Values.tolerations $.root.Values.global.tolerations -}}
  {{- if $tolerations }}
  tolerations:
    {{- tpl (toYaml $tolerations | nindent 4) $.root }}
  {{- end }}
  topologySpreadConstraints:
    {{- include "wandb-base.topologySpreadConstraints" $.root | nindent 4 }}
  {{- $localVolumes := default list .podData.volumes }}
  {{- $globalVolumes := default list $.root.Values.global.volumes }}
  {{- $localVolumeTpls := default list .podData.volumesTpls }}
  {{- $globalVolumeTpls := default list $.root.Values.global.volumesTpls }}
  {{- $volumeNames := list }}
  {{- $combinedVolumes := list }}
  {{- range $volume := $localVolumes }}
    {{- $combinedVolumes = append $combinedVolumes $volume }}
    {{- if and (kindIs "map" $volume) (hasKey $volume "name") }}
      {{- $volumeNames = append $volumeNames $volume.name }}
    {{- end }}
  {{- end }}
  {{- range $volume := $globalVolumes }}
    {{- if and (kindIs "map" $volume) (hasKey $volume "name") }}
      {{- if not (has $volume.name $volumeNames) }}
        {{- $combinedVolumes = append $combinedVolumes $volume }}
        {{- $volumeNames = append $volumeNames $volume.name }}
      {{- end }}
    {{- else }}
      {{- $combinedVolumes = append $combinedVolumes $volume }}
    {{- end }}
  {{- end }}
  {{- $combinedVolumeTpls := concat $localVolumeTpls $globalVolumeTpls }}
  {{- if or $combinedVolumes $combinedVolumeTpls }}
  volumes:
    {{- range $combinedVolumeTpls }}
    {{- tpl . $.root | nindent 4 }}
    {{- end }}
    {{- if $combinedVolumes }}
    {{- tpl (toYaml $combinedVolumes | nindent 4) $.root }}
    {{- end }}
  {{- end }}
{{ end }}
