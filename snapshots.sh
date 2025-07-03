#!/usr/bin/env bash 
set -euo pipefail

function main() {
  local chart="operator-wandb"
  local values_dir="test-configs"

  local func="$1"
  case "$func" in
    update)
      echo "Updating operator-wandb snapshots"
      for value_file in ./$values_dir/$chart/*; do
        if [[ -f "$value_file" ]]; then
          helm chartsnap -c "./charts/$chart" -u -f "$value_file"
        fi
      done
      ;;
    run)
      echo "Checking snapshot tests"
      for value_file in ./$values_dir/$chart/*; do
        if [[ -f "$value_file" ]]; then
          sleep 1
          helm chartsnap -c "./charts/$chart" -f "$value_file"
        fi
      done
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
