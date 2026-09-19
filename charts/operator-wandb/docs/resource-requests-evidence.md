# Resource request evidence — September 2026

Source: [Managed Installs — Capacity & Sizing, fixed 30-day window](https://us5.datadoghq.com/dashboard/9vc-gz8-urw/managed-installs--capacity--sizing?from_ts=1787188854000&to_ts=1789780854000&live=false), queried read-only with PUP. Window: **2026-08-20 01:20 UTC to 2026-09-19 01:20 UTC**. Scope: `env:managed-install`, `cluster_audience:customer`, separately filtered by each standard `size`; small is partitioned by AWS/GCP/Azure. QA measurements are not included in the production cohort.

The collection completed 91 partitioned metric queries. At least one profiled service had 14 days of CPU/memory data in **215 customer-size cohorts**: 140 small, 24 medium, 12 large, 7 xlarge and 32 xxlarge. These are customer-size pairs, not necessarily 215 distinct customers; a deployment can change size during the month. Per-service and matching-allocation coverage is narrower, as shown below.

## Method and limits

- Container CPU usage (`kubernetes.cpu.usage.total`, nanocores converted to cores) and memory working set (`kubernetes.memory.working_set`, bytes converted to GiB) use the maximum across containers of a service per customer, then hourly maximum rollups. Mean series are also retained separately. **CPU P95 below means the 95th percentile of a customer's hourly container maxima**, then the largest customer P95 in the cohort; it is not a request-latency percentile or a raw per-pod percentile. Memory peak is the highest reported hourly maximum. Retention and sampling can miss short spikes.
- Require at least 336 reported hourly CPU/memory samples (14 days) per customer/service/size. Missing telemetry is excluded, never counted as zero. Fewer than three matching customers means no telemetry-based reduction.
- Match stable observed minimum requests and limits to the chart defaults throughout the available monthly allocation samples. This removes observed custom/changed minima; it cannot prove every replica had identical allocations. A larger custom replica can still influence a maximum, so these are conservative cohort bounds rather than exact per-pod profiles. Different chart versions and cloud hardware remain mixed when their allocation minima match. No customer identifiers are published here.
- For eligible ordinary services, the CPU starting point is 1.5 times the largest customer CPU P95, rounded up to 0.25 cores, with a 0.25-core floor (0.5 for app/API/glue/metric-observer/weave-trace). Memory starts at 1.25 times the observed peak, rounded up to a simple memory size (0.25, 0.5, 1, 2, 3, 4, 6, 8, 12, 16, 24, 32, 48, 64 GiB). These margins and floors are explicit policy choices. Do not raise requests above current defaults in this reduction profile; flag pressure for separate review. Preserve nondecreasing requests across tiers. All nine profiled services explicitly define all five tiers, including retained defaults. App xlarge/xxlarge retain defaults because xlarge coverage is sparse.
- Retain queue-worker and cache-heavy requests without representative queue/cache load evidence. The medium, large and xlarge Parquet/metadata-cache experiments below are explicit exceptions. Medium API memory and large API CPU also use explicit tuning choices rather than the formula. Retain all memory and CPU limits.
- HPA evidence joins `kubernetes_state.hpa.status_target_metric` with `spec_target_metric` by customer, controller, resource, target type and hour; compare observed/target ratios. Controller eligibility also requires at least 336 matched hours and a matching allocation cohort. Check `current_replicas`, `min_replicas`, and `max_replicas` to identify fixed bounds and ceilings. Rescale the worst customer/controller P95 ratio for the proposed request denominator. A ratio more than 1.25 times the other resource selects the 70% primary target; otherwise use 80%/80%. Fixed, protected and under-covered rows retain 80%/80%. Independently rolled-up hourly maxima do not prove which resource crossed first within an hour or caused latency.
- This is observational sizing, not a controlled load test. It does not establish burst CPU entitlement, horizontal scalability of caches, queue throughput, failover capacity, or absence of throttling/OOMs. HPA percentages may increase replicas, so smaller requests do not alone prove lower cost. Validate before rollout.

## Per-size evidence and decisions

N is matching customers with at least 14 days of data. CPU and memory observations below describe matching cohorts; `—` means insufficient/no metric evidence. Targets are CPU%/memory%; `fixed` means the rendered chart min=max, not an elastic controller. Requests are CPU/GiB. Retained rows are shown to make coverage gaps visible.

| Size | Service | N | Worst customer CPU P95 | CPU peak | Memory peak GiB | Proposed request | Pressure | HPA CPU/memory |
| --- | --- | ---: | ---: | ---: | ---: | --- | --- | --- |
| small | api | 140 | 1.67 | 4.09 | 7.99 | 1/2 | memory | 80/80 fixed |
| small | app | 28 | 0.06 | 0.54 | 0.86 | 0.5/2 | unknown | — |
| small | filemeta | 139 | 0.04 | 0.11 | 0.14 | 0.25/0.25 | memory | 80/70 |
| small | flat-run-fields-updater | 139 | 0.32 | 1.26 | 1.52 | 1/2 | memory | 80/80 |
| small | frontend | 139 | 0.04 | 0.39 | 0.05 | 0.25/0.25 | memory | 80/80 fixed |
| small | glue | 140 | 0.18 | 2.00 | 2.60 | 0.5/2 | unknown | — |
| small | history-updater | 2 | 0.06 | 0.45 | 1.71 | 1/1 | unknown | 80/80 |
| small | metric-observer | 139 | 0.15 | 0.39 | 0.27 | 0.5/0.5 | memory | 80/70 |
| small | parquet-metadata-cache | 0 | — | — | — | 4/16 | unknown | — |
| small | parquet | 140 | 0.92 | 4.10 | 15.99 | 1/8 | memory | 80/80 fixed |
| small | weave-trace-agent-scoring-worker | 9 | 0.02 | 0.71 | 0.39 | 1/3 | memory | 80/80 |
| small | weave-trace-worker | 9 | 0.02 | 0.75 | 0.41 | 1/4 | memory | 80/80 |
| small | weave-trace | 48 | 0.84 | 1.81 | 6.72 | 1/4 | cpu | 70/80 |
| small | weave | 140 | 0.49 | 5.01 | 16.00 | 1/8 | memory | 80/80 fixed |
| medium | api | 24 | 2.55 | 4.50 | 15.97 | 4/12 | balanced | 80/80 fixed |
| medium | app | 8 | 0.14 | 0.25 | 0.35 | 0.5/2 | unknown | — |
| medium | filemeta | 24 | 0.19 | 0.24 | 0.12 | 0.5/0.25 | memory | 80/70 |
| medium | flat-run-fields-updater | 23 | 1.01 | 3.53 | 4.00 | 1/2 | memory | 80/80 |
| medium | frontend | 24 | 0.21 | 0.31 | 0.06 | 0.5/0.25 | balanced | 80/80 |
| medium | glue | 24 | 0.64 | 1.57 | 2.93 | 1/4 | unknown | — |
| medium | history-updater | 0 | — | — | — | 1/1 | unknown | 80/80 |
| medium | metric-observer | 23 | 0.33 | 0.93 | 0.49 | 0.75/1 | cpu | 70/80 |
| medium | parquet-metadata-cache | 0 | — | — | — | 8/64 | unknown | — |
| medium | parquet | 24 | 3.14 | 22.91 | 41.44 | 8/64 | cpu | 80/80 fixed |
| medium | weave-trace-agent-scoring-worker | 1 | 0.01 | 0.49 | 0.31 | 1/3 | unknown | 80/80 |
| medium | weave-trace-worker | 1 | 0.01 | 0.52 | 0.32 | 1/4 | unknown | 80/80 |
| medium | weave-trace | 9 | 0.42 | 1.24 | 2.05 | 1/4 | cpu | 70/80 |
| medium | weave | 23 | 0.14 | 1.36 | 20.84 | 2/24 | memory | 80/80 |
| large | api | 11 | 2.86 | 7.12 | 15.98 | 4/16 | balanced | 80/80 fixed |
| large | app | 7 | 0.06 | 0.23 | 0.36 | 0.5/2 | unknown | — |
| large | filemeta | 12 | 0.03 | 0.22 | 0.11 | 0.5/0.25 | memory | 80/70 |
| large | flat-run-fields-updater | 12 | 0.54 | 1.13 | 1.72 | 1/3 | memory | 80/80 |
| large | frontend | 12 | 0.07 | 0.47 | 0.05 | 0.5/0.25 | memory | 80/70 |
| large | glue | 12 | 0.82 | 4.69 | 0.46 | 1.25/4 | unknown | — |
| large | history-updater | 0 | — | — | — | 1/1.5 | unknown | 80/80 |
| large | metric-observer | 12 | 0.19 | 0.28 | 0.18 | 0.75/1 | memory | 80/70 |
| large | parquet-metadata-cache | 0 | — | — | — | 8/64 | unknown | — |
| large | parquet | 12 | 2.09 | 15.83 | 63.99 | 8/64 | memory | 80/80 fixed |
| large | weave-trace-agent-scoring-worker | 0 | — | — | — | 1/3 | unknown | 80/80 |
| large | weave-trace-worker | 0 | — | — | — | 1/4 | unknown | 80/80 |
| large | weave-trace | 4 | 0.36 | 0.80 | 0.93 | 1/4 | cpu | 70/80 |
| large | weave | 12 | 0.76 | 2.68 | 4.91 | 3/24 | memory | 80/80 |
| xlarge | api | 6 | 5.31 | 8.99 | 15.73 | 6/16 | cpu | 80/80 fixed |
| xlarge | app | 1 | 0.19 | 0.36 | 0.35 | 4/8 | unknown | — |
| xlarge | filemeta | 7 | 0.14 | 0.18 | 0.10 | 0.5/0.25 | memory | 80/70 |
| xlarge | flat-run-fields-updater | 7 | 1.23 | 2.16 | 4.07 | 1/6 | balanced | 80/80 |
| xlarge | frontend | 7 | 0.06 | 0.32 | 0.05 | 0.5/0.25 | memory | 80/70 |
| xlarge | glue | 7 | 0.59 | 2.80 | 1.66 | 1.25/4 | unknown | — |
| xlarge | history-updater | 0 | — | — | — | 1/3 | unknown | 80/80 |
| xlarge | metric-observer | 7 | 0.17 | 0.52 | 0.26 | 0.75/1 | balanced | 80/80 |
| xlarge | parquet-metadata-cache | 1 | 0.16 | 0.58 | 1.44 | 8/64 | unknown | — |
| xlarge | parquet | 7 | 17.81 | 24.05 | 63.98 | 12/64 | balanced | 80/80 |
| xlarge | weave-trace-agent-scoring-worker | 0 | — | — | — | 1/3 | unknown | 80/80 |
| xlarge | weave-trace-worker | 0 | — | — | — | 1/4 | unknown | 80/80 |
| xlarge | weave-trace | 0 | — | — | — | 1/6 | unknown | 80/80 |
| xlarge | weave | 7 | 0.16 | 1.27 | 2.38 | 3/24 | memory | 80/80 |
| xxlarge | api | 24 | 6.54 | 10.33 | 16.00 | 6/16 | balanced | 80/80 fixed |
| xxlarge | app | 20 | 0.68 | 2.05 | 0.49 | 4/8 | unknown | — |
| xxlarge | filemeta | 32 | 0.41 | 0.63 | 0.16 | 0.75/0.25 | memory | 80/70 |
| xxlarge | flat-run-fields-updater | 29 | 3.60 | 3.84 | 8.00 | 1/6 | cpu | 80/80 |
| xxlarge | frontend | 32 | 0.34 | 0.95 | 0.07 | 0.75/0.25 | balanced | 80/80 |
| xxlarge | glue | 29 | 1.45 | 3.85 | 4.21 | 2.25/6 | unknown | — |
| xxlarge | history-updater | 2 | 0.49 | 1.19 | 3.96 | 1/3 | unknown | 80/80 |
| xxlarge | metric-observer | 32 | 2.69 | 3.32 | 2.96 | 1/4 | cpu | 70/80 |
| xxlarge | parquet-metadata-cache | 5 | 0.73 | 11.83 | 21.08 | 15/64 | unknown | — |
| xxlarge | parquet | 20 | 12.57 | 28.21 | 63.33 | 15/64 | cpu | 80/80 |
| xxlarge | weave-trace-agent-scoring-worker | 3 | 0.02 | 0.65 | 0.33 | 1/3 | memory | 80/80 |
| xxlarge | weave-trace-worker | 3 | 0.20 | 0.84 | 0.62 | 1/4 | memory | 80/80 |
| xxlarge | weave-trace | 17 | 0.36 | 1.86 | 2.28 | 1/6 | memory | 80/70 |
| xxlarge | weave | 29 | 0.91 | 3.86 | 63.58 | 3/48 | balanced | 80/80 |

## Findings that constrain reductions

- Small API and Parquet memory peaks approached their limits. Their memory requests are retained; fixed replica bounds need separate attention under pressure.
- Large and xlarge Parquet approached 64 GiB, so their memory requests remain 64 GiB. Their 8-CPU and 12-CPU requests are compaction experiments; xlarge's 12 CPUs is a chosen contention margin, not a formula-derived safe minimum. Xxlarge retains 15 CPUs. Some reported CPU maxima exceed configured limits, so these telemetry values must not be treated as precise quota or throughput measurements.
- Large/xlarge metadata-cache requests 8 CPUs / 64 GiB experimentally, retaining the chart's memory requests and 15-CPU / 64-GiB limits. Coverage is zero and one matching customer respectively. Five matching xxlarge customers peaked at 21.08 GiB; that does not justify extrapolating a smaller memory reservation across tiers. Medium remains at 8 CPUs / 64 GiB; small and xxlarge explicitly retain defaults. Memory/runtime limits and cache configuration remain unchanged; validate warm caches and CPU contention.
- Medium API memory at 12 GiB and large API CPU at 4 cores are explicit tuning choices. The observed medium API peak was 15.97 GiB; the reservation is below that peak while its 16-GiB limit remains unchanged. These API workloads have fixed replica bounds, so HPA percentages cannot provide additional replicas.
- Xxlarge API, flat-run-fields-updater and Weave showed pressure. This profile does not solve their replica ceilings or increase limits.
- Weave Trace xlarge has no matching telemetry cohort. Its explicit profile entry retains the chart's 1-CPU / 6-GiB requests and 80/80 HPA targets; it does not claim a measured reduction for that tier.
- History-updater, newer Weave workers, and several metadata-cache tiers have sparse coverage. Low activity is not sufficient evidence to lower their queue/cache capacity.
- Frontend and filemeta have low sustained CPU and working sets across the observed tiers. Their lower requests are candidates for packing tests, with existing limits preserved.

Repeat the same metric families, hourly rollups and cohort rules for future reviews; compare the resulting latency/queue behavior under load rather than repeatedly applying a fixed percentage reduction to requests.
