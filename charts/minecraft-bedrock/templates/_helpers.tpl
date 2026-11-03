{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "minecraft.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Validate settings used to generate both SERVER_UDP_PORTS and Service ports. */}}
{{- define "minecraft.validateTransport" -}}
{{- if or (hasKey .Values.extraEnv "TRANSPORT") (hasKey .Values.extraEnv "SERVER_UDP_PORTS") -}}
  {{- fail "Use minecraftServer.transport and minecraftServer.nethernet instead of extraEnv.TRANSPORT or extraEnv.SERVER_UDP_PORTS so the server and Service ports agree" -}}
{{- end -}}
{{- if eq .Values.minecraftServer.transport "nethernet" -}}
  {{- $nethernet := .Values.minecraftServer.nethernet -}}
  {{- if gt (int $nethernet.udpPortStart) (int $nethernet.udpPortEnd) -}}
    {{- fail "minecraftServer.nethernet.udpPortStart must not exceed udpPortEnd" -}}
  {{- end -}}
  {{- if eq .Values.minecraftServer.serviceType "NodePort" -}}
    {{- if not $nethernet.nodePortStart -}}
      {{- fail "minecraftServer.nethernet.nodePortStart is required for a NetherNet NodePort Service" -}}
    {{- end -}}
    {{- if not $nethernet.advertisedAddress -}}
      {{- fail "minecraftServer.nethernet.advertisedAddress is required for a NetherNet NodePort Service" -}}
    {{- end -}}
    {{- if gt (add (int $nethernet.nodePortStart) (sub (int $nethernet.udpPortEnd) (int $nethernet.udpPortStart))) 65535 -}}
      {{- fail "The NetherNet UDP NodePort range must end at or below 65535" -}}
    {{- end -}}
  {{- else if $nethernet.nodePortStart -}}
    {{- fail "minecraftServer.nethernet.nodePortStart is only used with serviceType: NodePort" -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/* Construct the advertised external:internal UDP mapping, including IPv6 literals. */}}
{{- define "minecraft.serverUdpPorts" -}}
{{- $nethernet := .Values.minecraftServer.nethernet -}}
{{- $internal := printf "%d-%d" (int $nethernet.udpPortStart) (int $nethernet.udpPortEnd) -}}
{{- $external := $internal -}}
{{- if eq .Values.minecraftServer.serviceType "NodePort" -}}
  {{- $external = printf "%d-%d" (int $nethernet.nodePortStart) (int (add (int $nethernet.nodePortStart) (sub (int $nethernet.udpPortEnd) (int $nethernet.udpPortStart)))) -}}
{{- end -}}
{{- if $nethernet.advertisedAddress -}}
  {{- $address := $nethernet.advertisedAddress -}}
  {{- if contains ":" $address -}}
    {{- $address = printf "[%s]" $address -}}
  {{- end -}}
  {{- printf "%s:%s:%s" $address $external $internal -}}
{{- else -}}
  {{- $internal -}}
{{- end -}}
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
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "minecraft.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

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
