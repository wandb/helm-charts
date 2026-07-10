# orchestratordev/orchestrator-charts

**orchestratordev/orchestrator-charts** is your go-to repository for cutting-edge Helm charts tailored specifically for streamlined deployment and management of orchestrator applications. Whether you're automating your Kubernetes environment or enhancing your continuous deployment workflows, these charts are designed to provide robust, scalable, and flexible solutions right out of the box.

Features:

- **Easy Deployment**: Simplified Helm charts for seamless setup and configuration.
- **Customizability**: Highly configurable templates to match your unique infrastructure needs.
- **Scalability**: Optimized for high-performance and scalable deployments.
- **Active Development**: Continuously updated to keep up with the latest best practices and features in the orchestrator ecosystem.

Get started with orchestratordev/orchestrator-charts today and supercharge your Kubernetes deployments!

## Workspace-engine topology

By default the chart runs a single `workspace-engine` Deployment in which every pod serves the Connect API **and** runs all reconcile controllers (`SERVICES` is empty, which the engine treats as "run everything").

For independent scaling, the chart can split the engine into two Deployments:

```yaml
workspace-engine:
  replicaCount: 2
  env:
    SERVICES: connect

workspace-engine-controllers:
  install: true # off by default
  replicaCount: 4
```

- `workspace-engine` keeps the Kubernetes Service (`<release>-workspace-engine:8086`), so the web app, identity service, and inbound webhooks continue to route to it unchanged. Set `SERVICES: connect` so it serves only the API.
- `workspace-engine-controllers` runs `SERVICES: controllers` (the default for this block): every background worker and no API server. It exposes no Service.

This is the standard web + worker pattern: one image, two Deployments. The API deployment deliberately keeps the plain `workspace-engine` name rather than something like `workspace-engine-api`, because it owns the engine's network identity — the Service name `<release>-workspace-engine` is what identity's `CONNECT_URL`, the web app, and the ingress `/engine` route all resolve to. Whatever answers the API *is* the workspace-engine to the rest of the system; the controllers are a headless worker fleet that nothing addresses. Keeping the name also means enabling or disabling the split never renames the Service, so routing is identical in both topologies and existing values files keep working.

### Version requirements and rollback

The `controllers` and `connect` values for `SERVICES` require a workspace-engine image containing the service group aliases (ctrlplane `c48ced3` / PR #79 or later).

On older images, `SERVICES: controllers` matches nothing: the pods pass health checks but process **no work**, silently stalling all deployments. Therefore:

- Enable the split and bump the image tag in the **same** change.
- Never roll the image back past `c48ced3` while the split is enabled — roll back by reverting the entire change (topology values + tag together).

Disabling the split (`install: false` on `workspace-engine-controllers`, remove the `SERVICES` override) is always safe: the single Deployment reverts to running everything, on any image version.
