# minecraft-server-charts

[![](https://github.com/itzg/minecraft-server-charts/workflows/Release%20Charts/badge.svg?branch=master)](https://github.com/itzg/minecraft-server-charts/actions)

## Usage

[Helm](https://helm.sh) must be installed to use the charts.
Please refer to Helm's [documentation](https://helm.sh/docs/) to get started.

Once Helm is set up properly, add the repo as follows:

```console
helm repo add itzg https://itzg.github.io/minecraft-server-charts/
```

You can then run `helm search repo itzg` to see the charts.

## Charts

* [minecraft](https://itzg.github.io/minecraft-server-charts)

```bash
helm install --name your-release itzg/minecraft
```

Also see [helm hub](https://hub.helm.sh/charts/itzg) for a complete list.
