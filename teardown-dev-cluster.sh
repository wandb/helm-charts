#!/bin/sh
set -o errexit

# Default configuration
cluster_name="wandb-helm-charts"

# Display usage information
usage() {
  echo "Usage: $0 [OPTIONS]"
  echo "Teardown kind cluster used to test helm charts."
  echo ""
  echo "Options:"
  echo "  -h, --help                 Display this help message"
  echo "  -n, --name NAME            Set the cluster name (default: kind)"
  echo ""
  echo "Examples:"
  echo "  $0 --name my-cluster       Create a cluster named 'my-cluster'"
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
    *)
      echo "Unknown option: $1"
      usage
      ;;
  esac
done

echo "Tearing down kind cluster:"
echo "  Cluster name: $cluster_name"
echo ""

kind delete cluster --name $cluster_name

