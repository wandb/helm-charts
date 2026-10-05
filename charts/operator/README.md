# Weights & Biases Operator

# Operator

## Install

```
helm repo add wandb https://wandb.github.io/helm-charts
helm upgrade --install operator wandb/operator
```

## Install from source

```
git clone https://github.com/wandb/helm-charts.git
cd helm-charts
helm upgrade --namespace=wandb --create-namespace --install operator .
```

## Traefik middleware permissions

Operator chart 1.4.10 adds `create`, `delete`, `get`, `list`, `patch`, `update`, and
`watch` for `middlewares` in the `traefik.io` API group. These permissions support
reconciliation of the operator-wandb chart's IP allowlist. Kubernetes Ingress
permissions already exist. The chart does not grant access to other Traefik CRDs.

The default ClusterRole grants these permissions across namespaces. With
`namespaceIsolation.enabled: true`, Roles grant them only in the release namespace
and `namespaceIsolation.additionalNamespaces`. Existing bindings use the manager's
configured ServiceAccount, including a supplied `manager.serviceAccount.name`.
If you override `role.rules`, include the middleware rule in your replacement list.

Upgrade the installed operator chart to a release containing these permissions
before enabling `global.traefikIngress` in operator-wandb. The Traefik CRDs and
controller must already be installed. Rendering RBAC does not update a running
operator's permissions until the chart is upgraded.

Run the RBAC unit tests and snapshots with:

```sh
helm unittest charts/operator
./snapshots.sh run operator
```
