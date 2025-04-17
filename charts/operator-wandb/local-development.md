# Helm Chart Operator Development Guide

This guide provides instructions for local development and testing of the Helm chart operator for the `wandb/helm-charts` repository. It includes setup instructions, development workflow, and guidelines for contributing to the repository.

## Prerequisites

- Helm (3.x+)
- kubectl (configured with access to your Kubernetes cluster)
- AWS CLI (configured with the necessary permissions)
- Azure CLI
- Google Cloud SDK

## Setup

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

## Contributing

After testing your changes locally, submit a pull request with your modifications. Ensure your commits are well-documented, and your PR includes a summary of the changes and any testing performed.
