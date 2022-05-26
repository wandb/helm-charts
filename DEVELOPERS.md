We make use of Github actions and [chart-testing](https://github.com/helm/chart-testing) from the helm team.  When developing locally you can create a kind cluster that supports custom images by running: `./dev-kind-cluster.sh`.

## Releasing

```shell
helm package wandb
helm push wandb/wandb-$VERSION.tgz oci://us-central1-docker.pkg.dev/wandb-production/charts/wandb
```