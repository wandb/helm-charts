# Upgrading the Helm Chart and wandb Server Version

This guide describes how to upgrade the Helm module and wandb server version in your deployment.

## Upgrading the Helm Chart

1. Update the Helm repo to fetch the latest charts:

```bash
   helm repo update
```
2. Check the available versions of the wandb Helm chart:

```bash
   helm search repo wandb --versions
```

3. Choose the desired version and upgrade the Helm release:

``` bash
   helm upgrade --namespace=wandb wandb wandb/wandb --version <desired_version> --set license=$LICENSE --set bucket=$BUCKET --set bucketRegion=$BUCKET_REGION
```
   Replace <desired_version> with the version you want to upgrade to.

## Upgrading the wandb Server Version

1. Update the `values.yaml` file by setting the desired wandb server image tag:
```yaml
   image:
     repository: wandb/local
     pullPolicy: always
     tag: "<desired_wandb_version>"
```

   Replace <desired_wandb_version> with the version you want to upgrade to.

2. Apply the changes by upgrading the Helm release:

```bash
   helm upgrade --namespace=wandb wandb ./charts/wandb --set license=$LICENSE --set bucket=$BUCKET --set bucketRegion=$BUCKET_REGION
```

3. Monitor the deployment progress to ensure the new version is running:

```bash
   kubectl -n wandb get pods
```

4. Verify the upgraded wandb server version by checking the logs:

```bash
   kubectl -n wandb get po
   kubectl -n wandb logs <wandb_pod_name>
```

   Replace <wandb_pod_name> with the name of the wandb pod in your deployment.
