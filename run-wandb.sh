#!/usr/bin/env bash

export LICENSE=$(cat license.txt)

helm upgrade --namespace=wandb \
    --create-namespace \
    --install wandb \
    ./charts/wandb-oper \
    --set license=$LICENSE \
    --set image.repository=wandb/local \
    --set-string extraEnv[0].name=GORILLA_CUSTOMER_SECRET_STORE_SOURCE --set-string extraEnv[0].value='k8s-secretmanager://wandb-secrets' \
    --set-string extraEnv[1].name=GORILLA_CUSTOMER_SECRET_STORE_K8S_CONFIG_NAMESPACE --set-string extraEnv[1].value='wandb'

# --set bucket=$BUCKET /
# --set bucketRegion=$BUCKET_REGION
