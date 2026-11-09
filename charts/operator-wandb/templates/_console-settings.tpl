{{/* Console creates and owns this Secret; the chart only references it. */}}
{{- define "wandb.consoleSettings.secretName" -}}
  {{- printf "%s-console-settings" .Release.Name -}}
{{- end -}}

{{/* Listed after the other envFromTpls so these keys override earlier envFrom
sources. Optional so pods start before Console has created the Secret.
*/}}
{{- define "wandb.consoleSettings.envFrom" -}}
- secretRef:
    name: {{ include "wandb.consoleSettings.secretName" . | quote }}
    optional: true
{{- end -}}
