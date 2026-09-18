# Optional resource request profile

Pass `-f values-resource-requests-conservative.yaml` to enable the optional resource request profile. Chart defaults remain unchanged when the profile is omitted.

The profile adjusts Frontend and Filemeta requests and uses absolute CPU and memory HPA targets to preserve the default scaling thresholds. Limits, replica bounds, and queue targets remain unchanged.

Review custom sizing and autoscaling overrides before enabling the profile. Helm merges size presets and overrides before rendering, so an inherited absolute target may require an explicit override to preserve the intended scaling threshold.

The base chart supports `targetCPUAverageValue` and `targetMemoryAverageValue`. Explicit service-level percentage targets and direct request overrides retain utilization behavior unless an explicit absolute target is supplied. An empty absolute override clears an inherited absolute target.

`preferredPodAntiAffinity` prefers separate hostnames for replicas of the same service and release. Explicit affinity takes precedence. Jobs and CronJobs must opt in independently.

Validate scheduling, application performance, and autoscaling under representative load before adopting the profile.
