{{/* Validate settings used to generate both SERVER_UDP_PORTS and Service ports. */}}
{{- define "minecraft-bedrock.validateTransport" -}}
{{- range $key := list "TRANSPORT" "SERVER_PORT" "SERVER_UDP_PORTS" -}}
  {{- if hasKey $.Values.extraEnv $key -}}
    {{- fail (printf "Configure %s through minecraftServer, not extraEnv, so the server and Service ports agree" $key) -}}
  {{- end -}}
{{- end -}}
{{- if eq .Values.minecraftServer.transport "nethernet" -}}
  {{- $server := .Values.minecraftServer -}}
  {{- $nethernet := .Values.minecraftServer.nethernet -}}
  {{- $start := int $nethernet.udpPortStart -}}
  {{- $end := int $nethernet.udpPortEnd -}}
  {{- if gt $start $end -}}
    {{- fail "minecraftServer.nethernet.udpPortStart must not exceed udpPortEnd" -}}
  {{- end -}}
  {{/* Strategic merge patches identify ports by number, without the protocol. */}}
  {{- $tcpPorts := list (int $server.serverPort) -}}
  {{- if $server.enableSSH -}}
    {{- $sshPort := int (default 2222 $server.exposedPortSSH) -}}
    {{- if or (eq (int $server.serverPort) 2222) (eq (int $server.serverPort) $sshPort) -}}
      {{- fail "NetherNet signaling and SSH must use different TCP ports" -}}
    {{- end -}}
    {{- if and $server.nodePort $server.nodePortSSH (eq (int $server.nodePort) (int $server.nodePortSSH)) -}}
      {{- fail "NetherNet signaling and SSH must use different TCP NodePorts" -}}
    {{- end -}}
    {{- $tcpPorts = append (append $tcpPorts 2222) $sshPort -}}
  {{- end -}}
  {{- range $port := $tcpPorts -}}
    {{- if and (ge $port $start) (le $port $end) -}}
      {{- fail "The NetherNet UDP range must not overlap TCP signaling or SSH ports; Helm merges port lists by number" -}}
    {{- end -}}
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
{{- define "minecraft-bedrock.serverUdpPorts" -}}
{{- $nethernet := .Values.minecraftServer.nethernet -}}
{{- $internal := printf "%d-%d" (int $nethernet.udpPortStart) (int $nethernet.udpPortEnd) -}}
{{- $external := $internal -}}
{{- if eq .Values.minecraftServer.serviceType "NodePort" -}}
  {{- $offset := sub (int $nethernet.udpPortEnd) (int $nethernet.udpPortStart) -}}
  {{- $lastNodePort := add (int $nethernet.nodePortStart) $offset -}}
  {{- $external = printf "%d-%d" (int $nethernet.nodePortStart) (int $lastNodePort) -}}
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

{{/* Keep all probes on the same transport and local server port. */}}
{{- define "minecraft-bedrock.probeCommand" -}}
- mc-monitor
- status-bedrock
- --protocol
- {{ .Values.minecraftServer.transport | quote }}
- --host
- 127.0.0.1
- --port
- {{ .Values.minecraftServer.serverPort | quote }}
{{- end -}}
