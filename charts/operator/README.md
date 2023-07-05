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
