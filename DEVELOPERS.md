We make use of Github actions and [chart-testing](https://github.com/helm/chart-testing) from the helm team. When developing locally you can create a kind cluster that supports custom images by running: `./setup-dev-cluster.sh`.

## Releasing

```sh
git checkout -b feature/bump_version
# update versions in charts/wandb/Chart.yaml
git push origin feature/bump_version
# merge PR after checks pass
```

## Snapshot tests

From the project root directory...

### Setup the dev cluster

```sh
./setup-dev-cluster.sh
```

### Build the Helm Charts

```sh
./snapshots.sh build
```

### See if tests generate expected values

The `test-configs/operator-wandb/__snapshots__` directory contains the __expected__ outputs
after running supplied values against the helm charts. This test is run by:

```sh
./snapshots.sh run
```

### Updated the expected test outputs

If you are __sure__ that generated values by the charts are correct and that the `__snapshots__`
values need updating then run:

```sh
./snapshots.sh update
```

### Tear it all down

Tear down what you built with:

```sh
./teardown-dev-cluster.sh
```
