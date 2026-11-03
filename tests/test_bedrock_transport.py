"""Check that Bedrock environment variables, ports, and probes agree.

Run with: python -m unittest discover -s tests -p 'test_bedrock_*.py'
Requires Helm on PATH and PyYAML.
"""

import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

import yaml


CHART = Path(__file__).resolve().parents[1] / "charts" / "minecraft-bedrock"


class BedrockTransportTests(unittest.TestCase):
    def render(self, server=None, chart=CHART, **values):
        values["minecraftServer"] = {"eula": "TRUE", **(server or {})}
        return subprocess.run(
            [os.environ.get("HELM", "helm"), "template", "test", str(chart), "-f", "-"],
            input=json.dumps(values), text=True, capture_output=True, check=False,
        )

    def manifests(self, server=None, **values):
        result = self.render(server, **values)
        self.assertEqual(result.returncode, 0, result.stderr)
        documents = [doc for doc in yaml.safe_load_all(result.stdout) if doc]
        service = next(doc for doc in documents if doc["kind"] == "Service")
        workload = next(doc for doc in documents if doc["kind"] in ("Deployment", "StatefulSet"))
        container = workload["spec"]["template"]["spec"]["containers"][0]
        return service, workload, container

    def assert_transport(self, service, container, transport, startup=False):
        env = {item["name"]: item.get("value") for item in container["env"]}
        self.assertEqual(env["TRANSPORT"], transport)
        self.assertEqual(len(env), len(container["env"]), "Duplicate environment variables")
        probes = ["livenessProbe", "readinessProbe"]
        if startup:
            probes.append("startupProbe")
        else:
            self.assertNotIn("startupProbe", container)
        for probe in probes:
            self.assertEqual(container[probe]["exec"]["command"], [
                "mc-monitor", "status-bedrock", "--protocol", transport,
                "--host", "127.0.0.1", "--port", env["SERVER_PORT"],
            ])
        # Every Service port must resolve to a declared pod port with the same protocol.
        for port in service["spec"]["ports"]:
            target = port["targetPort"]
            self.assertTrue(any(
                (p["name"] == target or p["containerPort"] == target)
                and p["protocol"] == port["protocol"]
                for p in container["ports"]
            ), port)
        return env

    def test_default_nethernet(self):
        service, _, container = self.manifests(startupProbe={"enabled": True})
        env = self.assert_transport(service, container, "nethernet", startup=True)
        self.assertEqual(env["SERVER_UDP_PORTS"], "19140-19155")
        self.assertEqual(service["spec"]["ports"][0]["protocol"], "TCP")
        self.assertEqual(service["spec"]["ports"][0]["port"], 19132)
        self.assertEqual([p["port"] for p in service["spec"]["ports"][1:]], list(range(19140, 19156)))
        self.assertTrue(all(p["protocol"] == "UDP" for p in service["spec"]["ports"][1:]))
        self.assertTrue(all("nodePort" not in p for p in service["spec"]["ports"]))

    def test_nodeport_mapping_uses_external_ports_in_advertisement(self):
        service, _, container = self.manifests({
            "serviceType": "NodePort", "serverPort": 19133, "nodePort": 31234,
            "nethernet": {
                "advertisedAddress": "192.0.2.10", "nodePortStart": 31240,
                "udpPortStart": 20000, "udpPortEnd": 20003,
            },
        }, startupProbe={"enabled": True})
        env = self.assert_transport(service, container, "nethernet", startup=True)
        self.assertEqual(env["SERVER_UDP_PORTS"], "192.0.2.10:31240-31243:20000-20003")
        self.assertEqual(service["spec"]["ports"], [{
            "name": "minecraft", "port": 19133, "targetPort": "minecraft",
            "nodePort": 31234, "protocol": "TCP",
        }] + [{
            "name": f"minecraft-{port}", "port": port, "targetPort": port,
            "nodePort": 31240 + port - 20000, "protocol": "UDP",
        } for port in range(20000, 20004)])

    def test_loadbalancer_and_ssh(self):
        service, _, container = self.manifests({
            "serviceType": "LoadBalancer", "enableSSH": True,
            "nethernet": {"advertisedAddress": "192.0.2.20"},
        })
        env = self.assert_transport(service, container, "nethernet")
        self.assertEqual(env["SERVER_UDP_PORTS"], "192.0.2.20:19140-19155:19140-19155")
        self.assertEqual(service["spec"]["ports"][-1]["name"], "minecraft-ssh")
        self.assertTrue(all("nodePort" not in p for p in service["spec"]["ports"]))

    def test_ipv6_and_single_udp_port(self):
        service, _, container = self.manifests({
            "nethernet": {"advertisedAddress": "2001:db8::1", "udpPortStart": 19140, "udpPortEnd": 19140},
        })
        env = self.assert_transport(service, container, "nethernet")
        self.assertEqual(env["SERVER_UDP_PORTS"], "[2001:db8::1]:19140-19140:19140-19140")
        self.assertEqual(len(service["spec"]["ports"]), 2)

    def test_raknet_retains_udp_service_without_nethernet_ports(self):
        service, _, container = self.manifests({
            "transport": "raknet", "serviceType": "NodePort", "nodePort": 31234,
            "nethernet": None,
        }, startupProbe={"enabled": True})
        env = self.assert_transport(service, container, "raknet", startup=True)
        self.assertNotIn("SERVER_UDP_PORTS", env)
        self.assertEqual(service["spec"]["ports"], [{
            "name": "minecraft", "port": 19132, "targetPort": "minecraft",
            "nodePort": 31234, "protocol": "UDP",
        }])

    def test_restore_mode_has_no_probes(self):
        _, _, container = self.manifests(restoreMode=True, startupProbe={"enabled": True})
        for probe in ("livenessProbe", "readinessProbe", "startupProbe"):
            self.assertNotIn(probe, container)

    def test_upgrade_reusing_chart_2_7_defaults(self):
        # --reuse-values replaces the new chart's defaults with the old values.
        # A normal helm template -f old-values.yaml would merge in new defaults
        # and hide missing-map errors in the upgrade path.
        with tempfile.TemporaryDirectory() as directory:
            chart = Path(directory) / "minecraft-bedrock"
            shutil.copytree(CHART, chart)
            fixture = Path(__file__).parent / "fixtures" / "bedrock-2.7.0-values.yaml"
            shutil.copyfile(fixture, chart / "values.yaml")
            for transport in ("nethernet", "raknet"):
                with self.subTest(transport=transport):
                    server = {
                        "transport": transport, "levelName": "existing-world",
                        "serviceType": "NodePort", "nodePort": 31234,
                    }
                    if transport == "nethernet":
                        example = CHART / "examples" / "nethernet-nodeport-migration.yaml"
                        server.update(yaml.safe_load(example.read_text())["minecraftServer"])
                    result = self.render(server, chart=chart, persistence={
                        "dataDir": {"enabled": True},
                    })
                    self.assertEqual(result.returncode, 0, result.stderr)
                    documents = [doc for doc in yaml.safe_load_all(result.stdout) if doc]
                    service = next(doc for doc in documents if doc["kind"] == "Service")
                    workload = next(doc for doc in documents if doc["kind"] == "Deployment")
                    container = workload["spec"]["template"]["spec"]["containers"][0]
                    env = self.assert_transport(service, container, transport)
                    self.assertEqual(env["LEVEL_NAME"], "existing-world")
                    self.assertEqual(container["imagePullPolicy"], "IfNotPresent")
                    pvc = next(doc for doc in documents if doc["kind"] == "PersistentVolumeClaim")
                    self.assertEqual(pvc["spec"]["accessModes"], ["ReadWriteOnce"])
                    self.assertEqual(pvc["spec"]["resources"]["requests"]["storage"], "1Gi")
                    self.assertIn({"name": "datadir", "persistentVolumeClaim": {
                        "claimName": pvc["metadata"]["name"],
                    }}, workload["spec"]["template"]["spec"]["volumes"])

    def test_statefulset_and_existing_world(self):
        service, workload, container = self.manifests(
            {"levelName": "existing-world"}, workloadAsStatefulSet=True, strategyType="OnDelete",
            persistence={"dataDir": {"enabled": True, "existingClaim": "existing-world-pvc"}},
        )
        env = self.assert_transport(service, container, "nethernet")
        self.assertEqual(workload["kind"], "StatefulSet")
        self.assertEqual(env["LEVEL_NAME"], "existing-world")
        volumes = workload["spec"]["template"]["spec"]["volumes"]
        self.assertIn({"name": "datadir", "persistentVolumeClaim": {"claimName": "existing-world-pvc"}}, volumes)

    def test_invalid_configuration_fails_before_install(self):
        cases = [
            ({"transport": "typo"}, "transport"),
            ({"nethernet": {"udpPortStart": 0}}, "udpPortStart"),
            ({"nethernet": {"udpPortEnd": 65536}}, "udpPortEnd"),
            ({"nethernet": {"udpPortStart": 19140.5}}, "integer"),
            ({"nethernet": {"udpPortStart": 19156}}, "must not exceed"),
            ({"nethernet": {"nodeportStart": 31240}}, "Additional property nodeportStart"),
            ({"nethernet": {"advertisedAddress": "minecraft.example.com"}}, "advertisedAddress"),
            ({"serviceType": "NodePort"}, "nodePortStart is required"),
            ({"serviceType": "NodePort", "nethernet": {"nodePortStart": 31240}}, "advertisedAddress is required"),
            ({"serviceType": "NodePort", "nethernet": {"nodePortStart": 65530, "advertisedAddress": "192.0.2.10"}}, "must end at or below"),
            ({"serviceType": "LoadBalancer", "nethernet": {"nodePortStart": 31240}}, "only used with serviceType"),
        ]
        for server, error in cases:
            with self.subTest(server=server):
                result = self.render(server)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(error, result.stderr)

    def test_overlapping_ports_are_rejected(self):
        cases = [
            ({"serverPort": 19140}, "must not overlap"),
            ({"serverPort": 19155}, "must not overlap"),
            ({"enableSSH": True, "exposedPortSSH": 19140}, "must not overlap"),
            ({"enableSSH": True, "nethernet": {
                "udpPortStart": 2222, "udpPortEnd": 2223,
            }}, "must not overlap"),
            ({"enableSSH": True, "serverPort": 2222}, "different TCP ports"),
            ({"enableSSH": True, "exposedPortSSH": 19132}, "different TCP ports"),
            ({"enableSSH": True, "serviceType": "NodePort", "nodePort": 31234,
              "nodePortSSH": 31234, "nethernet": {
                  "nodePortStart": 31240, "advertisedAddress": "192.0.2.10",
              }}, "different TCP NodePorts"),
        ]
        for server, error in cases:
            with self.subTest(server=server):
                result = self.render(server)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(error, result.stderr)

    def test_env_overrides_cannot_desynchronize_service(self):
        for key, value in (
            ("TRANSPORT", "raknet"), ("SERVER_PORT", "19133"),
            ("SERVER_UDP_PORTS", "20000-20010"),
        ):
            with self.subTest(key=key):
                result = self.render(extraEnv={key: value})
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(f"Configure {key} through minecraftServer, not extraEnv", result.stderr)


if __name__ == "__main__":
    unittest.main()
