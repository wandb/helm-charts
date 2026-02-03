#!/usr/bin/env bash 
set -eo pipefail

if ! command -v helm &> /dev/null; then
  echo "❌ helm is not installed"
  echo "Please install Helm: https://helm.sh/docs/intro/install/"
  exit 1
fi

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

Usage: $0 [COMMAND] [CHART (default: operator-wandb)]

Commands:
  build,              build the operator-wandb chart
  update,             execute chartsnap to update the snapshots
  run,                executes chartsnap to test helm changes
  generate-env-tests, generate environment expansion test from Chart.yaml and values.yaml
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

function generate_env_tests() {
  local chart="$1"
  
  if ! command -v gomplate &> /dev/null; then
    echo "❌ gomplate is not installed"
    echo "Please install gomplate:"
    echo "  brew install gomplate"
    echo "  or visit https://gomplate.ca/install/"
    exit 1
  fi

  local chart_dir="./charts/$chart"
  local template_file="./scripts/templates/test-env-expansion.yaml.tpl"
  local output_file="$chart_dir/templates/tests/test-env-expansion.yaml"

  if [ ! -f "$chart_dir/Chart.yaml" ]; then
    echo "❌ Chart.yaml not found for chart: $chart"
    exit 1
  fi

  if [ ! -f "$template_file" ]; then
    echo "❌ Template file not found: $template_file"
    exit 1
  fi

  CHART_FILE="$chart_dir/Chart.yaml" \
  VALUES_FILE="$chart_dir/values.yaml" \
  gomplate \
    -o "$output_file" \
    -f "$template_file"
}


function main() {
  if [ $# -eq 0 ]; then
    usage
    exit 1
  fi

  local func="$1"
  local chart="${2:-operator-wandb}"
  local values_dir="test-configs"
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
    generate-env-tests)
      generate_env_tests "$chart"
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
