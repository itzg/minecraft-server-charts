{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "minecraft.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "minecraft.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "minecraft.ingress.apiVersion" -}}
{{- if semverCompare "<1.14-0" .Capabilities.KubeVersion.Version -}}
{{- print "extensions/v1beta1" -}}
{{- else if semverCompare "<1.19-0" .Capabilities.KubeVersion.Version -}}
{{- print "networking.k8s.io/v1beta1" -}}
{{- else -}}
{{- print "networking.k8s.io/v1" -}}
{{- end }}
{{- end -}}

{{- define "minecraft.extraEnv" }}
{{- range $key, $value := . }}
{{- if kindIs "map" $value }}
{{-   if hasKey $value "valueFrom" }}
- name: {{ $key }}
  valueFrom:
    {{- $value.valueFrom | toYaml | nindent 4 }}
{{-   end }}
{{- else }}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- end }}
{{- end }}
{{- end }}

{{- define "extraDeploy.render" -}}
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
