# Optional resource request profile

Pass `-f values-resource-requests-conservative.yaml` to opt in. Normal chart defaults are unchanged. These are rounded candidates informed by a month of managed-install telemetry, not validated throughput or capacity guarantees. The [evidence and method](resource-requests-evidence.md) explain each tier's coverage and why some defaults are retained.

CPU requests use quarter-core increments. Memory uses simple GiB sizes or 256/512 MiB. Limits, replica bounds, queue targets and enabled services are unchanged. Reducing requests below equal limits changes affected Guaranteed pods to Burstable; API, app and Parquet are among the affected services. Lower CPU requests also reduce CPU weight under contention even when the limit stays the same.

## Effective requests

Each cell is **CPU cores / GiB memory**, including unchanged defaults. All nine services in the profile explicitly define all five tiers. The remaining services below retain chart defaults. Requests are nondecreasing across tiers; metadata-cache retains its default memory reservation at every size.

| Service | Small | Medium | Large | Xlarge | Xxlarge |
| --- | --- | --- | --- | --- | --- |
| api | 1 / 2 | 4 / 12 | 4 / 16 | 6 / 16 | 6 / 16 |
| app | 0.5 / 2 | 0.5 / 2 | 0.5 / 2 | 4 / 8 | 4 / 8 |
| frontend | 0.25 / 0.25 | 0.5 / 0.25 | 0.5 / 0.25 | 0.5 / 0.25 | 0.75 / 0.25 |
| filemeta | 0.25 / 0.25 | 0.5 / 0.25 | 0.5 / 0.25 | 0.5 / 0.25 | 0.75 / 0.25 |
| glue | 0.5 / 2 | 1 / 4 | 1.25 / 4 | 1.25 / 4 | 2.25 / 6 |
| metric-observer | 0.5 / 0.5 | 0.75 / 1 | 0.75 / 1 | 0.75 / 1 | 1 / 4 |
| weave-trace | 1 / 4 | 1 / 4 | 1 / 4 | 1 / 6 | 1 / 6 |
| parquet | 1 / 8 | 8 / 64 | 8 / 64 | 12 / 64 | 15 / 64 |
| parquet-metadata-cache | 4 / 16 | 8 / 64 | 8 / 64 | 8 / 64 | 15 / 64 |
| weave | 1 / 8 | 2 / 24 | 3 / 24 | 3 / 24 | 3 / 48 |
| flat-run-fields-updater | 1 / 2 | 1 / 2 | 1 / 3 | 1 / 6 | 1 / 6 |
| history-updater | 1 / 1 | 1 / 1 | 1 / 1.5 | 1 / 3 | 1 / 3 |
| weave-trace-worker | 1 / 4 | 1 / 4 | 1 / 4 | 1 / 4 | 1 / 4 |
| weave-trace-agent-scoring-worker | 1 / 3 | 1 / 3 | 1 / 3 | 1 / 3 | 1 / 3 |

The two medium Parquet replicas and one metadata-cache replica request **8 CPUs each**, retaining 15-CPU limits and 64-GiB memory requests/limits. This is the agreed QA experiment. Metadata-cache has insufficient representative medium fleet coverage; its 8-CPU request is an explicit experiment, not a telemetry-derived recommendation. Large Parquet requests 8 CPUs / 64 GiB; xlarge requests 12 CPUs / 64 GiB. Metadata-cache requests 8 CPUs / 64 GiB at both sizes. Small and xxlarge Parquet/cache explicitly retain defaults. The short medium QA test does not validate other tiers.

The large/xlarge settings are explicit CPU compaction experiments. Parquet retains its memory reservation because observed working sets approached 64 GiB. The xlarge 12-CPU request is a chosen contention margin, not a measured safe minimum. Large metadata-cache has no matching customer cohort and xlarge has only one, so both retain the chart's 64-GiB memory request. The observed 21-GiB peak across five matching xxlarge customers does not justify reducing reservations in other tiers. Limits remain 15 CPUs / 64 GiB, and `GOMEMLIMIT`/`GOMAXPROCS` still derive from those limits.

At two Parquet replicas and one cache replica, these changes alone release **21 requested CPUs for large** and **13 requested CPUs for xlarge**, versus their defaults, with no memory reservation reduction. Those CPU reservations can accommodate other workloads; realized node and cost reductions depend on placement, HPA growth, supporting services and rollout headroom. Six nodes is a QA test result, not a fleet-wide size guarantee.

API small/xlarge/xxlarge and Parquet small/xxlarge explicitly retain defaults because of observed pressure. App xlarge/xxlarge and Weave Trace xlarge also explicitly retain defaults where coverage is sparse or missing. An explicit tier entry documents the sizing decision; it does not imply a measured reduction.

Medium API memory (12 GiB) and large API CPU (4 cores) are also explicit tuning choices rather than outputs of the headroom formula. Medium API observed memory approached 16 GiB; its limit remains 16 GiB and its fixed replica bounds do not provide additional scale-out capacity.

## Percentage autoscaling

HPA targets use Kubernetes `Utilization` percentages of the new full-pod requests. There is no absolute-target conversion. Both CPU and memory remain configured; Kubernetes uses the larger replica recommendation. With sufficient controller coverage, a clearly higher normalized pressure signal gets a 70% target and the other resource stays at 80%; balanced or uncertain rows stay at 80%/80%. These are operator-selected policy thresholds, not an empirically proven latency boundary. See the evidence table for the pressure signal and final targets.

For example, medium metric-observer uses CPU 70% / memory 80%, while filemeta uses CPU 80% / memory 70%. A smaller request lowers the absolute scale-out threshold intentionally. Fixed min=max workloads cannot add replicas regardless of the percentage; their bounds remain unchanged and their targets stay at 80%/80%. The profile does not turn on autoscaling for app, glue or metadata-cache.

Queue workers and cache-heavy services retain their existing resource targets rather than interpreting low idle CPU or resident cache memory as evidence for new scaling behavior. KEDA keeps its configured queue/resource triggers, percentages, authentication and replica bounds. A custom KEDA utilization trigger still uses the new request denominator; its absolute scale-out point can therefore change. Service-level custom percentage targets retain precedence over size presets. Review custom requests and sidecars because HPA utilization includes every container's requests and usage.

The managed-spec port in deployments PR976 omits the legacy `app` profile because managed installs default it off. It also omits metric-observer's native HPA targets: managed metric-observer uses KEDA, which suppresses native HPA rendering and retains its existing resource and queue triggers. The standalone chart profile keeps those targets for installations using native HPA.

## Placement and validation

Required hostname anti-affinity separates Parquet and metadata-cache from each other and from Parquet replicas at every size. It selects both service names within the namespace, including other releases. At least one eligible node per combined replica is required; a rolling surge can need another node. Preserve the selector if changing service name labels or affinity. On current QA workers, two 8-CPU requests also exceed the 15.82 allocatable CPUs; the affinity keeps separation on larger workers. This profile does not set a PriorityClass. Priority preemption can make room for pending pods; it does not evict neighbors when a running Parquet pod needs more CPU. Required separation does not eliminate contention with other services.

Before enrollment, inspect effective HPA/KEDA maxima or fixed replica counts for both services, including user overrides and other matching releases. Their combined maxima set the number of separate eligible workers needed at peak replica count; add rolling-surge and failure headroom. Check autoscaler node ceilings, taints, node selectors, volume zones and available CPU/memory. A sufficient total node count alone does not establish schedulability. Preserve customer replica settings rather than lowering them to hit a packing target.

The profile enables preferred hostname anti-affinity for frontend, filemeta and metric-observer replicas of the same release. The base chart's `preferredPodAntiAffinity` defaults to `false` when omitted, so it adds no preferred anti-affinity unless enabled. Explicit `affinity` takes precedence. Jobs and CronJobs do not inherit the service flag; enable it separately with `jobs.<name>.preferredPodAntiAffinity: true` or `cronJobs.<name>.preferredPodAntiAffinity: true`. Parquet and metadata-cache use explicit required anti-affinity, independently of this flag.

After building dependencies, run `python scripts/validate_resource_requests_profile.py` with Helm and PyYAML installed. It lints and renders all five sizes with normal and synthetic KEDA controllers, checks the rounded requests and percentage targets, and rejects unexpected changes to limits, replica bounds, queues and unrelated objects. Render tests do not establish performance. Test the revised profile under representative concurrent load, sustained pressure, bursts, and worker loss before rollout; watch latency, backlog, throttling, OOMs and HPA ceilings. Include warm-cache steady state and competing workloads when validating the lower CPU reservations. Xlarge Parquet at 80% CPU now targets 9.6 cores per pod rather than 12; reaching its default three-replica ceiling can offset packing savings. Large defaults to two fixed replicas; customer overrides can differ.
