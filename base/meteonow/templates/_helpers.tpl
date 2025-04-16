{{- define "meteonow.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "meteonow.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "meteonow.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}


{{/*
Return a component name: <release-name>-<component>
Usage: {{ include "meteonow.componentname" (dict "name" "svc" "releaseName" .Release.Name) }}
*/}}
{{- define "meteonow.componentname" -}}
{{- printf "%s-%s" .releaseName .name | trunc 63 | trimSuffix "-" -}}
{{- end -}}



{{/* Return the service account name */}}
{{- define "meteonow.serviceAccountName" }}{{- if .Values.serviceAccount.name }}{{ .Values.serviceAccount.name }}{{- else }}{{ include "meteonow.fullname" . }}{{- end }}{{- end }}
