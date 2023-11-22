# Minecraft

[Minecraft](https://minecraft.net/en/) is a game about placing blocks and going on adventures.

## Introduction

This chart creates a single Minecraft Pod, plus Services for the Minecraft server and RCON.

## Prerequisites

- 512 MB of RAM
- Kubernetes 1.4+ with Beta APIs enabled
- PV provisioner support in the underlying infrastructure

## Installing the Chart

To install the chart with the release name `minecraft`, read the [Minecraft EULA](https://account.mojang.com/documents/minecraft_eula) run:

```shell
helm install minecraft \
  --set minecraftServer.eula=true itzg/minecraft
```

This command deploys a Minecraft dedicated server with sensible defaults.

> **Tip**: List all releases using `helm list`

## Uninstalling the Chart

To uninstall/delete the `minecraft` deployment:

```shell
helm delete minecraft
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

Refer to [values.yaml](values.yaml) for the full run-down on defaults. These are a mixture of Kubernetes and Minecraft-related directives that map to environment variables in the [itzg/minecraft-server](https://hub.docker.com/r/itzg/minecraft-server/) Docker image.

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

```shell
helm install --name minecraft \
  --set minecraftServer.eula=true,minecraftServer.Difficulty=hard \
  itzg/minecraft
```

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart. For example,

```shell
helm install --name minecraft -f values.yaml itzg/minecraft
```

> **Tip**: You can use the default [values.yaml](values.yaml)

## Persistence

The [itzg/minecraft-server](https://hub.docker.com/r/itzg/minecraft-server/) image stores the saved games and mods under /data.

When [persistence.dataDir.enabled in values.yaml](https://github.com/itzg/minecraft-server-charts/blob/master/charts/minecraft/values.yaml#L171) is set to true PersistentVolumeClaim is created and mounted for saves but not mods. In order to enable this functionality
you can change the values.yaml to enable persistence under the sub-sections under `persistence`.

> *"An emptyDir volume is first created when a Pod is assigned to a Node, and exists as long as that Pod is running on that node. When a Pod is removed from a node for any reason, the data in the emptyDir is deleted forever."*

## Backups

You can backup the state of your minecraft server to your local machine via the `kubectl cp` command.

```shell
NAMESPACE=default
POD_ID=lionhope-387ff8d-sdis9
kubectl exec --namespace ${NAMESPACE} ${POD_ID} rcon-cli save-off
kubectl exec --namespace ${NAMESPACE} ${POD_ID} rcon-cli save-all
kubectl cp ${NAMESPACE}/${POD_ID}:/data .
kubectl exec --namespace ${NAMESPACE} ${POD_ID} rcon-cli save-on
```

### Known issues

`rclone` can attempt to update its configuration file when there is data to be
modified, such as missing configuration entries or tokens. As this configuration
file will most likely be stored in a ConfigMap or a Secret, it will be read-only
and the container will generate errors like this one:

``` text
rclone: 2023/11/22 21:41:18 ERROR : Failed to save config after 10 tries: failed to create temp file for new config: open /config/rclone/rclone.conf4086229703: read-only file system
```

In that case, double-check if there are missing entries in your `rclone`
configuration as this might be the reason why `rclone` throws an error. This
might not solve all cases, though.

For more information, see this GitHub
[issue](https://github.com/rclone/rclone/issues/3655)

## Tutorials

For a quickstart guide to setting up a Kubernetes cluster and deploying
Minecraft servers using this Helm Chart see:

[gilesknap/k3s-minecraft](https://github.com/gilesknap/k3s-minecraft)

