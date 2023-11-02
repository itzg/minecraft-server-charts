# Minecraft Router

Routes Minecraft client connections to backend servers based upon the requested
server address.

## Introduction

This chart creates a single `mc-router` Pod, associated Service and permissions.

## Prerequisites

- 16 MB of RAM
- Kubernetes 1.4+
- PV provisioner support in the underlying infrastructure

## Installing the Chart

To install the chart with the release name `mc-router`, run:

```shell
helm install mc-router itzg/mc-router
```

This command deploys a `mc-router` instance with sensible defaults.

> **Tip**: List all releases using `helm list`

## Uninstalling the Chart

To uninstall/delete the `mc-router` deployment:

```shell
helm delete mc-router
```

The command removes all the Kubernetes components associated with the chart and
deletes the release.

## Configuration

Refer to [values.yaml](values.yaml) for the full run-down on defaults. These are
a mixture of Kubernetes and Minecraft Router -related directives that map to
environment variables in the
[itzg/mc-router](https://hub.docker.com/r/itzg/mc-router/) Docker image.

Specify each parameter using the `--set key=value[,key=value]` argument to `helm
install`. For example,

```shell
helm install mc-router \
  --set minecraftRouter.connectionRateLimit=2,minecraftRouter.debug.enabled=true \
  itzg/mc-router
```

Alternatively, a YAML file that specifies the values for the parameters can be
provided while installing the chart. For example,

```shell
helm install mc-router -f values.yaml itzg/mc-router
```

> **Tip**: You can use the default [values.yaml](values.yaml)
