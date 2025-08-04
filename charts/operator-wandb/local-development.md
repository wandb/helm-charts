# Helm Chart Operator Development Guide

This guide provides instructions for local development and testing of the Helm chart operator for the `wandb/helm-charts` repository. It includes setup instructions, development workflow, and guidelines for contributing to the repository.

## Prerequisites

- Helm (3.x+)
- kubectl (configured with access to your Kubernetes cluster)
- Docker (for local development with kind)
- kind (for local Kubernetes clusters)
- Tilt (for local development workflow)
- AWS CLI (configured with the necessary permissions, if using AWS)
- Azure CLI (if using Azure)
- Google Cloud SDK (if using GCP)

# Local Pipeline Development and Troubleshooting

To test the pipeline locally, comment out all but the test you want to run in
the `.github/workflows/test-operator-wandb.yaml` testing matrix, and run

```bash
act pull_request -s LICENSE="test" -W '.github/workflows/test-operator-wandb.yaml' --container-architecture linux/amd64
```

To test the `ct install` that gets run in the pipeline.

You can then exec into the `chart-testing-***-control-plane` docker container, run `bash` and `kubectl` to
diagnose any issues the tests are facing

`act` is a tool that allows you to run GitHub Actions workflows locally. It
simulates the GitHub Actions environment on your local machine.

`ct` (chart-testing), which is a tool that helps validate Helm charts by
running a series of checks and tests including linting and installation tests.

## Local Development with kind and Tilt

This section describes how to set up a local development environment using kind (Kubernetes IN Docker) and Tilt. This approach allows you to quickly iterate on changes without needing access to a cloud-based Kubernetes cluster.

### 1. Create a Local kind Cluster

The repository includes a script to create a local kind cluster with a local Docker registry:

```bash
# Run the script to create a kind cluster with default settings
./dev-kind-cluster.sh

# Or customize the cluster with various options
./dev-kind-cluster.sh --name my-cluster --ingress --http-port 8080
```

By default, this script:
- Creates a local Docker registry container on port 5001
- Creates a kind cluster named "kind" with one control-plane node and one worker node
- Configures the cluster to use the local registry
- Creates a ConfigMap to document the local registry

The script now supports several configuration options:

| Option | Description | Default |
|--------|-------------|---------|
| `-n, --name NAME` | Set the cluster name | `kind` |
| `-r, --no-registry` | Don't create a local registry | Registry is created |
| `-i, --ingress` | Install and configure nginx-ingress controller | Not installed |
| `--http-port PORT` | Set HTTP port for ingress | `80` |
| `--https-port PORT` | Set HTTPS port for ingress | `443` |
| `-h, --help` | Display help message | |

Examples:
```bash
# Create a cluster named 'dev-cluster'
./dev-kind-cluster.sh --name dev-cluster

# Create a cluster without a local registry
./dev-kind-cluster.sh --no-registry

# Create a cluster with nginx-ingress controller
./dev-kind-cluster.sh --ingress

# Create a cluster with custom ingress ports
./dev-kind-cluster.sh --ingress --http-port 8080 --https-port 8443
```

### 2. Configure Tilt

Create a `tilt-settings.json` file in the root directory of the repository. You can use the sample file as a starting point:

```bash
# Copy the sample settings file
cp tilt-settings.sample.json tilt-settings.json
```

The `tilt-settings.json` file allows you to configure:
- Allowed Kubernetes contexts (should include "kind-kind" for kind clusters)
- Whether to install Minio (recommended for local development)
- Whether to install Ingress
- Which test configuration to use (e.g., "default", "weave-trace", "separate-pods")
- Additional values to override

Example `tilt-settings.json`:
```json
{
  "allowedContexts": ["kind-kind"],
  "installMinio": true,
  "installIngress": false,
  "values": "default",
  "additionalValues": {}
}
```

### 3. Run Tilt

Once your kind cluster is running and Tilt is configured, you can start Tilt:

```bash
# Start Tilt with explicit context
tilt up --context=kind-kind
```

Tilt will:
- Deploy Minio (if enabled in your settings)
- Deploy Ingress (if enabled in your settings)
- Deploy the operator-wandb chart with the specified test configuration
- Set up port forwarding for various services
- Watch for changes and automatically redeploy when files change

You can access the Tilt UI in your browser to monitor the deployment status and view logs.

### 4. Deploy a Test Configuration

The repository includes several test configurations in the `test-configs/operator-wandb/` directory:

- `default.yaml`: Basic configuration with Minio, MySQL, and Redis
- `executor-enabled.yaml`: Configuration with executor enabled
- `runs-v2-bufstream.yaml`: Configuration with runs-v2 and bufstream
- `separate-pods.yaml`: Configuration with separate pods
- `weave-trace.yaml`: Configuration with weave-trace enabled

To deploy a different test configuration, update the `values` field in your `tilt-settings.json` file and restart Tilt:

```bash
# Edit tilt-settings.json to change the "values" field
# For example, to use the weave-trace configuration:
# "values": "weave-trace"

# Restart Tilt with explicit context
tilt up --context=kind-kind
```

### 5. Accessing the Deployed Services

Tilt automatically sets up port forwarding for the deployed services. By default:
- App service: http://localhost:8080
- Console service: http://localhost:8082
- Weave-trace service (if enabled): http://localhost:8722

You can customize these ports in your `tilt-settings.json` file.

## Testing with an existing Operator Managed Cluster

### 1. Cloud Provider Login

#### AWS

Update your kube-context for the EKS cluster:

```bash
aws eks update-kubeconfig --name smooth-operator --region us-west-2
```

#### Azure

Log in to Azure CLI:

```bash
az login
az account set --subscription <Subscription_ID>
az aks get-credentials --resource-group <Resource_Group_Name> --name <AKS_Cluster_Name>
```

#### GCP

Authenticate with the Google Cloud SDK:

```bash
gcloud auth login
gcloud container clusters get-credentials YOUR_CLUSTER_NAME --zone YOUR_ZONE --project YOUR_PROJECT
```

### 2. Clone the Helm Charts Repository

Clone the `wandb/helm-charts` repository:

```bash
git clone https://github.com/wandb/helm-charts.git
cd helm-charts
```

### 3. Initial Setup for Development

Extract the current values from the deployed Helm chart and scale down the `wandb-controller-manager` deployment:

```bash
helm get values wandb > secret.operator-spec.yaml
kubectl scale --replicas=0 deployment -n wandb wandb-controller-manager
```

### 4. Develop and Test Your Changes

After extracting the current chart values into `secret.operator-spec.yaml`, you can start making your changes to the chart or the operator specifications.

#### Building Dependencies

Before deploying your changes, ensure that any chart dependencies are updated:

```bash
helm dependency build ./charts/operator-wandb
```

#### Upgrading the Helm Release

To apply your changes, upgrade the Helm release with your modified specifications:

```bash
# Helm template command
helm template wandb \
    ./charts/operator-wandb -f ./secret.operator-spec.yaml > secret.template.yaml

# Helm upgrade command
helm upgrade \
    --install wandb \
    ./charts/operator-wandb -f ./secret.operator-spec.yaml

```

Helm diff example

```bash
helm diff revision wandb 109 107
```

### 5. Finalizing Development

After completing your development work:

1. Ensure to increment the version in `Chart.yaml` of your Helm chart, e.g., `0.10.43`.
2. Scale the `wandb-controller-manager` deployment back up:

   ```bash
   kubectl scale --replicas=1 deployment -n wandb wandb-controller-manager
   ```

## Contributing

After testing your changes locally, submit a pull request with your modifications. Ensure your commits are well-documented, and your PR includes a summary of the changes and any testing performed.
