#!/usr/bin/env bash 
set -euo pipefail

# Check if helm chartsnap plugin is installed
if ! helm plugin list | grep -q "chartsnap"; then
  echo "❌ helm chartsnap plugin is not installed"
  echo "Please install it by running:"
  echo "  helm plugin install https://github.com/jlandowner/helm-chartsnap"
  exit 1
fi

if ! helm plugin list | grep -q "cascade"; then
  echo "❌ helm cascade plugin is not installed"
  echo "Please install it by running:"
  echo "  helm plugin install https://github.com/origranot/helm-cascade"
  exit 1
fi

function usage() {
  cat <<EOF
A helper script for the helm-chartsnap plugin https://github.com/jlandowner/helm-chartsnap

Usage: $0 [COMMAND]

Commands:
  build,    build the operator-wandb chart
  update,   execute chartsnap to update the snapshots
  run,      executes chartsnap to test helm changes
EOF
}

function main() {
  local chart="operator-wandb"
  local values_dir="test-configs"
  local chart_dir="charts/$chart"

  if [ $# -eq 0 ]; then
    usage
    exit 1
  fi

  local func="$1"
  case "$func" in
    build)
      echo "Building operator-wandb"
      helm cascade build "./charts/$chart"
      ;;
    update)
      echo "Updating operator-wandb snapshots"
      helm chartsnap -c "./charts/$chart" -u -f "./$values_dir/$chart"
      ;;
    run)
      echo "Checking snapshot tests"
      helm chartsnap -c "./charts/$chart" -f "./$values_dir/$chart"
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
