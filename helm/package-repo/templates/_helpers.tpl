{{/*
Expand the name of the chart.
*/}}
{{- define "package-repo.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "package-repo.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "package-repo.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "package-repo.labels" -}}
helm.sh/chart: {{ include "package-repo.chart" . }}
{{ include "package-repo.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "package-repo.selectorLabels" -}}
app.kubernetes.io/name: {{ include "package-repo.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "package-repo.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "package-repo.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Get the secret name for API keys
*/}}
{{- define "package-repo.secretName" -}}
{{- printf "%s-secrets" (include "package-repo.fullname" .) }}
{{- end }}

{{/*
Get S3 credentials secret name
*/}}
{{- define "package-repo.s3SecretName" -}}
{{- if .Values.config.s3.existingSecret }}
{{- .Values.config.s3.existingSecret }}
{{- else }}
{{- printf "%s-s3" (include "package-repo.fullname" .) }}
{{- end }}
{{- end }}
