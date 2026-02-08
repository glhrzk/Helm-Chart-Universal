{{/*
Expand the name of the chart.
*/}}
{{- define "app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "app.fullname" -}}
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
{{- define "app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "app.labels" -}}
helm.sh/chart: {{ include "app.chart" . }}
{{ include "app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/mode: {{ .Values.mode }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "app.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "app.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the ConfigMap to use
*/}}
{{- define "app.configMapName" -}}
{{- if .Values.configMap.name }}
{{- .Values.configMap.name }}
{{- else }}
{{- include "app.fullname" . }}
{{- end }}
{{- end }}

{{/*
Create the name of the Secret to use
*/}}
{{- define "app.secretName" -}}
{{- if .Values.secret.name }}
{{- .Values.secret.name }}
{{- else }}
{{- include "app.fullname" . }}
{{- end }}
{{- end }}

{{/*
Return the proper image name
*/}}
{{- define "app.image" -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion -}}
{{- if $tag -}}
{{- printf "%s:%s" .Values.image.repository $tag -}}
{{- else -}}
{{- .Values.image.repository -}}
{{- end -}}
{{- end }}

{{/*
Return the proper container ports
*/}}
{{- define "app.containerPort" -}}
{{- if .Values.service.targetPort }}
{{- .Values.service.targetPort }}
{{- else }}
{{- .Values.service.port }}
{{- end }}
{{- end }}

{{/*
Check if deployment should be created (http or worker mode)
*/}}
{{- define "app.isDeployment" -}}
{{- or (eq .Values.mode "http") (eq .Values.mode "worker") -}}
{{- end }}

{{/*
Check if service should be created (http mode only)
*/}}
{{- define "app.isServiceEnabled" -}}
{{- and (eq .Values.mode "http") .Values.service.enabled -}}
{{- end }}

{{/*
Check if cronjob should be created
*/}}
{{- define "app.isCronJob" -}}
{{- eq .Values.mode "cron" -}}
{{- end }}

{{/*
Check if job should be created
*/}}
{{- define "app.isJob" -}}
{{- eq .Values.mode "job" -}}
{{- end }}

{{/*
Common pod template spec
*/}}
{{- define "app.podTemplate" -}}
metadata:
  {{- with .Values.podAnnotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  labels:
    {{- include "app.selectorLabels" . | nindent 4 }}
spec:
  {{- if .Values.imagePullSecrets }}
  imagePullSecrets:
  {{- if kindIs "string" .Values.imagePullSecrets }}
  - name: {{ .Values.imagePullSecrets | quote }}
  {{- else if kindIs "slice" .Values.imagePullSecrets }}
  {{- range .Values.imagePullSecrets }}
  {{- if kindIs "string" . }}
  - name: {{ . | quote }}
  {{- else }}
  {{ toYaml . | indent 2 }}
  {{- end }}
  {{- end }}
  {{- else }}
  {{ toYaml .Values.imagePullSecrets | indent 2 }}
  {{- end }}
  {{- end }}
  serviceAccountName: {{ include "app.serviceAccountName" . }}
  securityContext:
    {{- toYaml .Values.podSecurityContext | nindent 4 }}
  {{- with .Values.initContainers }}
  initContainers:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  containers:
    - name: {{ .Chart.Name }}
      securityContext:
        {{- toYaml .Values.securityContext | nindent 8 }}
      image: {{ include "app.image" . }}
      imagePullPolicy: {{ .Values.image.pullPolicy }}
      {{- with .Values.command }}
      command:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.args }}
      args:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- if eq .Values.mode "http" }}
      ports:
        - name: http
          containerPort: {{ include "app.containerPort" . }}
          protocol: TCP
      {{- end }}
      {{- if and (eq .Values.mode "http") .Values.livenessProbe.enabled }}
      livenessProbe:
        {{- omit .Values.livenessProbe "enabled" | toYaml | nindent 8 }}
      {{- end }}
      {{- if and (eq .Values.mode "http") .Values.readinessProbe.enabled }}
      readinessProbe:
        {{- omit .Values.readinessProbe "enabled" | toYaml | nindent 8 }}
      {{- end }}
      {{- if and (eq .Values.mode "http") .Values.startupProbe.enabled }}
      startupProbe:
        {{- omit .Values.startupProbe "enabled" | toYaml | nindent 8 }}
      {{- end }}
      resources:
        {{- toYaml .Values.resources | nindent 8 }}
      {{- with .Values.env }}
      env:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.envFrom }}
      envFrom:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.volumeMounts }}
      volumeMounts:
        {{- toYaml . | nindent 8 }}
      {{- end }}
    {{- with .Values.sidecars }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- with .Values.volumes }}
  volumes:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .Values.nodeSelector }}
  nodeSelector:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .Values.affinity }}
  affinity:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .Values.tolerations }}
  tolerations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end }}
