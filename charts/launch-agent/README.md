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
