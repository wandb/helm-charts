#!/usr/bin/env python3
"""Render the optional profile and verify its scheduling/autoscaling contract.

Requires Helm with chart dependencies built, and PyYAML. This check uses chart
configuration only; it does not read telemetry or contact a Kubernetes cluster.
"""
from __future__ import annotations

import argparse
from copy import deepcopy
from decimal import Decimal
from pathlib import Path
import re
import subprocess
import tempfile

import yaml

ROOT = Path(__file__).resolve().parents[1]
CHART = ROOT / "charts" / "operator-wandb"
PROFILE = CHART / "values-resource-requests-conservative.yaml"
SIZES = ("small", "medium", "large", "xlarge", "xxlarge")
PARQUET_SERVICES = {"parquet", "parquet-metadata-cache"}
PARQUET_AFFINITY = {
    "podAntiAffinity": {
        "requiredDuringSchedulingIgnoredDuringExecution": [{
            "topologyKey": "kubernetes.io/hostname",
            "labelSelector": {
                "matchExpressions": [{
                    "key": "app.kubernetes.io/name",
                    "operator": "In",
                    "values": ["parquet", "parquet-metadata-cache"],
                }],
            },
        }],
    },
}
EVICTION_VOLUMES = {
    'app': 'wandb-ca-certs-root,datadog-socket',
    'api': 'wandb-ca-certs-root,datadog-socket,temp-dir',
    'frontend': 'wandb-ca-certs-root,datadog-socket',
    'filemeta': 'wandb-ca-certs-root,datadog-socket',
    'glue': 'wandb-ca-certs-root,datadog-socket,temp-dir',
    'metric-observer': 'wandb-ca-certs-root,datadog-socket',
    'parquet': 'wandb-ca-certs-root,datadog-socket',
    'parquet-metadata-cache': 'wandb-ca-certs-root,datadog-socket',
    'weave-trace': 'wandb-ca-certs-root,datadog-socket,temp-dir',
    'anaconda2': 'wandb-ca-certs-root,datadog-socket',
    'executor': 'wandb-ca-certs-root,datadog-socket',
    'flat-run-fields-updater': 'wandb-ca-certs-root,datadog-socket',
    'history-updater': 'wandb-ca-certs-root,datadog-socket',
    'mcp-server': 'wandb-ca-certs-root,datadog-socket,temp-dir',
    'weave': 'wandb-ca-certs-root,datadog-socket,temp-dir,cache',
}
RESOURCE_KEYS = {"cpu", "memory"}
PERCENTAGE_KEYS = {"targetCPUUtilizationPercentage", "targetMemoryUtilizationPercentage"}
QUANTITY = re.compile(r"^([+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?)([A-Za-z]*)$")
FACTORS = {"": Decimal(1), "m": Decimal(".001"), "u": Decimal(".000001"), "n": Decimal(".000000001")}
FACTORS.update({suffix: Decimal(1024) ** power for power, suffix in enumerate(("Ki", "Mi", "Gi", "Ti", "Pi", "Ei"), 1)})
FACTORS.update({suffix: Decimal(1000) ** power for power, suffix in enumerate(("k", "M", "G", "T", "P", "E"), 1)})


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def quantity(value: object) -> Decimal:
    match = QUANTITY.fullmatch(str(value))
    require(bool(match), f"Invalid resource quantity: {value!r}")
    number, suffix = match.groups()
    require(suffix in FACTORS, f"Unsupported resource suffix: {suffix!r}")
    return Decimal(number) * FACTORS[suffix]


def check_resources(value: dict, location: str) -> None:
    require(set(value) <= {"requests"}, f"{location}: only requests may change")
    require(set(value.get("requests", {})) <= RESOURCE_KEYS, f"{location}: unexpected resource")


def check_profile(profile: dict) -> None:
    require(bool(profile), "Profile must contain services")
    for service, settings in profile.items():
        require(set(settings) <= {"sizing", "resources", "containers", "preferredPodAntiAffinity", "affinity", "podAnnotations", "podDisruptionBudget"}, f"{service}: unexpected profile setting")
        if "podAnnotations" in settings:
            require(service in EVICTION_VOLUMES and settings["podAnnotations"] == {"cluster-autoscaler.kubernetes.io/safe-to-evict-local-volumes": EVICTION_VOLUMES[service]}, f"{service}: unexpected eviction exemption")
        if "podDisruptionBudget" in settings:
            require(service in {"app", "parquet-metadata-cache"} and settings["podDisruptionBudget"] == {"maxUnavailable": "0%"}, f"{service}: preserve a serving replica")
        if "affinity" in settings:
            require(service in PARQUET_SERVICES and settings["affinity"] == PARQUET_AFFINITY, f"{service}: unexpected required anti-affinity")
        if "resources" in settings:
            check_resources(settings["resources"], service)
        for name, container in settings.get("containers", {}).items():
            require(set(container) == {"resources"}, f"{service}/{name}: only resources may change")
            check_resources(container["resources"], f"{service}/{name}")
        if "preferredPodAntiAffinity" in settings:
            require(settings["preferredPodAntiAffinity"] is True, f"{service}: preference must be enabled explicitly")
        for size, preset in settings.get("sizing", {}).items():
            require(size in SIZES, f"{service}: unsupported profile size")
            require(set(preset) <= {"resources", "autoscaling"}, f"{service}/{size}: unexpected preset setting")
            check_resources(preset.get("resources", {}), f"{service}/{size}")
            scaling = preset.get("autoscaling", {})
            require(set(scaling) <= {"horizontal"}, f"{service}/{size}: only HPA percentages may change")
            targets = scaling.get("horizontal", {})
            require(set(targets) <= PERCENTAGE_KEYS, f"{service}/{size}: unexpected HPA setting")
            require(all(v in (70, 80) for v in targets.values()), f"{service}/{size}: use reviewed percentage targets")


def enable_values(profile: dict) -> dict:
    chart = yaml.safe_load((CHART / "Chart.yaml").read_text())
    dependencies = {item.get("alias", item["name"]): item for item in chart["dependencies"]}
    result = {"global": {"api": {"enabled": True}}}
    for service in profile:
        require(service in dependencies, f"{service}: no chart dependency renders this service")
        require(dependencies[service]["name"] == "wandb-base", f"{service}: unsupported workload chart")
        for condition in dependencies[service].get("condition", "").split(","):
            if not condition:
                continue
            target = result
            parts = condition.split(".")
            for part in parts[:-1]:
                target = target.setdefault(part, {})
            target[parts[-1]] = True
    return result


def render(helm: str, size: str, enabled: Path, profile: Path | None) -> dict:
    command = [helm, "template", "profile-check", str(CHART), "--namespace", "profile-check", "-f", str(enabled), "--set", f"global.size={size}"]
    if profile:
        command += ["-f", str(profile)]
    completed = subprocess.run(command, text=True, capture_output=True, check=False)
    require(completed.returncode == 0, f"Helm render failed for {size}: {completed.stderr}")
    result = {}
    for document in yaml.safe_load_all(completed.stdout):
        if not isinstance(document, dict):
            continue
        key = (document["kind"], document["metadata"]["name"])
        require(key not in result, f"Duplicate rendered object: {key}")
        result[key] = document
    return result


def qos(pod: dict) -> str:
    containers = (pod.get("containers") or []) + (pod.get("initContainers") or [])
    guaranteed = bool(containers)
    has_resources = False
    for container in containers:
        resources = container.get("resources", {})
        has_resources |= bool(resources.get("requests") or resources.get("limits"))
        for resource in RESOURCE_KEYS:
            limit = resources.get("limits", {}).get(resource)
            request = resources.get("requests", {}).get(resource, limit)
            guaranteed &= limit is not None and request is not None and quantity(limit) > 0 and quantity(limit) == quantity(request)
    return "Guaranteed" if guaranteed else "Burstable" if has_resources else "BestEffort"


def expected_requests(settings: dict, defaults: dict, size: str, container: str) -> dict:
    requests = dict(settings.get("sizing", {}).get(size, {}).get("resources", {}).get("requests", {}))
    for resource in defaults.get("resources", {}).get("requests", {}):
        requests.pop(resource, None)
    requests.update(settings.get("resources", {}).get("requests", {}))
    for resource in defaults.get("containers", {}).get(container, {}).get("resources", {}).get("requests", {}):
        requests.pop(resource, None)
    requests.update(settings.get("containers", {}).get(container, {}).get("resources", {}).get("requests", {}))
    return requests


def check_workload(old: dict, new: dict, settings: dict, defaults: dict, size: str) -> bool:
    before, after = old["spec"]["template"]["spec"], new["spec"]["template"]["spec"]
    service = old["metadata"]["labels"]["app.kubernetes.io/name"]
    require(qos(before) == qos(after) or (qos(before), qos(after)) == ("Guaranteed", "Burstable"),
            f"{size}/{service}: unexpected QoS transition")
    old_containers = {item["name"]: item for item in before["containers"]}
    new_containers = {item["name"]: item for item in after["containers"]}
    require(old_containers.keys() == new_containers.keys(), "Container set changed")
    changed = False
    for name, original in old_containers.items():
        replacement = new_containers[name]
        expected = expected_requests(settings, defaults, size, name)
        for resource, target in expected.items():
            actual = replacement.get("resources", {}).get("requests", {}).get(resource)
            previous = original.get("resources", {}).get("requests", {}).get(resource)
            require(actual is not None and previous is not None, f"{name}: request missing")
            require(quantity(actual) == quantity(target), f"{size}/{name}/{resource}: profile request was not applied")
            require(0 < quantity(actual) <= quantity(previous), f"{size}/{name}/{resource}: requests must be positive and no larger than defaults")
            step = Decimal(".25") if resource == "cpu" else Decimal(256 * 1024 * 1024)
            require(quantity(actual) % step == 0, f"{size}/{name}/{resource}: request must use a human-readable increment")
            changed |= quantity(actual) != quantity(previous)
            replacement["resources"]["requests"][resource] = previous
    if "affinity" in settings:
        require(after.get("affinity") == PARQUET_AFFINITY, f"{size}/{service}: required Parquet separation missing")
        if "affinity" in before:
            after["affinity"] = deepcopy(before["affinity"])
        else:
            after.pop("affinity", None)
    if settings.get("preferredPodAntiAffinity") and not before.get("affinity"):
        expected_affinity = {"podAntiAffinity": {"preferredDuringSchedulingIgnoredDuringExecution": [{"weight": 100, "podAffinityTerm": {"topologyKey": "kubernetes.io/hostname", "labelSelector": {"matchLabels": old["spec"]["selector"]["matchLabels"]}}}]}}
        require(after.get("affinity") == expected_affinity, f"{size}: incorrect preferred anti-affinity")
        after.pop("affinity", None)
    if "podAnnotations" in settings:
        old_annotations = (old["spec"]["template"]["metadata"].get("annotations") or {})
        new_annotations = new["spec"]["template"]["metadata"]["annotations"]
        for key, value in settings["podAnnotations"].items():
            require(new_annotations.get(key) == value, f"{size}/{service}: missing durable eviction annotation")
            if key in old_annotations:
                new_annotations[key] = old_annotations[key]
            else:
                new_annotations.pop(key)
        if not new_annotations:
            if "annotations" in old["spec"]["template"]["metadata"]:
                new["spec"]["template"]["metadata"]["annotations"] = deepcopy(old["spec"]["template"]["metadata"]["annotations"])
            else:
                new["spec"]["template"]["metadata"].pop("annotations")
    require(old == new, f"{size}/{old['metadata']['name']}: unexpected workload change")
    return changed


def check_hpa(old: dict, new: dict, settings: dict, size: str) -> None:
    configured = settings.get("sizing", {}).get(size, {}).get("autoscaling", {}).get("horizontal", {})
    before, after = old["spec"]["metrics"], new["spec"]["metrics"]
    require(len(before) == len(after), f"{size}: HPA metric set changed")
    seen = set()
    for original, replacement in zip(before, after):
        require(original.get("type") == replacement.get("type") == "Resource", "Expected resource HPA metrics")
        resource = original["resource"]["name"]
        key = {"cpu": "targetCPUUtilizationPercentage", "memory": "targetMemoryUtilizationPercentage"}[resource]
        target = replacement["resource"]["target"]
        expected = configured.get(key, original["resource"]["target"]["averageUtilization"])
        require(target == {"type": "Utilization", "averageUtilization": expected}, f"{size}/{resource}: incorrect percentage HPA target")
        seen.add(key)
        replacement["resource"]["target"] = deepcopy(original["resource"]["target"])
    require(set(configured) <= seen, f"{size}: configured HPA resource did not render")
    require(old == new, f"{size}: HPA replica bounds or other settings changed")


def normalize_generated_secrets(document: dict) -> None:
    # Fresh offline renders generate these values independently of this profile.
    if document["kind"] == "Secret":
        for key in ("MYSQL_ROOT_PASSWORD", "MYSQL_PASSWORD", "CLICKHOUSE_PASSWORD", "GORILLA_SESSION_KEY"):
            if key in (document.get("data") or {}):
                document["data"][key] = "generated-for-offline-render"


def keda_fixture(enabled: dict, profile: dict) -> dict:
    fixture = deepcopy(enabled)
    # Exercise a queue worker and Parquet with synthetic resource triggers.
    # Custom KEDA percentages and queue settings must remain unchanged.
    for service in ("metric-observer", "parquet"):
        if service not in profile:
            continue
        fixture.setdefault(service, {}).setdefault("autoscaling", {})["keda"] = {
            "enabled": True, "minReplicaCount": 2, "maxReplicaCount": 9,
            "cooldownPeriod": 90,
            "triggers": [
                {"type": "kafka", "name": "queue-work", "metadata": {"bootstrapServers": "broker.example:9092", "consumerGroup": "example-consumer", "topic": "example-topic", "lagThreshold": "25"}, "authenticationRef": {"name": "example-auth"}},
                {"type": "cpu", "metricType": "Utilization", "metadata": {"value": "60"}},
                {"type": "memory", "metricType": "Utilization", "metadata": {"value": "70"}},
            ],
        }
    return fixture


def validate_render(baseline: dict, updated: dict, profile: dict, defaults: dict, size: str, changes: dict) -> None:
    require(baseline.keys() == updated.keys(), f"{size}: object set changed")
    seen, autoscalers_seen = set(), set()
    for key, original in baseline.items():
        replacement = updated[key]
        service = (original["metadata"].get("labels") or {}).get("app.kubernetes.io/name")
        if original["kind"] == "Deployment" and service in profile:
            seen.add(service)
            if check_workload(deepcopy(original), deepcopy(replacement), profile[service], defaults[service], size):
                changes[service].add(size)
        elif original["kind"] == "PodDisruptionBudget" and profile.get(service, {}).get("podDisruptionBudget"):
            expected = deepcopy(original)
            expected["spec"]["maxUnavailable"] = "0%"
            require(replacement == expected, f"{size}/{service}: incorrect singleton protection")
        elif original["kind"] == "HorizontalPodAutoscaler" and service in profile:
            autoscalers_seen.add(service)
            check_hpa(deepcopy(original), deepcopy(replacement), profile[service], size)
        elif original["kind"] == "ScaledObject" and service in profile:
            autoscalers_seen.add(service)
            require(original == replacement, f"{size}/{service}: KEDA triggers or controller settings changed")
        else:
            left, right = deepcopy(original), deepcopy(replacement)
            normalize_generated_secrets(left)
            normalize_generated_secrets(right)
            require(left == right, f"{size}/{key}: profile changed an unrelated object")
    require(seen == set(profile), f"{size}: a profile service did not render as a Deployment")
    for service, settings in profile.items():
        if settings.get("sizing", {}).get(size, {}).get("autoscaling", {}).get("horizontal"):
            require(service in autoscalers_seen, f"{size}/{service}: configured autoscaler did not render")


def validate(helm: str, profile_path: Path) -> None:
    profile = yaml.safe_load(profile_path.read_text())
    check_profile(profile)
    enabled = enable_values(profile)
    defaults = yaml.safe_load((CHART / "values.yaml").read_text())
    fixtures = {"default": enabled}
    synthetic_keda = keda_fixture(enabled, profile)
    if synthetic_keda:
        fixtures["KEDA"] = synthetic_keda
    changes = {service: set() for service in profile}
    with tempfile.TemporaryDirectory(prefix="resource-profile-") as directory:
        values_path = Path(directory) / "enabled.yaml"
        for fixture_name, fixture in fixtures.items():
            values_path.write_text(yaml.safe_dump(fixture))
            for size in SIZES:
                lint = subprocess.run([helm, "lint", str(CHART), "-f", str(values_path), "-f", str(profile_path), "--set", f"global.size={size}"], text=True, capture_output=True, check=False)
                require(lint.returncode == 0, f"Helm lint failed for {size}: {lint.stdout}{lint.stderr}")
                baseline = render(helm, size, values_path, None)
                updated = render(helm, size, values_path, profile_path)
                validate_render(baseline, updated, profile, defaults, size, changes)
                print(f"Profile contract passed for {size} ({fixture_name})")
    for service, settings in profile.items():
        if settings.get("sizing") or settings.get("resources") or settings.get("containers"):
            require(bool(changes[service]), f"{service}: profile does not change any request")
        if settings.get("preferredPodAntiAffinity"):
            require(changes[service] == set(SIZES), f"{service}: preference affects sizes without request changes")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--helm", default="helm")
    parser.add_argument("--profile", type=Path, default=PROFILE)
    args = parser.parse_args()
    validate(args.helm, args.profile.resolve())


if __name__ == "__main__":
    main()
