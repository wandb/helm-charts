#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
chart="$repo_root/charts/operator-wandb"
values="$repo_root/test-configs/operator-wandb/mysql-aws-iam.yaml"
rendered="$(mktemp)"
password_rendered="$(mktemp)"
trap 'rm -f "$rendered" "$password_rendered"' EXIT

helm template wandb "$chart" --namespace default --values "$values" >"$rendered"

if grep -q 'name: MYSQL_PASSWORD' "$rendered"; then
  echo "IAM authentication must not render MYSQL_PASSWORD" >&2
  exit 1
fi

if grep -q 'name: wandb-mysql$' "$rendered"; then
  echo "IAM authentication must not render the application MySQL password Secret" >&2
  exit 1
fi

# shellcheck disable=SC2016 # Helm intentionally renders these environment references literally.
expected_dsn='mysql://$(MYSQL_USER)@$(MYSQL_HOST):$(MYSQL_PORT)/$(MYSQL_DATABASE)?tls=custom&ssl-ca=$(MYSQL_CA_CERT_PATH)&rds-iam-auth=true&aws-region=us-east-1'
if ! grep -Fq "$expected_dsn" "$rendered"; then
  echo "IAM authentication DSN was not rendered" >&2
  exit 1
fi

role_annotation_count="$(grep -c 'eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/wandb-database' "$rendered")"
if [[ "$role_annotation_count" -ne 11 ]]; then
  echo "expected 11 database workload service accounts, found $role_annotation_count" >&2
  exit 1
fi

if grep -q 'name: init-db' "$rendered"; then
  echo "password-based init-db must be disabled for IAM authentication" >&2
  exit 1
fi

if grep -q 'prometheus-mysql-exporter' "$rendered"; then
  echo "password-based mysql-exporter must be disabled for IAM authentication" >&2
  exit 1
fi

iam_metrics=(
  IamDbAuthConnectionRequests
  IamDbAuthConnectionSuccess
  IamDbAuthConnectionFailure
  IamDbAuthConnectionFailureInvalidToken
  IamDbAuthConnectionFailureInsufficientPermissions
  IamDbAuthConnectionFailureThrottling
  IamDbAuthConnectionFailureServerError
)
for metric in "${iam_metrics[@]}"; do
  if ! grep -Fq -- "- name: $metric" "$rendered"; then
    echo "missing Aurora IAM authentication metric: $metric" >&2
    exit 1
  fi
done

if [[ "$(grep -c -- '- name: IamDbAuthConnection' "$rendered")" -ne 7 ]]; then
  echo "expected exactly seven Aurora IAM authentication metrics" >&2
  exit 1
fi

if ! grep -A3 -F 'exportedTagsOnMetrics:' "$rendered" | grep -Fq -- 'AWS/RDS:' ||
  ! grep -A3 -F 'exportedTagsOnMetrics:' "$rendered" | grep -Fq -- '- Namespace'; then
  echo "RDS metrics must export the Namespace tag for per-deployment dashboards" >&2
  exit 1
fi

assert_iam_render_rejected() {
  local description="$1"
  shift

  if helm template wandb "$chart" --namespace default --values "$values" "$@" >/dev/null 2>&1; then
    echo "IAM authentication $description must fail validation" >&2
    exit 1
  fi
}

assert_iam_render_rejected "with rdsIamAuth as string false" --set-string global.mysql.rdsIamAuth=false
assert_iam_render_rejected "with rdsIamAuth as string true" --set-string global.mysql.rdsIamAuth=true
assert_iam_render_rejected "with rdsIamAuth as a number" --set global.mysql.rdsIamAuth=1
assert_iam_render_rejected "without a database host" --set global.mysql.host=
assert_iam_render_rejected "without a database user" --set global.mysql.user=
assert_iam_render_rejected "without an AWS region" --set global.mysql.awsRegion=
assert_iam_render_rejected "without a CA certificate" --set global.mysql.caCert=
assert_iam_render_rejected "with a database password" --set global.mysql.password=must-be-empty
assert_iam_render_rejected "with a password Secret" --set global.mysql.passwordSecret.name=existing-secret
assert_iam_render_rejected "with local MySQL installed" --set mysql.install=true
assert_iam_render_rejected "with password init-db enabled" --set app.initContainers.init-db.enabled=true
assert_iam_render_rejected "with mysql-exporter enabled" --set prometheus.mysql-exporter.install=true

helm template wandb "$chart" --namespace default >"$password_rendered"
if ! grep -Fq 'name: MYSQL_PASSWORD' "$password_rendered" ||
  ! grep -Fq 'mysql://$(MYSQL_USER):$(MYSQL_PASSWORD)@$(MYSQL_HOST):$(MYSQL_PORT)/$(MYSQL_DATABASE)?tls=preferred' "$password_rendered"; then
  echo "default password authentication must remain unchanged" >&2
  exit 1
fi
