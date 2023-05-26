# W&B Launch Agent

This chart deploys the W&B Launch Agent to your Kubernetes cluster.

The launch agent is a Kubernetes Deployment that runs a container that connects to the W&B API and watches for new runs in one or more launch queues. When the agent pops a run off the queue(s), it will launch a Kubernetes Job to execute the run on the W&B user's behalf.

To deploy an agent, you will need to specify the following values:

- `agent.apiKey`: Your W&B API key
- `launchConfig`: The literal contents of a launch agent config file that will be used to configure the agent. See the [launch agent docs](https://docs.wandb.ai/guides/launch/run-agent) for more information.

You will likely want to modify the variable `agent.resources.limits.{cpu,mem}`, which default to `1000m`, and `1Gi` respectively.

You can provide these values by modifying the contents of [`values.yaml`](values.yaml) or by passing them in as command line arguments to `helm install`, e.g.

By default, this chart will also install [volcano](https://volcano.sh), but this can be disabled by setting `volcano=false`.

```bash
helm install <package-name> <launch-agent-chart-path> --set agent.apiKey=<your-api-key> --set-file launchConfig=<path-to-launch-config.yaml>
```

## Chart variables

Below is a table describing chart variables, their type, whether the user is required to provide a value, the default value, and a description of how the variable is used.

| Variables | Type | Required | Default | Description |
|--------|-----|------|--|-------|
| `agent.apiKey` | string | **Yes** | n/a | W&B API key to be used by the agent. |
| `agent.Image` | string | No | `wandb/launch-agent-dev:latest` | Container image for the agent.
| `agent.imagePullPolicy` | string | No | Always | Pull policy for the agent container image.
| `agent.resources` | object | No | Limit to 1 CPU, 1Gi RAM. | [Pod spec resources block](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/) for the agent.
| `launchConfig` | string | **Yes** | n/a | Launch agent configuration file contents. This config will be mounted at `/home/launch_agent/.config/wandb` in the agent container. For more details on how this config is structured, see [these docs](https://docs.wandb.ai/guides/launch/run-agent).
| `gitCreds` | string | No | `null` | If set, the conents of this string will be stored in a k8s secret and then mounted in the agent container at `~/.git-credentials` and used to grant the agent permission to clone private repositories via https. For more information on what the contents of this file should look like, see the [official git documentation](https://git-scm.com/docs/git-credential-store#_storage_format).
| `volcano` | bool | No | `true` | Controls whether the volcano scheduler should be installed in your cluster along with the agent. Set to `false` to disable volcano install.
