{{- define "dapr-agents.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "dapr-agents.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{ include "dapr-agents.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "dapr-agents.selectorLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "dapr-agents.redis-host" -}}
{{ printf "%s.%s.svc.cluster.local:6379" .Values.redisConfig.serviceName .Release.Namespace }}
{{- end -}}

{{- define "dapr-agents.state-redis-spec" -}}
type: state.redis
version: v1
metadata:
- name: redisHost
  value: {{ include "dapr-agents.redis-host" . }}
- name: redisPassword
  secretKeyRef:
    name: {{ .Values.redisConfig.passwordSecret.name }}
    key: {{ .Values.redisConfig.passwordSecret.key }}
{{- end -}}
