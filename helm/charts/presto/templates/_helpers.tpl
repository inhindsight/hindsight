{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "presto.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a fully qualified presto name.
*/}}
{{- define "presto.fullname" -}}
{{- if .Values.presto.fullnameOverride -}}
{{- .Values.presto.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s-%s" .Release.Name "hindsight" "presto" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Create a fully qualified metastore name.
*/}}
{{- define "presto.metastore.fullname" -}}
{{- if .Values.metastore.fullnameOverride -}}
{{- .Values.metastore.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s-%s" .Release.Name "hindsight" "metastore" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Create a fully qualified hive name.
*/}}
{{- define "presto.hive.fullname" -}}
{{- if .Values.hive.fullnameOverride -}}
{{- .Values.hive.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s-%s" .Release.Name "hindsight" "hive" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Create a fully qualified postgres name.
*/}}
{{- define "presto.postgres.fullname" -}}
{{- if .Values.postgres.fullnameOverride -}}
{{- .Values.postgres.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s-%s" .Release.Name "hindsight" "postgres" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}


{{/*
Create a fully qualified minio name.
*/}}
{{- define "presto.minio.fullname" -}}
{{- printf "%s-%s-%s" .Release.Name "hindsight" "minio" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create the name of the service account to use for the platform
*/}}
{{- define "presto.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "presto.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create a common label block
*/}}
{{- define "presto.labels" -}}
chart: {{ .Chart.Name }}-{{ .Chart.Version }}
release: {{ .Release.Name }}
source: helm
{{- end -}}
