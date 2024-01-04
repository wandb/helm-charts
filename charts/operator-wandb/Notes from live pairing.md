# Notes from live pairing

## feedback for codespaces
  - add extensions
  - login command should say what it is doing

## working notes for helm development
```
# connect kubectl to your cluster and make sure it is selected
kubectl config get-contexts

# Get current details from Helm
helm ls -aA

# make changes in operator-wandb helm chart

# optional, but good to do
helm dependency update ./charts/operator-wandb
helm dependency build ./charts/operator-wandb

# upgrade helm
helm upgrade --namespace=default \
    --create-namespace \
    --install wandb \
    ./charts/operator-wandb

# Use this to get the curent spec of the wandb deployment
kubectl get wandb wandb -o yaml

# save this and update it to new-manifest.yaml if needed

# Make chanegs to the sepc as nessessary, example below of a spec.
kubectl apply -f new-manifest.yaml
```