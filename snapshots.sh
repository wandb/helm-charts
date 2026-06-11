#!/usr/bin/env bash 
set -eo pipefail

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

# Check if ct (chart-testing) is installed
function check_ct() {
  if ! command -v ct &> /dev/null; then
    echo "❌ ct (chart-testing) is not installed"
    echo "Install: https://github.com/helm/chart-testing#installation"
    exit 1
  fi
}

function usage() {
  cat <<EOF
A helper script for the helm-chartsnap plugin https://github.com/jlandowner/helm-chartsnap

Usage: $0 [COMMAND] [CHART (default: operator-wandb)]

Commands:
  build,    build the operator-wandb chart
  update,   execute chartsnap to update the snapshots
  run,      executes chartsnap to test helm changes
  lint,     lint the operator-wandb chart with ct lint
EOF
}

function build_chart() {
  local chart="$1"
  echo "Building $chart"
  helm cascade build "./charts/$chart"
}

function update_chart() {
  local chart="$1"
  local values_file="$2"
  echo "updating $chart snapshots"
  helm chartsnap -c "./charts/$chart" -u -f "$values_file"
}

function run_chart() {
  local chart="$1"
  local values_file="$2"
  echo "Checking $chart snapshot tests"
  helm chartsnap -c "./charts/$chart" -f "$values_file"
}

function lint_chart() {
  local chart="$1"
  check_ct
  echo "Linting $chart"
  ct lint --config ct.yaml --charts "./charts/$chart"
}

function main() {
  local chart="operator-wandb"
  local values_dir="test-configs"

  if [ $# -eq 0 ]; then
    usage
    exit 1
  fi

  local func="$1"
  local target_chart="$2"

  if [ -n "$target_chart" ]; then
    chart="$target_chart"
  fi
  case "$func" in
    build)
      build_chart "$chart"
      ;;
    update)
      update_chart "$chart" "./$values_dir/$chart"
      ;;
    run)
      run_chart "$chart" "./$values_dir/$chart"
      ;;
    lint)
      lint_chart "$chart"
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
