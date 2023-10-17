#!/usr/bin/env bash

export LICENSE=$(cat license.txt)

if ! command -v minio &>/dev/null; then
    brew install minio/stable/minio
else
    echo "MinIO is already installed."
fi

# Check if mc is installed
if ! command -v mc &>/dev/null; then
    brew install minio/stable/mc
else
    echo "mc (MinIO Client) is already installed."
fi

# MinIO configurations
export MINIO_ROOT_USER=minio
export MINIO_ROOT_PASSWORD=minio123
export MINIO_ADDRESS="127.0.0.1:9000"
export MINIO_BINARY=$(which minio)
export MINIO_DATA_DIR="./minio-data"
export MINIO_PID_FILE="/tmp/minio.pid"
export MINIO_WANDB_BUCKET="wandb"
export MINIO_ALIAS="myminio"

# Check if MinIO is running
is_minio_running() {
    if [ -f "$MINIO_PID_FILE" ]; then
        if ps -p $(cat "$MINIO_PID_FILE") >/dev/null 2>&1; then
            return 0
        else
            rm "$MINIO_PID_FILE"
            return 1
        fi
    else
        return 1
    fi
}

start_minio() {
    if ! is_minio_running; then
        nohup $MINIO_BINARY server $MINIO_DATA_DIR >/dev/null 2>&1 &
        echo $! >"$MINIO_PID_FILE"
        echo "MinIO started."
    else
        echo "MinIO is already running."
    fi
}

stop_minio() {
    if is_minio_running; then
        kill $(cat "$MINIO_PID_FILE")
        rm "$MINIO_PID_FILE"
        echo "MinIO stopped."
    else
        echo "MinIO is not running."
    fi
}

minio="start"
# minio="stop"
# Script main execution
case "$minio" in
start)
    start_minio
    ;;
stop)
    stop_minio
    exit
    ;;
*)
    echo "Usage: $0 {start|stop}"
    ;;
esac

mc alias set $MINIO_ALIAS http://$MINIO_ADDRESS $MINIO_ROOT_USER $MINIO_ROOT_PASSWORD

if ! mc ls $MINIO_ALIAS | grep -qE "^\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} [A-Z]{3}\][[:space:]]+[0-9BKMGT]+[[:space:]]+${MINIO_WANDB_BUCKET}/$"; then
    mc mb $MINIO_ALIAS/$MINIO_WANDB_BUCKET
    echo "wandb bucket created on MinIO."
else
    echo "wandb bucket already exists on MinIO."
fi

helm upgrade --namespace=wandb \
    --create-namespace \
    --install wandb \
    ./charts/operator

FORCE_REBUILD=false

# Check if FORCE_REBUILD is set to true or dependencies are missing
if $FORCE_REBUILD || helm dep list ./charts/operator-wandb | grep -q "missing"; then
    helm dependency build ./charts/operator-wandb
fi

MANIFEST=$(
    cat <<EOF
apiVersion: apps.wandb.com/v1
kind: WeightsAndBiases
metadata:
  labels:
    app.kubernetes.io/name: weightsandbiases
    app.kubernetes.io/instance: wandb
    wandb.ai/console-default: "true"
  name: wandb
spec:
  values:
    global:
      host: "http://localhost"
      license: "$LICENSE"
      bucket:
        name: "$MINIO_ROOT_USER:$MINIO_ROOT_PASSWORD@host.docker.internal:9000/$MINIO_WANDB_BUCKET"
        region: "us-east-2"
EOF
)

echo "$MANIFEST"

echo "$MANIFEST" | kubectl apply -f -

# To enable the ui and console run the following commands in a new terminal.
kubectl port-forward svc/wandb-app 8080:8080 &
kubectl port-forward svc/wandb-console 8081:8082 &
