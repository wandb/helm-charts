{{- define "wandb.sessionKeyEnvs" -}}
  {{- with .Values.global.auth.sessionKey }}
- name: GORILLA_SESSION_KEY
    {{- if kindIs "map" . }}
{{- toYaml . | nindent 2 }}
    {{- else }}
  value: {{ . | toString | quote }}
    {{- end }}
  {{- end }}
  {{- with .Values.global.auth.sessionKeyPrevious }}
- name: GORILLA_SESSION_KEY_PREVIOUS
    {{- if kindIs "map" . }}
{{- toYaml . | nindent 2 }}
    {{- else }}
  value: {{ . | toString | quote }}
    {{- end }}
  {{- end }}
  {{- $rotation := .Values.global.auth.sessionKeyRotation -}}
  {{- if and $rotation.id $rotation.phase }}
- name: WANDB_SESSION_KEY_ROTATION
  value: {{ printf "%s-%s" $rotation.id $rotation.phase | quote }}
  {{- end }}
  {{- with .Values.global.auth.sessionKeyRolloutId }}
- name: WANDB_SESSION_KEY_ROLLOUT
  value: {{ . | toString | quote }}
  {{- end }}
{{- end -}}
