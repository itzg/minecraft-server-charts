# Minecraft Bedrock

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

For a new server reachable through a Kubernetes node's LAN address, read the
[Minecraft EULA](https://account.mojang.com/documents/minecraft_eula), then save
the following as `values.yaml`. This is also available as
[examples/nodeport-values.yaml](examples/nodeport-values.yaml).

```yaml
minecraftServer:
  eula: "TRUE"
  serviceType: NodePort
  nodePort: 31234
  nethernet:
    advertisedAddress: "192.0.2.10"
    nodePortStart: 31240

persistence:
  dataDir:
    enabled: true

extraEnv:
  ALLOW_LIST_USERS: "YourGamertag:YOUR_XUID"
```

Replace `192.0.2.10` with a stable node address reachable by your players, and
replace the allowlist entry with each player's gamertag and XUID. Multiple
entries are comma-separated. See the image's
[allowlist documentation](https://github.com/itzg/docker-minecraft-bedrock-server#allowlist).
The example enables persistent world storage and assumes a default storage
class is available. TCP NodePort 31234 and UDP NodePorts 31240–31255 must be
available in your cluster; use different ports if another Service uses them.

```shell
helm repo add itzg https://itzg.github.io/minecraft-server-charts/
helm install minecraft-bedrock itzg/minecraft-bedrock -f values.yaml --wait
```

Connect in Minecraft using the node address and port `31234`. Allow client
traffic to TCP 31234 and UDP 31240–31255 through any intervening firewalls.
The chart supplies the internal ports and generates the UDP mapping.

For a cluster with a load balancer, start with
[examples/loadbalancer-values.yaml](examples/loadbalancer-values.yaml) and the
[LoadBalancer instructions below](#loadbalancer).
Existing installations should follow [Upgrading from chart 2.x](#upgrading-from-chart-2x)
to retain their deployed world and storage settings.

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
helm install minecraft-bedrock itzg/minecraft-bedrock \
  -f values.yaml --set minecraftServer.difficulty=hard
```

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart. For example,

```shell
helm install minecraft-bedrock -f values.yaml itzg/minecraft-bedrock
```

The chart defaults use a ClusterIP Service and disable persistence. The new-server
examples above explicitly configure external access and persistent storage.

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

For a new installation, the networking portion of the NodePort example is:

```yaml
minecraftServer:
  serviceType: NodePort
  nodePort: 31234
  nethernet:
    nodePortStart: 31240
    advertisedAddress: "192.0.2.10"
```

This sets `SERVER_UDP_PORTS` to `192.0.2.10:31240-31255:19140-19155`.
Allow TCP 31234 and UDP 31240–31255 through the host firewall and any routers or
firewalls between clients and the node. Use a stable address or DHCP reservation.

### LoadBalancer

For a LoadBalancer Service, set `nethernet.advertisedAddress` to the externally
reachable IP and omit `nethernet.nodePortStart`. The advertised UDP ports then
match the Service ports. For a reserved IP, configure your load balancer's
reservation settings separately, including any provider-specific annotations
under `serviceAnnotations`. Setting `advertisedAddress` does not reserve an IP.
If the load balancer assigns its IP dynamically, wait for it to appear and update
the release with that address. The load balancer
must support a Service containing both TCP and UDP ports; mixed-protocol
LoadBalancer Services are stable in Kubernetes 1.26 and later, but support also
depends on the load balancer implementation.

### ClusterIP and connection checks

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
UDP gameplay ports. Keep your existing release name, namespace, persistence
settings, and `levelName` to continue using the same world.

For an existing NodePort release, save this as `nethernet-migration.yaml`, or copy
[examples/nethernet-nodeport-migration.yaml](examples/nethernet-nodeport-migration.yaml).
Replace the address and choose an available UDP NodePort range:

```yaml
minecraftServer:
  transport: nethernet
  nethernet:
    udpPortStart: 19140
    udpPortEnd: 19155
    nodePortStart: 31240
    advertisedAddress: "192.0.2.10"
```

Use the existing release name and namespace in these commands:

```shell
helm get values my-server -n minecraft -o yaml > before-nethernet.yaml
helm upgrade my-server itzg/minecraft-bedrock -n minecraft \
  --reuse-values -f nethernet-migration.yaml --wait --timeout 5m
```

The saved file contains Helm configuration, not a world backup. The upgrade
restarts the server and retains its existing values, including the client port.
Allow TCP on that port and UDP on the new range; the example uses UDP 31240–31255.
Then join from Minecraft to check the complete connection.

The complete overlay is intentional: `--reuse-values` can retain old chart
defaults, so it needs the new transport and internal UDP range as well as the
external address and ports.

For an existing LoadBalancer release, omit `nodePortStart` from the overlay and
set `advertisedAddress` to the load balancer's reachable IP. Keep `udpPortStart`
and `udpPortEnd`; clients must reach the same UDP ports on the load balancer.

When joining through an IP address with plain HTTP signaling, Minecraft may show
a trust dialog on the first NetherNet connection, even if you played on the
server before the migration. Check the displayed server details before accepting.
The client remembers the server's identity key, so later connections using the
same key normally do not prompt again. See Mojang's
[NetherNet identity documentation](https://mojang.github.io/bedrock-protocol-docs/guides/nether-net-onboarding-guide/#how-the-client-anchors-trust-https-vs-plaintext-http)
for details.

Servers pinned to a Bedrock version that still supports RakNet can retain the
legacy UDP Service by setting `minecraftServer.transport: raknet`. NetherNet
settings are ignored in this mode. A recent container image is still needed
for the health check's `--protocol` option; pin the Bedrock binary separately
with `minecraftServer.version`. Current Bedrock versions require NetherNet.

If you previously set `TRANSPORT`, `SERVER_PORT`, or `SERVER_UDP_PORTS` in
`extraEnv`, move them to the corresponding `minecraftServer` values. With
`--reuse-values`, remove each old override explicitly, for example by adding
`--set extraEnv.TRANSPORT=null` to the upgrade command.
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
