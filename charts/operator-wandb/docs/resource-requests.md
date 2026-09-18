# Optional resource request profile

Pass `-f values-resource-requests-conservative.yaml` to enable the optional resource request profile. Chart defaults remain unchanged when the profile is omitted.

The profile adjusts the service and size entries listed in the values file. Unlisted requests stay unchanged, and the profile does not enable disabled services. Each request reduction is at most 25%. Limits, pod QoS classes, replica bounds, and queue targets remain unchanged.

Where a changed request contributes to a resource HPA, the profile uses an absolute CPU or memory target. This target equals the prior full-pod request sum multiplied by the configured utilization percentage, preserving the default scaling threshold. Resources whose requests stay unchanged retain their existing target type.

Review custom sizing, resource requests, sidecars, and autoscaling overrides before enabling the profile. Helm merges size presets and overrides before rendering, so an inherited absolute target may require an explicit override to preserve the intended scaling threshold.

The base chart supports `targetCPUAverageValue` and `targetMemoryAverageValue`. Explicit service-level percentage targets and direct request overrides retain utilization behavior unless an explicit absolute target is supplied. An empty absolute override clears an inherited absolute target.

`preserveAbsoluteTargetsWithRequestOverrides` explicitly keeps size-level absolute targets when direct container requests are already included in the full-pod threshold. Review custom sidecar requests before using this option. Explicit service-level percentage or absolute targets still take precedence.

For services with `autoscaling.keda.resourceRequestBaseline`, CPU and memory `Utilization` triggers convert to `AverageValue` using each trigger's configured percentage and the prior full-pod request sum. CPU baselines are expressed in `cpuMillicores` and memory baselines in `memoryBytes`; memory targets round upward by less than one byte. Queue triggers, existing absolute targets, authentication, and controller policies remain unchanged. The profile does not enable KEDA. Direct request overrides preserve the original trigger for that resource; custom sizing or sidecar changes require reviewing the baseline. Set a resource baseline to `0` to disable its conversion. Whole-pod baselines cannot be used with a resource trigger's `containerName`.

For services adjusted across every standard size, `preferredPodAntiAffinity` prefers separate hostnames for replicas of the same service and release. This is a scheduling preference, so replicas can share a node when needed. Explicit affinity takes precedence. Jobs and CronJobs must opt in independently.

Validate scheduling, application performance, and autoscaling under representative load before adopting the profile.

After building chart dependencies, run `python scripts/validate_resource_requests_profile.py` from the repository root with Helm and PyYAML installed. It lints and renders every standard size using default controllers and synthetic KEDA fixtures, checks request bounds and full-pod scaling thresholds, and rejects changes to limits, QoS classes, replica bounds, queue behavior, or unrelated objects.
