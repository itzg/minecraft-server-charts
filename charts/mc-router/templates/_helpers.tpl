{{/*
Expand the name of the chart.
*/}}
{{- define "mc-router.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "mc-router.fullname" -}}
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
{{- define "mc-router.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "mc-router.labels" -}}
helm.sh/chart: {{ include "mc-router.chart" . }}
{{ include "mc-router.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "mc-router.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mc-router.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "mc-router.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "mc-router.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Helper function for environment variables
*/}}
{{- define "mc-router.envMap" -}}
{{- if or (index . 1) (kindIs "float64" (index . 1)) (kindIs "bool" (index . 1)) }}
            - name: {{ index . 0 }}
              value: {{ index . 1 | quote }}
{{- end }}
{{- end }}

{{/*
Helper function for multiline environment variables
*/}}
{{- define "mc-router.envMultilineMap" -}}
{{- if index . 1 }}
            - name: {{ index . 0 }}
              value: |
                {{- index . 1 }}
{{- end }}
{{- end }}

{{/*
Helper function for secret environment variables
*/}}
{{- define "mc-router.envSecretMap" -}}
{{- if index . 1 }}
            - name: {{ index . 0 }}
              valueFrom:
                secretKeyRef:
                  name: {{ index . 1 }}
                  key: {{ index . 2 }}
{{- end }}
{{- end }}

{{/*
Helper function for mappings formatting
*/}}
{{- define "mc-router.formatMappings" -}}
{{- range . }}
                {{ printf "%s=%s:%d" .externalHostname .host (.port | int) }}
{{- end -}}
{{- end }}

{{/*
Helper function for rendering extra resources to deploy
*/}}
{{- define "mc-router.extraDeploy.render" -}}
{{- $value := typeIs "string" .value | ternary .value (.value | toYaml) }}
{{- if contains "{{" (toJson .value) }}
  {{- if .scope }}
      {{- tpl (cat "{{- with $.RelativeScope -}}" $value "{{- end }}") (merge (dict "RelativeScope" .scope) .context) }}
  {{- else }}
    {{- tpl $value .context }}
  {{- end }}
{{- else }}
    {{- $value }}
{{- end }}
{{- end -}}
