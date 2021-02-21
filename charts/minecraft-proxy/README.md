# Minecraft Proxy

[Minecraft](https://minecraft.net/en/) proxies allows for a single server to become a network of seamlessly integrated servers.

[BungeeCord](https://www.spigotmc.org/wiki/about-bungeecord/) is the most well known solution in this arena, but [several](https://github.com/PaperMC/Waterfall) [other](https://github.com/PaperMC/Travertine) forks of BungeeCord and new projects such as [Velocity](https://velocitypowered.com/) have become popular choices.

This chart relies on the [itzg/bungeecord](https://hub.docker.com/r/itzg/bungeecord) container which supports BungeeCord, Waterfall, and Velocity out of the box. It is also designed to allow the use of any other custom proxies with some additional configuration.

## Introduction

This chart creates a single Proxy Pod, Services for the BungeeCord, server and RCON.

## Prerequisites

- 512 MB of RAM
- Kubernetes 1.4+ with Beta APIs enabled
- PV provisioner support in the underlying infrastructure

## Configuration

Refer to [values.yaml](values.yaml) for the full run-down on defaults. These are a mixture of Kubernetes and BungeeCord-related directives that map to environment variables in the [itzg/bungeecord](https://hub.docker.com/r/itzg/bungeecord/) Docker image.

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. 

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart.

> **Tip**: You can use the default [values.yaml](values.yaml)

## Persistence

The [itzg/bungeecord](https://hub.docker.com/r/itzg/bungeecord/) image stores config and state under `/server`.

When [persistence.dataDir.enabled in values.yaml](https://github.com/ArchitectSMP/charts/blob/main/bungee/values.yaml#L180) is set to true PersistentVolumeClaim is created and mounted. In order to enable this functionality
you can change the values.yaml to enable persistence under the sub-sections under `persistence`.
The config file for the server can be added to the persistent volume manually, or optionally, you can set it by amending the config file path (if your proxy type has a different config path) and pasting your config under [bungeecord.configFilePath and bungeeCord.config in values.yaml](https://github.com/ArchitectSMP/charts/blob/main/bungee/values.yaml#L103).

> *"If persistence is not enabled, an emptyDir volume is first created when a Pod is assigned to a Node, and exists as long as that Pod is running on that node. When a Pod is removed from a node for any reason, the data in the emptyDir is deleted forever."*
