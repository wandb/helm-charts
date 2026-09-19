# Optional resource request profile

Pass `-f values-resource-requests-conservative.yaml` to enable the optional resource request profile. Chart defaults remain unchanged when the profile is omitted.

The profile adjusts the service and size entries listed in the values file. Unlisted requests stay unchanged, and the profile does not enable disabled services. Most request reductions are at most 25%. For medium only, Parquet and parquet-metadata-cache instead request 8 CPUs rather than 15, retaining their 15-CPU limits and 64-GiB memory requests/limits. These pods change from Guaranteed to Burstable QoS. Other pod QoS classes, all limits, replica bounds, and queue targets remain unchanged.

Where a changed request contributes to a resource HPA, the profile uses an absolute CPU or memory target. This target equals the prior full-pod request sum multiplied by the configured utilization percentage, preserving the default scaling threshold. Resources whose requests stay unchanged retain their existing target type.

Review custom sizing, resource requests, sidecars, and autoscaling overrides before enabling the profile. Helm merges size presets and overrides before rendering, so an inherited absolute target may require an explicit override to preserve the intended scaling threshold.

The base chart supports `targetCPUAverageValue` and `targetMemoryAverageValue`. Explicit service-level percentage targets and direct request overrides retain utilization behavior unless an explicit absolute target is supplied. An empty absolute override clears an inherited absolute target.

`preserveAbsoluteTargetsWithRequestOverrides` explicitly keeps size-level absolute targets when direct container requests are already included in the full-pod threshold. Review custom sidecar requests before using this option. Explicit service-level percentage or absolute targets still take precedence.

For services with `autoscaling.keda.resourceRequestBaseline`, CPU and memory `Utilization` triggers convert to `AverageValue` using each trigger's configured percentage and the prior full-pod request sum. CPU baselines are expressed in `cpuMillicores` and memory baselines in `memoryBytes`; memory targets round upward by less than one byte. Queue triggers, existing absolute targets, authentication, and controller policies remain unchanged. The profile does not enable KEDA. Direct request overrides preserve the original trigger for that resource; custom sizing or sidecar changes require reviewing the baseline. Set a resource baseline to `0` to disable its conversion. Whole-pod baselines cannot be used with a resource trigger's `containerName`.

For services adjusted across every standard size, `preferredPodAntiAffinity` prefers separate hostnames for replicas of the same service and release. This is a scheduling preference, so replicas can share a node when needed. Explicit affinity takes precedence. Jobs and CronJobs must opt in independently.

Parquet and parquet-metadata-cache use required hostname anti-affinity across both service names, including between Parquet replicas, at every size when this profile is enabled. The selector is namespace-wide, including other releases in that namespace. At least one eligible node per combined replica is required; rolling updates may need an additional node for a surge pod. Preserve this separation if overriding affinity or service name labels. Small-size requests retain their existing profile settings; large, xlarge, and xxlarge retain their original 15-CPU requests for these services.

An 8-CPU request also prevents two of these pods sharing a QA worker with 15.82 allocatable CPUs. The explicit affinity keeps that separation on larger workers. CPU limits allow bursts only when CPU is available; pod priority does not reserve burst capacity. This profile does not set a PriorityClass.

These are candidate settings, not validated capacity sizing for each tier. The render checks establish configuration correctness, not workload performance.

| Size | Parquet CPU request | Metadata-cache CPU request | Evidence for these settings |
| --- | ---: | ---: | --- |
| small | 1 (unchanged) | 3 (existing profile) | No per-tier performance validation established by this PR |
| medium | 8 (was 15) | 8 (was 15) | Proposed QA compaction experiment; performance validation pending |
| large | 15 (unchanged) | 15 (unchanged) | No reduction inferred from medium QA |
| xlarge | 15 (unchanged) | 15 (unchanged) | No reduction inferred from medium QA |
| xxlarge | 15 (unchanged) | 15 (unchanged) | No reduction inferred from medium QA |

Other service/size entries also require tier-specific validation. Record deployment samples, observation windows, per-pod CPU and memory distributions, burst/startup behavior, replica counts, load and latency targets, and failure headroom before promoting a candidate to a recommended tier setting. Identical requests across tiers can be appropriate when capacity scales through replicas; they need workload evidence rather than a fixed reduction percentage.

The 8-CPU configuration has not yet been performance-tested in QA. Earlier QA results used 15-CPU Parquet/cache requests. Validate scheduling, application performance under concurrent Parquet/cache and neighboring workloads, and autoscaling before adopting the profile.

After building chart dependencies, run `python scripts/validate_resource_requests_profile.py` from the repository root with Helm and PyYAML installed. It lints and renders every standard size using default controllers and synthetic KEDA fixtures, checks request bounds and full-pod scaling thresholds, and rejects changes to limits, replica bounds, queue behavior, or unrelated objects. It allows only the documented Parquet QoS transition and verifies required separation for both services.
