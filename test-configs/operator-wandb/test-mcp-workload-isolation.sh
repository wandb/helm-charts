#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
chart="$repo_root/charts/operator-wandb"
expected="$repo_root/test-configs/operator-wandb/mcp-workload-isolation.expected"
actual="$(mktemp)"
disabled_sources="$(mktemp)"
enabled_sources="$(mktemp)"
rendered="$(mktemp)"
api_containers="$(mktemp)"
trap 'rm -f "$actual" "$disabled_sources" "$enabled_sources" "$rendered" "$api_containers"' EXIT

render() {
  local size="$1"
  local enabled="$2"
  shift 2

  helm template chartsnap "$chart" \
    --set-string global.host=https://wandb.example.com \
    --set-string global.size="$size" \
    --set global.api.enabled=true \
    --set api.mcpWorkloadIsolation.enabled="$enabled" \
    "$@" >"$rendered"

  awk '
    /^# Source: operator-wandb\/charts\/api\/templates\/deployment.yaml$/ {
      in_api_deployment = 1
    }
    in_api_deployment && /^      containers:$/ {
      in_containers = 1
    }
    in_containers && /^      initContainers:$/ {
      exit
    }
    in_containers {
      print
    }
  ' "$rendered" >"$api_containers"
}

env_value() {
  local name="$1"
  awk -v name="$name" '
    $0 ~ "^[[:space:]]*- name: " name "$" {
      getline
      sub(/^[[:space:]]*value: /, "")
      gsub(/"/, "")
      print
      exit
    }
  ' "$api_containers"
}

record_case() {
  local name="$1"
  local mysql
  local query
  local mysql_count
  local query_count

  mysql="$(env_value GORILLA_MCP_MYSQL_CONNECTIONS_PER_REQUEST)"
  query="$(env_value GORILLA_MCP_SDK_GRAPHQL_QUERY_SECONDS)"
  mysql_count="$(grep -c 'name: GORILLA_MCP_MYSQL_CONNECTIONS_PER_REQUEST' "$api_containers" || true)"
  query_count="$(grep -c 'name: GORILLA_MCP_SDK_GRAPHQL_QUERY_SECONDS' "$api_containers" || true)"

  printf '%s\t%s\t%s\t%s\t%s\n' \
    "$name" "${mysql:-absent}" "${query:-absent}" "$mysql_count" "$query_count" >>"$actual"
}

printf 'case\tmysql_connections\tquery_seconds\tmysql_occurrences\tquery_occurrences\n' >"$actual"

render small false
record_case disabled
grep '^# Source:' "$rendered" >"$disabled_sources"

for size in small medium large xlarge xxlarge; do
  render "$size" true
  record_case "$size"
done

render large true \
  --set-string api.containers.api.env.GORILLA_MCP_MYSQL_CONNECTIONS_PER_REQUEST=9 \
  --set-string api.containers.api.env.GORILLA_MCP_SDK_GRAPHQL_QUERY_SECONDS=10
record_case override

render small true
grep '^# Source:' "$rendered" >"$enabled_sources"

diff -u "$expected" "$actual"
diff -u "$disabled_sources" "$enabled_sources"

echo "MCP workload-isolation renders match the focused snapshots and add no resources."
