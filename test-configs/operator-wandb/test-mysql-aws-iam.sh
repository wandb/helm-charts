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

database_role_annotation='eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/wandb-database'

service_account_exists() {
  local name="$1"

  awk -v expected_name="$name" '
    BEGIN { RS = "---" }
    $0 ~ "\nkind: ServiceAccount\n" &&
      $0 ~ "\n  name: " expected_name "\n" {
      found = 1
    }
    END { exit found ? 0 : 1 }
  ' "$rendered"
}

service_account_has_database_role() {
  local name="$1"

  awk -v expected_name="$name" -v expected_annotation="$database_role_annotation" '
    BEGIN { RS = "---" }
    $0 ~ "\nkind: ServiceAccount\n" &&
      $0 ~ "\n  name: " expected_name "\n" &&
      index($0, expected_annotation) {
      found = 1
    }
    END { exit found ? 0 : 1 }
  ' "$rendered"
}

database_service_accounts=(
  wandb-api
  wandb-app
  wandb-executor
  wandb-filemeta
  wandb-filestream
  wandb-flat-run-fields-updater
  wandb-glue
  wandb-history-updater
  wandb-metric-observer
  wandb-parquet
  wandb-parquet-metadata-cache
)
for service_account in "${database_service_accounts[@]}"; do
  if ! service_account_exists "$service_account"; then
    echo "expected database workload ServiceAccount $service_account to be rendered" >&2
    exit 1
  fi
  if ! service_account_has_database_role "$service_account"; then
    echo "expected database role annotation on ServiceAccount $service_account" >&2
    exit 1
  fi
done

excluded_service_accounts=(
  wandb-weave
  wandb-weave-trace
)
for service_account in "${excluded_service_accounts[@]}"; do
  if ! service_account_exists "$service_account"; then
    echo "expected excluded ServiceAccount $service_account to be rendered" >&2
    exit 1
  fi
  if service_account_has_database_role "$service_account"; then
    echo "database role annotation must not be set on ServiceAccount $service_account" >&2
    exit 1
  fi
done

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
  metric_block="$(grep -A3 -F -- "- name: $metric" "$rendered")"
  if [[ "$metric_block" != *"length: 600"* ]]; then
    echo "Aurora IAM authentication metric $metric must use a 600-second lookback for delayed CloudWatch samples" >&2
    exit 1
  fi
  if [[ "$metric_block" != *"period: 600"* ]]; then
    echo "Aurora IAM authentication metric $metric must aggregate a 600-second CloudWatch period" >&2
    exit 1
  fi
done

if [[ "$(grep -c -- '- name: IamDbAuthConnection' "$rendered")" -ne 7 ]]; then
  echo "expected exactly seven Aurora IAM authentication metrics" >&2
  exit 1
fi

datadog_iam_metrics=(
  aws_rds_iam_db_auth_connection_requests_sum
  aws_rds_iam_db_auth_connection_success_sum
  aws_rds_iam_db_auth_connection_failure_sum
  aws_rds_iam_db_auth_connection_failure_invalid_token_sum
  aws_rds_iam_db_auth_connection_failure_insufficient_permissions_sum
  aws_rds_iam_db_auth_connection_failure_throttling_sum
  aws_rds_iam_db_auth_connection_failure_server_error_sum
)
if ! grep -Fq 'ad.datadoghq.com/yace.checks:' "$rendered"; then
  echo "YACE must configure Datadog OpenMetrics autodiscovery" >&2
  exit 1
fi
for metric in "${datadog_iam_metrics[@]}"; do
  if ! grep -Fq "\"$metric\"" "$rendered"; then
    echo "Datadog OpenMetrics autodiscovery must collect $metric" >&2
    exit 1
  fi
done

exported_tags_block="$(grep -A3 -F 'exportedTagsOnMetrics:' "$rendered")"
if [[ "$exported_tags_block" != *"AWS/RDS:"* ]] ||
  [[ "$exported_tags_block" != *"- namespace"* ]]; then
  echo "RDS metrics must export the lowercase namespace tag used by managed-install resources" >&2
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

assert_iam_render_accepted() {
  local description="$1"
  shift

  if ! helm template wandb "$chart" --namespace default --values "$values" "$@" >/dev/null; then
    echo "IAM authentication $description must pass validation" >&2
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

assert_iam_render_accepted \
  "with app disabled and its unused init-db default enabled" \
  --set app.install=false \
  --set app.initContainers.init-db.enabled=true
assert_iam_render_accepted \
  "with Prometheus disabled and its unused mysql-exporter default enabled" \
  --set prometheus.install=false \
  --set prometheus.mysql-exporter.install=true

helm template wandb "$chart" --namespace default >"$password_rendered"
# shellcheck disable=SC2016 # Helm intentionally renders these environment references literally.
expected_password_dsn='mysql://$(MYSQL_USER):$(MYSQL_PASSWORD)@$(MYSQL_HOST):$(MYSQL_PORT)/$(MYSQL_DATABASE)?tls=preferred'
if ! grep -Fq 'name: MYSQL_PASSWORD' "$password_rendered" ||
  ! grep -Fq "$expected_password_dsn" "$password_rendered"; then
  echo "default password authentication must remain unchanged" >&2
  exit 1
fi
