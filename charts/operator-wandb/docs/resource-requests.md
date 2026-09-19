# Optional resource request profile

Pass `-f values-resource-requests-conservative.yaml` to opt in. Normal chart defaults are unchanged. The profile provides candidate settings for workload-specific validation; it does not guarantee throughput or capacity.

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

Medium and large Parquet request 8 CPUs / 64 GiB; xlarge requests 12 CPUs / 64 GiB. Metadata-cache requests 8 CPUs / 64 GiB at those sizes. Both services retain 15-CPU / 64-GiB limits. Small and xxlarge retain their defaults. `GOMEMLIMIT` and `GOMAXPROCS` still derive from limits.

With two Parquet replicas and one metadata-cache replica, the large profile reduces CPU requests by 21 cores and xlarge by 13 cores compared with defaults. Memory reservations remain unchanged. Actual node reductions depend on placement, replica counts, supporting services and rollout headroom.

These settings require contention and sustained-load testing at each deployment size. In particular, lower API memory requests do not reduce its memory limit, and fixed replica bounds cannot provide additional scale-out capacity.

## Percentage autoscaling

HPA targets use Kubernetes `Utilization` percentages of the new full-pod requests. There is no absolute-target conversion. Both CPU and memory remain configured; Kubernetes uses the larger replica recommendation. Targets are 70% or 80%, depending on service and size. These are configurable policy thresholds, not guaranteed latency boundaries.

For example, medium metric-observer uses CPU 70% / memory 80%, while filemeta uses CPU 80% / memory 70%. A smaller request lowers the absolute scale-out threshold intentionally. Fixed min=max workloads cannot add replicas regardless of the percentage; their bounds remain unchanged and their targets stay at 80%/80%. The profile does not turn on autoscaling for app, glue or metadata-cache.

Queue workers and cache-heavy services retain their existing resource targets rather than interpreting low idle CPU or resident cache memory as evidence for new scaling behavior. KEDA keeps its configured queue/resource triggers, percentages, authentication and replica bounds. A custom KEDA utilization trigger still uses the new request denominator; its absolute scale-out point can therefore change. Service-level custom percentage targets retain precedence over size presets. Review custom requests and sidecars because HPA utilization includes every container's requests and usage.

## Placement and validation

Required hostname anti-affinity separates Parquet and metadata-cache from each other and from Parquet replicas at every size. It selects both service names within the namespace, including other releases. At least one eligible node per combined replica is required; a rolling surge can need another node. Preserve the selector if changing service name labels or affinity. Required anti-affinity keeps these workloads separate regardless of worker size. This profile does not set a PriorityClass. Priority preemption can make room for pending pods; it does not evict neighbors when a running Parquet pod needs more CPU. Required separation does not eliminate contention with other services.

Before enrollment, inspect effective HPA/KEDA maxima or fixed replica counts for both services, including user overrides and other matching releases. Their combined maxima set the number of separate eligible workers needed at peak replica count; add rolling-surge and failure headroom. Check autoscaler node ceilings, taints, node selectors, volume zones and available CPU/memory. A sufficient total node count alone does not establish schedulability. Preserve customer replica settings rather than lowering them to hit a packing target.

The profile enables preferred hostname anti-affinity for frontend, filemeta and metric-observer replicas of the same release. The base chart's `preferredPodAntiAffinity` defaults to `false` when omitted, so it adds no preferred anti-affinity unless enabled. Explicit `affinity` takes precedence. Jobs and CronJobs do not inherit the service flag; enable it separately with `jobs.<name>.preferredPodAntiAffinity: true` or `cronJobs.<name>.preferredPodAntiAffinity: true`. Parquet and metadata-cache use explicit required anti-affinity, independently of this flag.

After building dependencies, run `python scripts/validate_resource_requests_profile.py` with Helm and PyYAML installed. It lints and renders all five sizes with normal and synthetic KEDA controllers, checks the rounded requests and percentage targets, and rejects unexpected changes to limits, replica bounds, queues and unrelated objects. Render tests do not establish performance. Test the revised profile under representative concurrent load, sustained pressure, bursts, and worker loss before rollout; watch latency, backlog, throttling, OOMs and HPA ceilings. Include warm-cache steady state and competing workloads when validating the lower CPU reservations. Xlarge Parquet at 80% CPU now targets 9.6 cores per pod rather than 12; reaching its default three-replica ceiling can offset packing savings. Large defaults to two fixed replicas; customer overrides can differ.

## Graceful consolidation

The opt-in profile supplies per-service `safe-to-evict-local-volumes` annotations
for the nine sized services and six supporting services (anaconda2, executor,
flat-run-fields-updater, history-updater, mcp-server and Weave). Supporting
services keep their existing requests and replica counts. The allowlist covers
only generated `wandb-ca-certs-root` certificates and `datadog-socket`, plus:

- API, glue, mcp-server and Weave Trace: request-scoped `temp-dir` scratch space.
- Weave: `temp-dir` and its disposable `cache`; the existing cache-clear sidecar
  already removes cached filesystem entries under `/vol/weave/cache`.

Replacement pods retain these annotations. Additional customer local volumes
are not exempted; do not replace the list with blanket `safe-to-evict: true`.
Persistent volumes, install switches and shutdown grace periods are unchanged.
Jobs and CronJobs keep their own pod annotations.

App and metadata-cache use `maxUnavailable: "0%"`. This blocks autoscaler
eviction, including installations running a singleton. After confirming
redundancy, a customer can override the budget to permit an eviction. It does not add
replicas or make a singleton highly available. Deployment rollouts retain
`maxSurge: 1` and `maxUnavailable: 0`; PDBs do not govern Deployment rollouts.
When overriding the disruption budget, a custom `minAvailable` budget must
clear `maxUnavailable`.

Allow temporary surge nodes during rollouts. Validate continuous writes and
reads, completed-run readback, readiness, termination and automatic scale-down
before treating a smaller node count as steady state. Match Cluster Autoscaler
to the cluster's Kubernetes minor version. A manual drain is not evidence that
autoscaler consolidation works.
