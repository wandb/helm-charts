#!/usr/bin/env bash 
set -euo pipefail

# Check if helm chartsnap plugin is installed
if ! helm plugin list | grep -q "chartsnap"; then
  echo "❌ helm chartsnap plugin is not installed"
  echo "Please install it by running:"
  echo "  helm plugin install https://github.com/jlandowner/helm-chartsnap"
  exit 1
fi

function main() {
  local chart="operator-wandb"
  local values_dir="test-configs"

  local func="$1"
  case "$func" in
    update)
      echo "Updating operator-wandb snapshots"
      helm chartsnap -c "./charts/$chart" -u -f "./$values_dir/$chart"
      ;;
    run)
      echo "Checking snapshot tests"
      helm chartsnap -c "./charts/$chart" -f "./$values_dir/$chart"
      ;;
    *)
      cat <<EOF
A helper script for the helm-chartsnap plugin https://github.com/jlandowner/helm-chartsnap

Usage: $0 [COMMAND]

Commands:
  update,   execute chartsnap to update the snapshots
  run,      executes chartsnap to test helm changes
EOF
      ;;
  esac
}

main "$@"
