#!/bin/sh
set -o errexit

# Default configuration
cluster_name="wandb-helm-charts"
create_registry=true
install_ingress=false
ingress_http_port=80
ingress_https_port=443

# Registry configuration
reg_name='kind-registry'
reg_port='5001'

# Check for required dependencies
check_dependencies() {
  local missing_deps=()
  
  # Check for kind
  if ! command -v kind >/dev/null 2>&1; then
    missing_deps+=("kind")
  fi
  
  # Check for docker
  if ! command -v docker >/dev/null 2>&1; then
    missing_deps+=("docker")
  fi
  
  # Check for kubectl
  if ! command -v kubectl >/dev/null 2>&1; then
    missing_deps+=("kubectl")
  fi
  
  # If any dependencies are missing, print error and exit
  if [ ${#missing_deps[@]} -ne 0 ]; then
    echo "Error: Missing required dependencies: ${missing_deps[*]}"
    echo ""
    echo "Please install the missing tools:"
    for dep in "${missing_deps[@]}"; do
      case "$dep" in
        kind)
          echo "  - kind: https://kind.sigs.k8s.io/docs/user/quick-start/#installation"
          echo "    macOS: brew install kind"
          echo "    Linux: curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64 && chmod +x ./kind && sudo mv ./kind /usr/local/bin/"
          ;;
        docker)
          echo "  - docker: https://docs.docker.com/get-docker/"
          echo "    macOS: brew install --cask docker"
          echo "    Ensure Docker Desktop is running after installation"
          ;;
        kubectl)
          echo "  - kubectl: https://kubernetes.io/docs/tasks/tools/"
          echo "    macOS: brew install kubectl"
          echo "    Linux: curl -LO \"https://dl.k8s.io/release/\$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl\" && sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl"
          ;;
      esac
    done
    exit 1
  fi
  
  # Check if Docker is running
  if ! docker info >/dev/null 2>&1; then
    echo "Error: Docker is installed but not running."
    echo "Please start Docker and try again."
    echo "  macOS: Open Docker Desktop from Applications"
    echo "  Linux: sudo systemctl start docker"
    exit 1
  fi
}

# Display usage information
usage() {
  echo "Usage: $0 [OPTIONS]"
  echo "Create a kind cluster with optional configurations."
  echo ""
  echo "Options:"
  echo "  -h, --help                 Display this help message"
  echo "  -n, --name NAME            Set the cluster name (default: wandb-helm-charts)"
  echo "  -r, --no-registry          Don't create a local registry"
  echo "  -i, --ingress              Install and configure nginx-ingress controller"
  echo "  --http-port PORT           Set HTTP port for ingress (default: 80)"
  echo "  --https-port PORT          Set HTTPS port for ingress (default: 443)"
  echo ""
  echo "Examples:"
  echo "  $0 --name my-cluster       Create a cluster named 'my-cluster'"
  echo "  $0 --no-registry           Create a cluster without a local registry"
  echo "  $0 --ingress               Create a cluster with nginx-ingress controller"
  exit 1
}

# Parse command line arguments
while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
      ;;
    -n|--name)
      if [ -z "$2" ] || [ "${2:0:1}" = "-" ]; then
        echo "Error: Missing or invalid cluster name after --name flag"
        exit 1
      fi
      cluster_name="$2"
      shift 2
      ;;
    -r|--no-registry)
      create_registry=false
      shift
      ;;
    -i|--ingress)
      install_ingress=true
      shift
      ;;
    --http-port)
      ingress_http_port="$2"
      if ! [[ "$ingress_http_port" =~ ^[0-9]+$ ]] || [ "$ingress_http_port" -lt 1 ] || [ "$ingress_http_port" -gt 65535 ]; then
        echo "Error: Invalid HTTP port. Port must be an integer between 1 and 65535."
        exit 1
      fi
      shift 2
      ;;
    --https-port)
      ingress_https_port="$2"
      if ! [[ "$ingress_https_port" =~ ^[0-9]+$ ]] || [ "$ingress_https_port" -lt 1 ] || [ "$ingress_https_port" -gt 65535 ]; then
        echo "Error: Invalid HTTPS port. Port must be an integer between 1 and 65535."
        exit 1
      fi
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      usage
      ;;
  esac
done

# Check that all required tools are installed
check_dependencies

echo "Creating kind cluster with the following configuration:"
echo "  Cluster name: $cluster_name"
echo "  Create registry: $create_registry"
echo "  Install ingress: $install_ingress"
if [ "$install_ingress" = true ]; then
  echo "  Ingress HTTP port: $ingress_http_port"
  echo "  Ingress HTTPS port: $ingress_https_port"
fi
echo ""

# Create registry container if enabled and it doesn't already exist
if [ "$create_registry" = true ]; then
  echo "Setting up local container registry..."
  if [ "$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)" != 'true' ]; then
    docker run \
      -d --restart=always -p "127.0.0.1:${reg_port}:5000" --name "${reg_name}" \
      registry:2
  fi
fi

# Create the kind cluster configuration
kind_config="kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane"

# Add ingress configuration if enabled
if [ "$install_ingress" = true ]; then
  kind_config="${kind_config}
  extraPortMappings:
  - containerPort: 80
    hostPort: ${ingress_http_port}
    protocol: TCP
  - containerPort: 443
    hostPort: ${ingress_https_port}
    protocol: TCP"
fi

kind_config="${kind_config}
- role: worker"

# Add registry configuration if enabled
if [ "$create_registry" = true ]; then
  kind_config="${kind_config}
containerdConfigPatches:
- |-
  [plugins.\"io.containerd.grpc.v1.cri\".registry.mirrors.\"localhost:${reg_port}\"]
    endpoint = [\"http://${reg_name}:5000\"]"
fi

# Create the cluster
echo "Creating kind cluster '$cluster_name'..."
echo "$kind_config" | kind create cluster --name "$cluster_name" --config=-

# Connect the registry to the cluster network if enabled and not already connected
if [ "$create_registry" = true ]; then
  echo "Connecting registry to cluster network..."
  if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' "${reg_name}" 2>/dev/null || true)" = 'null' ]; then
    docker network connect "kind" "${reg_name}"
  fi

  # Document the local registry
  # https://github.com/kubernetes/enhancements/tree/master/keps/sig-cluster-lifecycle/generic/1755-communicating-a-local-registry
  echo "Creating local-registry-hosting ConfigMap..."
  cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${reg_port}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF
fi

# Install ingress controller if enabled
if [ "$install_ingress" = true ]; then
  echo "Installing nginx-ingress controller..."
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
  
  echo "Waiting for ingress controller to be ready..."
  kubectl wait --namespace ingress-nginx \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=90s
fi

echo "Cluster '$cluster_name' is ready!"
