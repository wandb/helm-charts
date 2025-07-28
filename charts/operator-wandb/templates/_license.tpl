{{- define "wandb.license.name" -}}
{{- default (print "%s-license" .Release.Name) .Values.global.licenseSecret.name }}
{{- end }}

{{- define "wandb.license.key" -}}
{{- default "license" .Values.global.licenseSecret.key }}
{{- end }}

{{- define "wandb.license" -}}
- name: LICENSE
  valueFrom:
    secretKeyRef:
      name: "{{ include "wandb.license.name" . }}"
      key: "{{ include "wandb.license.key" . }}"
- name: GORILLA_LICENSE
  valueFrom:
    secretKeyRef:
      name: "{{ include "wandb.license.name" . }}"
      key: "{{ include "wandb.license.key" . }}"
{{- end }}
