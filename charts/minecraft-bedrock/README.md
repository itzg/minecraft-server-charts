# Minecraft

[Minecraft](https://minecraft.net/en/) is a game about placing blocks and going on adventures.

## Introduction

This chart creates a single [Minecraft Bedrock Server](https://www.minecraft.net/en-us/download/server/bedrock/) Pod and a Service for client connections.

## Prerequisites

- 512 MB of RAM
- Kubernetes with `apps/v1` Deployment support
- A PV provisioner or existing PVC when persistence is enabled
- `itzg/minecraft-bedrock-server:2026.9.1` or newer, including `latest`, for
  NetherNet properties and the `mc-monitor --protocol` health checks

## Installing the Chart

To install the chart with the release name `minecraft-bedrock`, read the [Minecraft EULA](https://account.mojang.com/documents/minecraft_eula), then run:

```shell
helm install minecraft-bedrock \
  --set minecraftServer.eula=true itzg/minecraft-bedrock
```

Configure networking and persistence below before using the server.

> **Tip**: List all releases using `helm list`

## Uninstalling the Chart

To uninstall/delete the `minecraft-bedrock` deployment:

```shell
helm delete minecraft-bedrock
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

Refer to [values.yaml](values.yaml) for the full run-down on defaults. These are a mixture of Kubernetes and Minecraft-related directives that map to environment variables in the [itzg/minecraft-bedrock-server](https://hub.docker.com/r/itzg/minecraft-bedrock-server/) Docker image.

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

```shell
helm install minecraft-bedrock \
  --set minecraftServer.eula=true,minecraftServer.difficulty=hard \
  itzg/minecraft-bedrock
```

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart. For example,

```shell
helm install minecraft-bedrock -f values.yaml itzg/minecraft-bedrock
```

> **Tip**: You can use the default [values.yaml](values.yaml)

## Transport and networking

Chart 3.0.0 defaults to `minecraftServer.transport: nethernet`, matching current
Bedrock Dedicated Server releases. NetherNet uses TCP on `serverPort` for HTTP
signaling and a separate UDP range for gameplay. Both protocols must reach the
same server pod. Opening only the signaling port is not sufficient to join.

The chart sets `TRANSPORT`, `SERVER_PORT`, and `SERVER_UDP_PORTS`, exposes matching Service and
container ports, and selects the transport explicitly in readiness, liveness,
and optional startup probes. Configure these through `minecraftServer`, not
`extraEnv`, so the server, Service, and probes use the same settings.

| Value | Default | Purpose |
| --- | --- | --- |
| `minecraftServer.transport` | `nethernet` | `nethernet` or `raknet` |
| `minecraftServer.serverPort` | `19132` | TCP signaling for NetherNet; UDP for RakNet |
| `minecraftServer.nethernet.udpPortStart` | `19140` | First UDP gameplay port in the pod and Service |
| `minecraftServer.nethernet.udpPortEnd` | `19155` | Last UDP gameplay port, inclusive |
| `minecraftServer.nethernet.advertisedAddress` | `""` | IP literal reachable by clients; use unbracketed IPv6 |
| `minecraftServer.nethernet.nodePortStart` | unset | First external UDP NodePort, required for NodePort Services |

For a NodePort Service, the chart assigns consecutive external UDP ports and
advertises that external range while the server binds the internal range.
The configured ports must be available and fall within the cluster's NodePort
range (normally 30000–32767). The signaling NodePort can differ from `serverPort`.
The internal UDP range must not overlap the TCP signaling or SSH ports.
Helm merges port lists by number when upgrading, so overlapping TCP and UDP
port numbers can produce an incorrect patch.

For example, clients can connect to `192.0.2.10:31234` with these values
(replace the example address with the reachable address of your node):

```yaml
minecraftServer:
  transport: nethernet
  serviceType: NodePort
  serverPort: 19132
  nodePort: 31234
  nethernet:
    udpPortStart: 19140
    udpPortEnd: 19155
    nodePortStart: 31240
    advertisedAddress: "192.0.2.10"
```

This sets `SERVER_UDP_PORTS` to `192.0.2.10:31240-31255:19140-19155`.
Allow TCP 31234 and UDP 31240–31255 through the host firewall and any routers or
firewalls between clients and the node. Use a stable address or DHCP reservation.

For a LoadBalancer Service, set `nethernet.advertisedAddress` to the externally
reachable IP and omit `nethernet.nodePortStart`. The advertised UDP ports then
match the Service ports. If the load balancer assigns its IP dynamically, wait
for it to appear and update the release with that address. The load balancer
must support a Service containing both TCP and UDP ports; mixed-protocol
LoadBalancer Services are stable in Kubernetes 1.26 and later, but support also
depends on the load balancer implementation.

With ClusterIP and an empty advertised address, the server advertises its pod
addresses. This is useful only when clients can route to those addresses.
Ordinary HTTP Ingress and `kubectl port-forward` do not carry UDP gameplay.
This chart configures direct server connections, not broadcast LAN discovery.

Test signaling from a client machine with:

```shell
curl http://192.0.2.10:31234/v1/join
```

A JSON response confirms signaling is reachable. Joining from Minecraft is
still required to verify the UDP gameplay path. See the image's
[NetherNet documentation](https://github.com/itzg/docker-minecraft-bedrock-server#nethernet)
for transport and address mapping details.

### Upgrading from chart 2.x

The default Minecraft Service port changes from UDP to TCP and the chart adds
UDP gameplay ports. Set the advertised address and, for NodePort, a UDP
`nodePortStart` before upgrading. Keep your existing release name, persistence
settings, and `levelName` to continue using the same world.

Servers pinned to a Bedrock version that still supports RakNet can retain the
legacy UDP Service by setting `minecraftServer.transport: raknet`. NetherNet
settings are ignored in this mode. A recent container image is still needed
for the health check's `--protocol` option; pin the Bedrock binary separately
with `minecraftServer.version`. Current Bedrock versions require NetherNet.

Move any existing `TRANSPORT`, `SERVER_PORT`, or `SERVER_UDP_PORTS` overrides
from `extraEnv` into the values above. When using `helm upgrade --reuse-values`,
explicitly provide `minecraftServer.transport` and, for NetherNet, the complete
`minecraftServer.nethernet` values. Helm may reuse the old chart defaults.
When reusing chart 2.7.0 values, an absent `startupProbe` leaves that probe disabled,
and an absent `persistence.dataDir.accessModes` retains `ReadWriteOnce`.

## Persistence

The [itzg/minecraft-bedrock-server](https://hub.docker.com/r/itzg/minecraft-bedrock-server/) image stores the saved games and mods under /data.

Persistence is disabled by default. Set `persistence.dataDir.enabled: true` to
create a PersistentVolumeClaim, or also set `persistence.dataDir.existingClaim`
to mount an existing claim. Without persistence, `/data` uses an `emptyDir`
volume and is lost when the Pod is removed.

> *"An emptyDir volume is first created when a Pod is assigned to a Node, and exists as long as that Pod is running on that node. When a Pod is removed from a node for any reason, the data in the emptyDir is deleted forever."*

## Backups

You can backup the state of your minecraft server to your local machine via the `kubectl cp` command.  

```shell
NAMESPACE=default
POD_ID=lionhope-387ff8d-sdis9
kubectl attach --namespace ${NAMESPACE} ${POD_ID} -it
save hold
save query
^P + ^Q (CtrlP and CtrlQ)
kubectl cp ${NAMESPACE}/${POD_ID}:/data .
kubectl attach --namespace ${NAMESPACE} ${POD_ID} -it
save resume
^P + ^Q (CtrlP and CtrlQ)
```
