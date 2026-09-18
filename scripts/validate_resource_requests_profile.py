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
RESOURCE_KEYS = {"cpu", "memory"}
ABSOLUTE_KEYS = {"targetCPUAverageValue", "targetMemoryAverageValue"}
BASELINE_KEYS = {"cpuMillicores", "memoryBytes"}
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
        require(set(settings) <= {"sizing", "resources", "containers", "preferredPodAntiAffinity"}, f"{service}: unexpected profile setting")
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
            require(set(scaling) <= {"horizontal", "keda"}, f"{service}/{size}: unexpected autoscaler")
            require(set(scaling.get("horizontal", {})) <= ABSOLUTE_KEYS | {"preserveAbsoluteTargetsWithRequestOverrides"}, f"{service}/{size}: only absolute HPA targets may change")
            keda = scaling.get("keda", {})
            require(set(keda) <= {"resourceRequestBaseline"}, f"{service}/{size}: only KEDA request baselines may change")
            require(set(keda.get("resourceRequestBaseline", {})) <= BASELINE_KEYS, f"{service}/{size}: unexpected KEDA baseline")


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
    require(qos(before) == qos(after), f"{size}/{old['metadata']['name']}: QoS class changed")
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
            require(Decimal(".75") * quantity(previous) <= quantity(actual) <= quantity(previous), f"{size}/{name}/{resource}: request change exceeds profile bounds")
            changed |= quantity(actual) != quantity(previous)
            replacement["resources"]["requests"][resource] = previous
    if settings.get("preferredPodAntiAffinity") and not before.get("affinity"):
        expected_affinity = {"podAntiAffinity": {"preferredDuringSchedulingIgnoredDuringExecution": [{"weight": 100, "podAffinityTerm": {"topologyKey": "kubernetes.io/hostname", "labelSelector": {"matchLabels": old["spec"]["selector"]["matchLabels"]}}}]}}
        require(after.get("affinity") == expected_affinity, f"{size}: incorrect preferred anti-affinity")
        after.pop("affinity", None)
    require(old == new, f"{size}/{old['metadata']['name']}: unexpected workload change")
    return changed


def check_hpa(old: dict, new: dict, workloads: dict, updated_workloads: dict, settings: dict, size: str) -> None:
    before, after = old["spec"], new["spec"]
    target_name = before["scaleTargetRef"]["name"]
    pod = workloads[target_name]["spec"]["template"]["spec"]
    updated_pod = updated_workloads[target_name]["spec"]["template"]["spec"]
    horizontal = settings.get("sizing", {}).get(size, {}).get("autoscaling", {}).get("horizontal", {})
    configured = {key: value for key, value in horizontal.items() if key in ABSOLUTE_KEYS}
    pending = set(configured)
    old_metrics, new_metrics = before["metrics"], after["metrics"]
    require(len(old_metrics) == len(new_metrics), f"{size}/{target_name}: HPA metric set changed")
    for original, replacement in zip(old_metrics, new_metrics):
        if original.get("type") == "Resource":
            resource = original["resource"]["name"]
            key = {"cpu": "targetCPUAverageValue", "memory": "targetMemoryAverageValue"}.get(resource)
            current = replacement.get("resource", {}).get("target", {})
            if key in configured:
                require(current.get("type") == "AverageValue" and quantity(current["averageValue"]) == quantity(configured[key]), f"{size}/{target_name}/{resource}: profile HPA target was not applied")
                pending.remove(key)
            old_requests = [container.get("resources", {}).get("requests", {}).get(resource) for container in pod["containers"]]
            new_requests = [container.get("resources", {}).get("requests", {}).get(resource) for container in updated_pod["containers"]]
            if old_requests != new_requests and original["resource"]["target"]["type"] == "Utilization":
                require(current.get("type") == "AverageValue", f"{size}/{target_name}/{resource}: request changed without preserving absolute HPA threshold")
        if original == replacement:
            continue
        require(original.get("type") == replacement.get("type") == "Resource", "Only resource HPA targets may change")
        resource = original["resource"]["name"]
        require(resource == replacement["resource"]["name"], "HPA resource changed")
        previous, current = original["resource"]["target"], replacement["resource"]["target"]
        require(previous["type"] == "Utilization" and current["type"] == "AverageValue", "Unexpected HPA target conversion")
        requests = []
        for container in pod["containers"]:
            request = container.get("resources", {}).get("requests", {}).get(resource)
            require(request is not None, f"{size}/{target_name}: incomplete HPA request denominator")
            requests.append(quantity(request))
        expected = sum(requests) * Decimal(previous["averageUtilization"]) / 100
        require(quantity(current["averageValue"]) == expected, f"{size}/{target_name}/{resource}: absolute target differs from prior full-pod threshold")
        replacement["resource"]["target"] = deepcopy(previous)
    require(not pending, f"{size}/{target_name}: a configured HPA resource did not render")
    require(old == new, f"{size}/{target_name}: other HPA settings changed")


def normalize_generated_secrets(document: dict) -> None:
    # Fresh offline renders generate these values independently of this profile.
    if document["kind"] == "Secret":
        for key in ("MYSQL_ROOT_PASSWORD", "MYSQL_PASSWORD", "CLICKHOUSE_PASSWORD", "GORILLA_SESSION_KEY"):
            if key in (document.get("data") or {}):
                document["data"][key] = "generated-for-offline-render"


def keda_fixture(enabled: dict, profile: dict) -> dict | None:
    fixture = deepcopy(enabled)
    services = [service for service, settings in profile.items() if any(preset.get("autoscaling", {}).get("keda") for preset in settings.get("sizing", {}).values())]
    if not services:
        return None
    for service in services:
        fixture.setdefault(service, {}).setdefault("autoscaling", {})["keda"] = {
            "enabled": True,
            "minReplicaCount": 2,
            "maxReplicaCount": 9,
            "cooldownPeriod": 90,
            "advanced": {"horizontalPodAutoscalerConfig": {"behavior": {"scaleDown": {"stabilizationWindowSeconds": 300}}}},
            "triggers": [
                {"type": "kafka", "name": "queue-work", "metadata": {"bootstrapServers": "broker.example:9092", "consumerGroup": "example-consumer", "topic": "example-topic", "lagThreshold": "25"}, "authenticationRef": {"name": "example-auth"}},
                {"type": "cpu", "metricType": "Utilization", "metadata": {"value": "60"}},
                {"type": "memory", "metricType": "Utilization", "metadata": {"value": "70"}},
            ],
        }
    return fixture


def check_keda(old: dict, new: dict, workloads: dict, updated_workloads: dict, settings: dict, size: str) -> None:
    target_name = old["spec"]["scaleTargetRef"]["name"]
    pod = workloads[target_name]["spec"]["template"]["spec"]
    updated_pod = updated_workloads[target_name]["spec"]["template"]["spec"]
    baselines = settings.get("sizing", {}).get(size, {}).get("autoscaling", {}).get("keda", {}).get("resourceRequestBaseline", {})
    before, after = old["spec"]["triggers"], new["spec"]["triggers"]
    require(len(before) == len(after), f"{size}/{target_name}: KEDA trigger count changed")
    for original, replacement in zip(before, after):
        resource = original["type"]
        if resource not in RESOURCE_KEYS:
            require(original == replacement, f"{size}/{target_name}: non-resource trigger changed")
            continue
        old_requests = [container.get("resources", {}).get("requests", {}).get(resource) for container in pod["containers"]]
        new_requests = [container.get("resources", {}).get("requests", {}).get(resource) for container in updated_pod["containers"]]
        if old_requests != new_requests and original["metricType"] == "Utilization":
            require(replacement.get("metricType") == "AverageValue", f"{size}/{target_name}/{resource}: changed request lost its original KEDA threshold")
        if original == replacement:
            continue
        require(original["metricType"] == "Utilization" and replacement.get("metricType") == "AverageValue", "Unexpected KEDA conversion")
        require(all(value is not None for value in old_requests), "Incomplete KEDA request denominator")
        old_sum = sum(quantity(value) for value in old_requests)
        baseline_key = "cpuMillicores" if resource == "cpu" else "memoryBytes"
        baseline_unit = Decimal(".001") if resource == "cpu" else Decimal(1)
        require(Decimal(baselines[baseline_key]) * baseline_unit == old_sum, f"{size}/{target_name}/{resource}: KEDA baseline differs from original full-pod requests")
        expected = old_sum * Decimal(original["metadata"]["value"]) / 100
        difference = quantity(replacement["metadata"]["value"]) - expected
        require(difference == 0 if resource == "cpu" else 0 <= difference < 1, f"{size}/{target_name}/{resource}: KEDA threshold changed")
        replacement["metricType"] = original["metricType"]
        replacement["metadata"]["value"] = original["metadata"]["value"]
    require(old == new, f"{size}/{target_name}: other KEDA configuration changed")


def validate_render(baseline: dict, updated: dict, profile: dict, defaults: dict, size: str, changes: dict) -> None:
    require(baseline.keys() == updated.keys(), f"{size}: object set changed")
    workloads = {name: item for (kind, name), item in baseline.items() if kind == "Deployment"}
    updated_workloads = {name: item for (kind, name), item in updated.items() if kind == "Deployment"}
    seen, autoscalers_seen = set(), set()
    for key, original in baseline.items():
        replacement = updated[key]
        service = (original["metadata"].get("labels") or {}).get("app.kubernetes.io/name")
        if original["kind"] == "Deployment" and service in profile:
            seen.add(service)
            if check_workload(deepcopy(original), deepcopy(replacement), profile[service], defaults[service], size):
                changes[service].add(size)
        elif original["kind"] == "HorizontalPodAutoscaler" and service in profile:
            autoscalers_seen.add(service)
            check_hpa(deepcopy(original), deepcopy(replacement), workloads, updated_workloads, profile[service], size)
        elif original["kind"] == "ScaledObject" and service in profile:
            autoscalers_seen.add(service)
            check_keda(deepcopy(original), deepcopy(replacement), workloads, updated_workloads, profile[service], size)
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
