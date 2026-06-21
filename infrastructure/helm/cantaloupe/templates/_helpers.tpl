{{/*
Expand the name of the chart.
*/}}
{{- define "cantaloupe.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "cantaloupe.fullname" -}}
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
{{- define "cantaloupe.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "cantaloupe.labels" -}}
helm.sh/chart: {{ include "cantaloupe.chart" . }}
{{ include "cantaloupe.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/part-of: almadar-platform
app.kubernetes.io/environment: {{ .Values.environment | quote }}
{{- end }}

{{/*
Selector labels.
*/}}
{{- define "cantaloupe.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cantaloupe.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use.
*/}}
{{- define "cantaloupe.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "cantaloupe.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the cache PVC name.
*/}}
{{- define "cantaloupe.cacheClaimName" -}}
{{- if .Values.persistence.existingClaim }}
{{- .Values.persistence.existingClaim }}
{{- else }}
{{- printf "%s-cache" (include "cantaloupe.fullname" .) }}
{{- end }}
{{- end }}
