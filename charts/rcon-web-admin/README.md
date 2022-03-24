# RCON Web Admin

RCON Web Admin is a powerful web interface to control your RCON servers. All servers with RCON support should work.

This application can install and run on a server, Raspberry Pi, or other devices which are online 24/7.

Out of the box, RCON Web Admin can check users for high ping, VAC status, or filter the chat for you around the clock.

## Introduction

This chart creates a single RCON Web Admin Pod, plus Services for HTTP and WebSocket traffic.

## Prerequisites

- 512 MB of RAM
- Kubernetes 1.4+ with Beta APIs enabled
- Ingress Controller or Load Balancer available on Kubernetes cluster

## Installing the Chart

To install the chart with the release name `rcon-web` and expose it through load balancer, run:

```shell
helm install \
  --set rconWeb.password=admin_password,service.type=LoadBalancer \
  rcon-web itzg/rcon-web-admin
```

This command deploys a RCON Web Admin dedicated server with sensible defaults.

> **Tip**: List all releases using `helm list`

## Uninstalling the Chart

To uninstall/delete the `rcon-web` deployment:

```shell
helm delete rcon-web
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

Refer to [values.yaml](values.yaml) for the full run-down on defaults. These are a mixture of Kubernetes and RCON-related directives that map to environment variables in the [itzg/rcon](https://hub.docker.com/r/itzg/rcon/) Docker image.

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

```shell
helm install \
  --set rconWeb.password=admin_password,rconWeb.serverName=minecraft_survival \
  rcon-web itzg/rcon-web-admin
```

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart. For example,

```shell
helm install -f values.yaml rcon-web itzg/rcon-web-admin
```

> **Tip**: You can use the default [values.yaml](values.yaml)
