# Native history import workers

The chart provisions a suspended `native-history-import` CronJob under Glue.
It requires the Core native-Parquet import stack starting at
[core#57623](https://github.com/wandb/core/pull/57623), including its database
migration and `NATIVE_HISTORY_IMPORT_WORKER` task definition. Older images
cannot run this task. Deploy the same compatible image and history-reader
configuration to the API and Glue before enabling workers.

## Enable and scale

Keep import admission paused while deploying and validating the worker.
The supported initial destination is the on-prem operator history route with
V1 run metadata; provisioning workers does not broaden API eligibility.

```yaml
global:
  glue:
    enabled: true
glue:
  cronJobs:
    native-history-import:
      enabled: true
      parallelism: 1
      completions: 1
```

Every minute, Kubernetes starts a Job unless its preceding Job is still active.
Each pod runs Glue in execute-once mode and claims at most one durable SQL job.
An empty queue lets the pod exit. Increase both `parallelism` and `completions`
to the desired number of workers per scheduled Job. SQL admission limits can
restrict how many claims succeed; those limits do not create pods.

The worker inherits Glue's image, service account, configuration, credentials,
workload identity and history-store settings. Its per-pod limits are 2 CPUs,
2 GiB memory and 1 GiB ephemeral storage, with a 15-minute Job deadline and
30-second termination grace period. The metadata pool allows five connections.
Three concurrent workers therefore allow up to 6 CPUs, 6 GiB memory and 15
metadata connections. Account for existing application load before increasing
concurrency. Read-size limits in the task must fit its memory limit.

## Recovery and health

SQL leases coordinate claims and prevent expired owners from publishing.
Kubernetes does not retry failed pods (`backoffLimit: 0`); later scheduled
workers can claim jobs according to the durable job retry and lease rules.
A deadline or OOM can interrupt a large import, so test representative large
files before choosing limits. Permanent job failures still need investigation.

Check Job completion and pod termination reasons, worker logs, and the import
status API. A successful pod can have found no work: also check queued-job age
and whether submitted jobs reach success and normal history readback. Lease
renewal proves ownership, not progress through a large file. This chart does
not add alerts or per-step progress metrics.

For rollback, pause import admission/processing through the import control API,
then set `enabled: false` to suspend future Jobs. Suspension alone does not stop
an already running Job. Let it finish or terminate that Job after pausing, and
check durable job status before resuming. Keep admission paused until a scratch
import and normal-reader readback succeed with the deployed worker.
