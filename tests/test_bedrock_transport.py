"""Render the Bedrock chart and check the client-to-server transport contract.

Run with: python -m unittest discover -s tests -p 'test_bedrock_*.py'
Requires Helm on PATH and PyYAML.
"""

import json
import os
from pathlib import Path
import subprocess
import unittest

import yaml


CHART = Path(__file__).resolve().parents[1] / "charts" / "minecraft-bedrock"


class BedrockTransportTests(unittest.TestCase):
    def render(self, server=None, **values):
        values["minecraftServer"] = {"eula": "TRUE", **(server or {})}
        return subprocess.run(
            [os.environ.get("HELM", "helm"), "template", "test", str(CHART), "-f", "-"],
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

    def assert_transport(self, service, container, transport):
        env = {item["name"]: item.get("value") for item in container["env"]}
        self.assertEqual(env["TRANSPORT"], transport)
        self.assertEqual(len(env), len(container["env"]), "Duplicate environment variables")
        for probe in ("livenessProbe", "readinessProbe", "startupProbe"):
            if probe in container:
                command = container[probe]["exec"]["command"]
                self.assertEqual(command[command.index("--protocol") + 1], transport)
                self.assertEqual(command[command.index("--port") + 1], env["SERVER_PORT"])
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
        env = self.assert_transport(service, container, "nethernet")
        self.assertEqual(env["SERVER_UDP_PORTS"], "19140-19155")
        self.assertEqual(service["spec"]["ports"][0]["protocol"], "TCP")
        self.assertEqual(service["spec"]["ports"][0]["port"], 19132)
        self.assertEqual([p["port"] for p in service["spec"]["ports"][1:]], list(range(19140, 19156)))
        self.assertTrue(all(p["protocol"] == "UDP" for p in service["spec"]["ports"][1:]))
        self.assertTrue(all("nodePort" not in p for p in service["spec"]["ports"]))

    def test_nodeport_mapping_uses_external_ports_in_advertisement(self):
        service, _, container = self.manifests({
            "serviceType": "NodePort", "serverPort": 31234, "nodePort": 31234,
            "nethernet": {"advertisedAddress": "192.0.2.10", "nodePortStart": 31240},
        }, startupProbe={"enabled": True})
        env = self.assert_transport(service, container, "nethernet")
        self.assertEqual(env["SERVER_UDP_PORTS"], "192.0.2.10:31240-31255:19140-19155")
        self.assertEqual(service["spec"]["ports"][0]["nodePort"], 31234)
        for port, internal, external in zip(service["spec"]["ports"][1:], range(19140, 19156), range(31240, 31256)):
            self.assertEqual((port["port"], port["targetPort"], port["nodePort"]), (internal, internal, external))

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
        }, startupProbe={"enabled": True})
        env = self.assert_transport(service, container, "raknet")
        self.assertNotIn("SERVER_UDP_PORTS", env)
        self.assertEqual(service["spec"]["ports"], [{
            "name": "minecraft", "port": 19132, "targetPort": "minecraft",
            "nodePort": 31234, "protocol": "UDP",
        }])

    def test_restore_mode_has_no_probes(self):
        _, _, container = self.manifests(restoreMode=True, startupProbe={"enabled": True})
        for probe in ("livenessProbe", "readinessProbe", "startupProbe"):
            self.assertNotIn(probe, container)

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

    def test_env_overrides_cannot_desynchronize_service(self):
        for key, value in (("TRANSPORT", "raknet"), ("SERVER_UDP_PORTS", "20000-20010")):
            with self.subTest(key=key):
                result = self.render(extraEnv={key: value})
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("instead of extraEnv.TRANSPORT or extraEnv.SERVER_UDP_PORTS", result.stderr)


if __name__ == "__main__":
    unittest.main()
