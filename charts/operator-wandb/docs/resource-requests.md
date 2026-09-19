# Optional resource request profile

Pass `-f values-resource-requests-conservative.yaml` to opt in. Normal chart defaults are unchanged. These are rounded candidates informed by a month of managed-install telemetry, not validated throughput or capacity guarantees. The [evidence and method](resource-requests-evidence.md) explain each tier's coverage and why some defaults are retained.

CPU requests use quarter-core increments. Memory uses simple GiB sizes or 256/512 MiB. Limits, replica bounds, queue targets and enabled services are unchanged. Reducing requests below equal limits changes affected Guaranteed pods to Burstable; API, app and Parquet are among the affected services. Lower CPU requests also reduce CPU weight under contention even when the limit stays the same.

## Effective requests

Each cell is **CPU cores / GiB memory**, including unchanged defaults. Unlisted services retain their defaults. The profile keeps larger tiers at least as large as the preceding tier; a tier without enough evidence retains its default and can therefore limit reductions in later tiers.

| Service | Small | Medium | Large | Xlarge | Xxlarge |
| --- | --- | --- | --- | --- | --- |
| api | 1 / 2 | 4 / 16 | 4.5 / 16 | 6 / 16 | 6 / 16 |
| app | 0.5 / 2 | 0.5 / 2 | 0.5 / 2 | 4 / 8 | 4 / 8 |
| frontend | 0.25 / 0.25 | 0.5 / 0.25 | 0.5 / 0.25 | 0.5 / 0.25 | 0.75 / 0.25 |
| filemeta | 0.25 / 0.25 | 0.5 / 0.25 | 0.5 / 0.25 | 0.5 / 0.25 | 0.75 / 0.25 |
| glue | 0.5 / 2 | 1 / 4 | 1.25 / 4 | 1.25 / 4 | 2.25 / 6 |
| metric-observer | 0.5 / 0.5 | 0.75 / 1 | 0.75 / 1 | 0.75 / 1 | 1 / 4 |
| weave-trace | 1 / 4 | 1 / 4 | 1 / 4 | 1 / 6 | 1 / 6 |
| parquet | 1 / 8 | 8 / 64 | 15 / 64 | 15 / 64 | 15 / 64 |
| parquet-metadata-cache | 4 / 16 | 8 / 64 | 15 / 64 | 15 / 64 | 15 / 64 |
| weave | 1 / 8 | 2 / 24 | 3 / 24 | 3 / 24 | 3 / 48 |
| flat-run-fields-updater | 1 / 2 | 1 / 2 | 1 / 3 | 1 / 6 | 1 / 6 |
| history-updater | 1 / 1 | 1 / 1 | 1 / 1.5 | 1 / 3 | 1 / 3 |
| weave-trace-worker | 1 / 4 | 1 / 4 | 1 / 4 | 1 / 4 | 1 / 4 |
| weave-trace-agent-scoring-worker | 1 / 3 | 1 / 3 | 1 / 3 | 1 / 3 | 1 / 3 |

The two medium Parquet replicas and one metadata-cache replica request **8 CPUs each**, retaining 15-CPU limits and 64-GiB memory requests/limits. This is the agreed QA experiment. Metadata-cache has insufficient representative medium fleet coverage; its 8-CPU request is an explicit experiment, not a telemetry-derived recommendation. Other Parquet/cache sizes retain defaults. Earlier QA runs used 15-CPU requests and do not validate these new settings.

## Percentage autoscaling

HPA targets use Kubernetes `Utilization` percentages of the new full-pod requests. There is no absolute-target conversion. Both CPU and memory remain configured; Kubernetes uses the larger replica recommendation. With sufficient controller coverage, a clearly higher normalized pressure signal gets a 70% target and the other resource stays at 80%; balanced or uncertain rows stay at 80%/80%. These are operator-selected policy thresholds, not an empirically proven latency boundary. See the evidence table for the pressure signal and final targets.

For example, medium metric-observer uses CPU 70% / memory 80%, while filemeta uses CPU 80% / memory 70%. A smaller request lowers the absolute scale-out threshold intentionally. Fixed min=max workloads cannot add replicas regardless of the percentage; their bounds remain unchanged and their targets stay at 80%/80%. The profile does not turn on autoscaling for app, glue or metadata-cache.

Queue workers and cache-heavy services retain their existing resource targets rather than interpreting low idle CPU or resident cache memory as evidence for new scaling behavior. KEDA keeps its configured queue/resource triggers, percentages, authentication and replica bounds. A custom KEDA utilization trigger still uses the new request denominator; its absolute scale-out point can therefore change. Service-level custom percentage targets retain precedence over size presets. Review custom requests and sidecars because HPA utilization includes every container's requests and usage.

## Placement and validation

Required hostname anti-affinity separates Parquet and metadata-cache from each other and from Parquet replicas at every size. It selects both service names within the namespace, including other releases. At least one eligible node per combined replica is required; a rolling surge can need another node. Preserve the selector if changing service name labels or affinity. On current QA workers, two 8-CPU requests also exceed the 15.82 allocatable CPUs; the affinity keeps separation on larger workers. This profile does not set a PriorityClass.

Frontend, filemeta and metric-observer retain preferred hostname anti-affinity for replicas of the same release. Explicit affinity takes precedence; jobs must opt in independently.

After building dependencies, run `python scripts/validate_resource_requests_profile.py` with Helm and PyYAML installed. It lints and renders all five sizes with normal and synthetic KEDA controllers, checks the rounded requests and percentage targets, and rejects unexpected changes to limits, replica bounds, queues and unrelated objects. Render tests do not establish performance. Test the revised profile under representative concurrent load, sustained pressure, bursts, and worker loss before rollout; watch latency, backlog, throttling, OOMs and HPA ceilings.
