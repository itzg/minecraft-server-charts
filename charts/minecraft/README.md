# minecraft

![Version: 3.1.7](https://img.shields.io/badge/Version-3.1.7-informational?style=flat-square) ![AppVersion: SeeValues](https://img.shields.io/badge/AppVersion-SeeValues-informational?style=flat-square)

Minecraft server

**Homepage:** <https://minecraft.net/>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| gtaylor | gtaylor@gc-taylor.com |  |
| billimek | jeff@billimek.com |  |
| itzg | itzgeoff@gmail.com |  |

## Source Code

* <https://github.com/itzg/minecraft-server-charts>

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| deploymentAnnotations | object | `{}` |  |
| extraEnv | object | `{}` |  |
| image | string | `"itzg/minecraft-server"` |  |
| imagePullSecret | string | `""` |  |
| imageTag | string | `"latest"` |  |
| initContainers | list | `[]` |  |
| livenessProbe.failureThreshold | int | `10` |  |
| livenessProbe.initialDelaySeconds | int | `30` |  |
| livenessProbe.periodSeconds | int | `5` |  |
| livenessProbe.successThreshold | int | `1` |  |
| livenessProbe.timeoutSeconds | int | `1` |  |
| minecraftServer.allowNether | bool | `true` |  |
| minecraftServer.announcePlayerAchievements | bool | `true` |  |
| minecraftServer.bukkitDownloadUrl | string | `nil` |  |
| minecraftServer.cfServerMod | string | `nil` |  |
| minecraftServer.difficulty | string | `"easy"` |  |
| minecraftServer.downloadModpackUrl | string | `nil` |  |
| minecraftServer.downloadWorldUrl | string | `nil` |  |
| minecraftServer.enableCommandBlock | bool | `true` |  |
| minecraftServer.eula | string | `"FALSE"` |  |
| minecraftServer.externalIPs | string | `nil` |  |
| minecraftServer.extraPorts | list | `[]` |  |
| minecraftServer.forceReDownload | bool | `false` |  |
| minecraftServer.forcegameMode | bool | `false` |  |
| minecraftServer.forgeInstallerUrl | string | `nil` |  |
| minecraftServer.forgeVersion | string | `nil` |  |
| minecraftServer.ftbLegacyJavaFixer | bool | `false` |  |
| minecraftServer.ftbServerMod | string | `nil` |  |
| minecraftServer.gameMode | string | `"survival"` |  |
| minecraftServer.generateStructures | bool | `true` |  |
| minecraftServer.generatorSettings | string | `nil` |  |
| minecraftServer.hardcore | bool | `false` |  |
| minecraftServer.icon | string | `nil` |  |
| minecraftServer.jvmOpts | string | `""` |  |
| minecraftServer.jvmXXOpts | string | `""` |  |
| minecraftServer.levelSeed | string | `nil` |  |
| minecraftServer.levelType | string | `"DEFAULT"` |  |
| minecraftServer.loadBalancerIP | string | `nil` |  |
| minecraftServer.maxBuildHeight | int | `256` |  |
| minecraftServer.maxPlayers | int | `20` |  |
| minecraftServer.maxTickTime | int | `60000` |  |
| minecraftServer.maxWorldSize | int | `10000` |  |
| minecraftServer.memory | string | `"1024M"` |  |
| minecraftServer.motd | string | `"Welcome to Minecraft on Kubernetes!"` |  |
| minecraftServer.onlineMode | bool | `true` |  |
| minecraftServer.ops | string | `nil` |  |
| minecraftServer.paperDownloadUrl | string | `nil` |  |
| minecraftServer.pvp | bool | `false` |  |
| minecraftServer.query.enabled | bool | `false` |  |
| minecraftServer.query.port | int | `25565` |  |
| minecraftServer.rcon.enabled | bool | `false` |  |
| minecraftServer.rcon.existingSecret | string | `nil` |  |
| minecraftServer.rcon.loadBalancerIP | string | `nil` |  |
| minecraftServer.rcon.password | string | `"CHANGEME!"` |  |
| minecraftServer.rcon.port | int | `25575` |  |
| minecraftServer.rcon.secretKey | string | `"rcon-password"` |  |
| minecraftServer.rcon.serviceType | string | `"LoadBalancer"` |  |
| minecraftServer.removeOldMods | bool | `false` |  |
| minecraftServer.serviceAnnotations | object | `{}` |  |
| minecraftServer.servicePort | int | `25565` |  |
| minecraftServer.serviceType | string | `"ClusterIP"` |  |
| minecraftServer.spawnAnimals | bool | `true` |  |
| minecraftServer.spawnMonsters | bool | `true` |  |
| minecraftServer.spawnNPCs | bool | `true` |  |
| minecraftServer.spigotDownloadUrl | string | `nil` |  |
| minecraftServer.spongeVersion | string | `nil` |  |
| minecraftServer.type | string | `"VANILLA"` |  |
| minecraftServer.version | string | `"LATEST"` |  |
| minecraftServer.viewDistance | int | `10` |  |
| minecraftServer.whitelist | string | `nil` |  |
| minecraftServer.worldSaveName | string | `"world"` |  |
| nodeSelector | object | `{}` |  |
| persistence.annotations | object | `{}` |  |
| persistence.dataDir.Size | string | `"1Gi"` |  |
| persistence.dataDir.enabled | bool | `false` |  |
| podAnnotations | object | `{}` |  |
| rconServiceAnnotations | object | `{}` |  |
| readinessProbe.failureThreshold | int | `10` |  |
| readinessProbe.initialDelaySeconds | int | `30` |  |
| readinessProbe.periodSeconds | int | `5` |  |
| readinessProbe.successThreshold | int | `1` |  |
| readinessProbe.timeoutSeconds | int | `1` |  |
| resources.requests.cpu | string | `"500m"` |  |
| resources.requests.memory | string | `"512Mi"` |  |
| securityContext.fsGroup | int | `2000` |  |
| securityContext.runAsUser | int | `1000` |  |
| serviceAnnotations | object | `{}` |  |
| startupProbe.enabled | bool | `false` |  |
| startupProbe.failureThreshold | int | `30` |  |
| startupProbe.periodSeconds | int | `10` |  |
| strategyType | string | `"Recreate"` |  |
| tolerations | list | `[]` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.5.0](https://github.com/norwoodj/helm-docs/releases/v1.5.0)
