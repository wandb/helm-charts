# W&B Launch Agent

This chart deploys the W&B Launch Agent to your Kubernetes cluster.

The launch agent is a Kubernetes Deployment that runs a container that connects to the W&B API and watches for new runs in one or more launch queues. When the agent pops a run off the queue(s), it will launch a Kubernetes Job to execute the run on the W&B user's behalf.

To deploy an agent, you will need to specify the following values in [`values.yaml`](values.yaml):

- `agent.apiKey`: Your W&B API key
- `agent.image`: The container image to use for the agent (default: `wandb/launch-agent-dev:latest`)
- `namespace`: The namespace to deploy the agent into (default: `wandb-launch`)
- `launchConfig.base_url`: URL of your W&B server (default: `https://api.wandb.ai`)
- `launchConfig.entity`: W&B entity (user or team) name (default: `"entity-name"`)
- `launchConfig.queues`: List of queues to poll (default: `["default"]`)
- `launchConfig.builder.type`: Container build config (`kaniko` or `noop`) (default: `docker`)

You will likely want to modify the variable `agent.resources.limits.{cpu,mem}`, which default to `1000m`, and `1Gi` respectively.

By default, this chart will also install [volcano](https://volcano.sh)
- `volcano`: Set to `false` to disable volcano install (default: `true`)

You can modify the values directly in the `values.yaml` file or provide them as command line arguments when running `helm install`, for example:

```bash
helm install <package-name> <launch-agent-chart-path> --set agent.apiKey=<your-api-key>
```

Here is an example with a `values.yaml`

```bash
helm upgrade --namespace=wandb --create-namespace --install wandb-launch wandb/launch-agent -f ./values.yaml --namespace=wandb-launch
```

## Chart variables
The table below describes all the available variables in the chart:

| Variable                      | Type   | Required | Default                           | Description                                                                                                                                    |
| ----------------------------- | ------ | -------- | --------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| `agent.apiKey`                | string | **Yes**  | n/a                               | W&B API key to be used by the agent.                                                                                                            |
| `agent.image`                 | string | No       | `wandb/launch-agent-dev:latest`   | Container image for the agent.                                                                                                                  |
| `agent.imagePullPolicy`       | string | No       | `Always`                          | Pull policy for the agent container image.                                                                                                      |
| `agent.resources`             | object | No       | Limit to 1 CPU, 1Gi RAM          | Pod spec resources block for the agent.                                                                                                         |
| `namespace`                   | string | No       | `wandb-launch`                    | The namespace to deploy the agent into.                                                                                                         |
| `launchConfig.base_url`       | string | **Yes**  | `https://api.wandb.ai`           | URL of your W&B server.                                                                                                                         |
| `launchConfig.entity`         | string | **Yes**  | `"entity-name"`                   | W&B entity (user or team) name.                                                                                                                 |
| `launchConfig.max_jobs`       | int    | **Yes**  | `-1`                              | Max number of concurrent runs to perform.                                                                                                       |
| `launchConfig.queues`         | list   | **Yes**  | `["default"]`                     | List of queues to poll.                                                                                                                         |
| `launchConfig.environment.type` | string | No      | `local`                           | Cloud environment config (`aws` or `gcp`).                                                                                                      |
| `launchConfig.registry.type`   | string | No      | `local`                           | Container registry config (`ecr` or `gcr`).                                                                                                     |
| `launchConfig.builder.type`    | string | No      | `docker`                          | Container build config (`kaniko` or `noop`).                                                                                                    |
| `volcano`                     | bool   | No       | `true`                            | Controls whether the volcano scheduler should be installed in your cluster along with the agent. Set to `false` to disable volcano installation. |
| `gitCreds`                    | string | No       | `null`                            | Contents of a git credentials file.                                                                                                             |
| `serviceAccount.annotations`  | object | No       |                                   | Annotations for the wandb service account.                                                                                                      |
| `azureStorageAccessKey`       | string | No       | ""                                | Azure storage access key required for kaniko to acces build contexts in azure blob storage.                                                     |
