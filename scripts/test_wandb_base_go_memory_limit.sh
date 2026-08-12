#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
chart_dir="${script_dir}/../charts/wandb-base"
helm_bin="${HELM_BIN:-helm}"

base_args=(
  --set-string containers.test.image.repository=example.invalid/test
  --set-string containers.test.image.tag=test
)

expect_success() {
  local label="$1"
  shift
  if ! "${helm_bin}" template go-memory-limit "${chart_dir}" "${base_args[@]}" "$@" >/dev/null; then
    echo "expected ${label} to render successfully" >&2
    return 1
  fi
}

expect_failure() {
  local label="$1"
  shift
  if "${helm_bin}" template go-memory-limit "${chart_dir}" "${base_args[@]}" "$@" >/dev/null 2>&1; then
    echo "expected ${label} to fail rendering" >&2
    return 1
  fi
}

expect_failure_containing() {
  local label="$1"
  local expected="$2"
  local output
  shift 2
  if output=$("${helm_bin}" template go-memory-limit "${chart_dir}" "${base_args[@]}" "$@" 2>&1); then
    echo "expected ${label} to fail rendering" >&2
    return 1
  fi
  if [[ "${output}" != *"${expected}"* ]]; then
    echo "expected ${label} failure to contain: ${expected}" >&2
    echo "${output}" >&2
    return 1
  fi
}

expect_success "an absent value"

for value in 1 1B 1KiB 1MiB 8GiB 1TiB; do
  expect_success "valid value ${value}" --set-string "containers.test.goMemoryLimit=${value}"
done

boundary_failures=0
for value in \
  9223372036854775807 \
  9223372036854775807B \
  9007199254740991KiB \
  8796093022207MiB \
  8589934591GiB \
  8388607TiB; do
  expect_success "maximum valid value ${value}" \
    --set-string "containers.test.goMemoryLimit=${value}" || boundary_failures=1
  expect_success "maximum valid value ${value} with schema skipped" \
    --skip-schema-validation \
    --set-string "containers.test.goMemoryLimit=${value}" || boundary_failures=1
done

for value in \
  9223372036854775808 \
  9223372036854775808B \
  9007199254740992KiB \
  8796093022208MiB \
  8589934592GiB \
  8388608TiB; do
  expect_failure "overflow value ${value}" \
    --set-string "containers.test.goMemoryLimit=${value}" || boundary_failures=1
  expect_failure_containing "overflow value ${value} with schema skipped" \
    "exceeds Go's maximum signed 64-bit memory limit" \
    --skip-schema-validation \
    --set-string "containers.test.goMemoryLimit=${value}" || boundary_failures=1
done

for value in \
  10000000000000000000 \
  10000000000000000000B \
  10000000000000000KiB \
  10000000000000MiB \
  10000000000GiB \
  10000000TiB; do
  expect_failure_containing "schema magnitude limit ${value}" \
    "values don't meet the specifications of the schema" \
    --set-string "containers.test.goMemoryLimit=${value}" || boundary_failures=1
done

if ((boundary_failures)); then
  exit 1
fi

for value in '' 0 0B 11Gi 11GB 1.5GiB -1GiB; do
  expect_failure "invalid string value ${value:-<empty>}" --set-string "containers.test.goMemoryLimit=${value}"
done

for value_path in \
  initContainers.test.goMemoryLimit \
  jobs.compact.containers.test.goMemoryLimit \
  cronJobs.cleanup.containers.test.goMemoryLimit; do
  expect_failure "invalid ${value_path}" --set-string "${value_path}=11Gi"
done

expect_failure "a numeric YAML value" --set containers.test.goMemoryLimit=1024
expect_failure "a null YAML value" --set-json containers.test.goMemoryLimit=null

for env_path in \
  containers.test.env.GOMEMLIMIT \
  env.GOMEMLIMIT \
  extraEnv.GOMEMLIMIT \
  global.env.GOMEMLIMIT \
  global.extraEnv.GOMEMLIMIT; do
  expect_failure "conflicting ${env_path}" \
    --set-string containers.test.goMemoryLimit=8GiB \
    --set-string "${env_path}=7GiB"
done

expect_failure "conflicting sizing environment" \
  --set-string containers.test.goMemoryLimit=8GiB \
  --set-string size=conflict-test \
  --set-string sizing.conflict-test.env.GOMEMLIMIT=7GiB

expect_failure "template string validation with schema skipped" \
  --skip-schema-validation \
  --set-string containers.test.goMemoryLimit=11Gi

expect_failure "template type validation for a number with schema skipped" \
  --skip-schema-validation \
  --set containers.test.goMemoryLimit=1024
