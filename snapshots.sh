#!/usr/bin/env bash 
set -euo pipefail

# helm plugin install https://github.com/origranot/helm-cascade
# helm plugin install https://github.com/jlandowner/helm-chartsnap
# helm cascade build ./charts/operator-wandb/

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
