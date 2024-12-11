We make use of Github actions and [chart-testing](https://github.com/helm/chart-testing) from the helm team. When developing locally you can create a kind cluster that supports custom images by running: `./dev-kind-cluster.sh`.

## Releasing

```shell
git checkout -b feature/bump_version
# update versions in charts/wandb/Chart.yaml
git push origin feature/bump_version
# merge PR after checks pass
```
