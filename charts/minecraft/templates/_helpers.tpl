{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "minecraft.name" -}}
{{- $nameOverride := (and .Values (get .Values "nameOverride")) }}
{{- default .Chart.Name $nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Set the chart fullname
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the labels spec).
We change "+" with "_" for OCI compatibility
*/}}
{{- define "chart.fullname" -}}
{{- printf "%s-%s" .Chart.Name (.Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-") -}}
{{- end }}

{{/*
Set the chart version
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the labels spec).
We change "+" with "_" for OCI compatibility
*/}}
{{- define "chart.version" -}}
{{- default .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "minecraft.fullname" -}}
{{- if and .Values (hasKey .Values "fullnameOverride") .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name (and .Values (get .Values "nameOverride")) }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "minecraft.ingress.apiVersion" -}}
{{- if semverCompare "<1.14-0" .Capabilities.KubeVersion.Version -}}
{{- print "extensions/v1beta1" -}}
{{- else if semverCompare "<1.19-0" .Capabilities.KubeVersion.Version -}}
{{- print "networking.k8s.io/v1beta1" -}}
{{- else -}}
{{- print "networking.k8s.io/v1" -}}
{{- end }}
{{- end -}}

{{- define "minecraft.envMap" }}
{{- if ne (toString (index . 1)) "default" }}
{{- if or (index . 1) (kindIs "float64" (index . 1)) (kindIs "bool" (index . 1)) }}
        - name: {{ index . 0 }}
          value: {{ index . 1 | quote }}
{{- end }}
{{- end }}
{{- end }}

{{- define "tplRender" -}}
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

{{- define "isResticWithRclone" -}}
{{- if .Values.mcbackup -}}
{{-   if and (eq .Values.mcbackup.backupMethod "restic") (hasPrefix "rclone" .Values.mcbackup.resticRepository) }}
{{-   printf "true" }}
{{-   else }}
{{-   printf "false" }}
{{-   end }}
{{- end }}
{{- end -}}
