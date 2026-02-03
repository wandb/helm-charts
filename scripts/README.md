# Scripts

## generate-env-tests (gomplate)

Generates `test-env-expansion.yaml` from Chart.yaml and values.yaml to validate environment variables.

### Requirements

- gomplate

### Installation

```bash
# Install gomplate
brew install gomplate

# Or visit https://gomplate.ca/install/
```

### Usage

```bash
# Via snapshots.sh (recommended)
./snapshots.sh generate-env-tests

# Or directly
CHART_FILE=./charts/operator-wandb/Chart.yaml \
VALUES_FILE=./charts/operator-wandb/values.yaml \
gomplate \
  -f ./scripts/templates/test-env-expansion.yaml.tpl \
  -o ./charts/operator-wandb/templates/tests/test-env-expansion.yaml
```

### What it does

1. Reads Chart.yaml to find all `wandb-base` service dependencies
2. For each service, extracts `envFrom`, `envTpls`, and `env` from values.yaml
3. Generates individual test containers that replicate each service's exact environment configuration
4. Each container runs `env | grep '('` to detect unresolved `$(VARIABLE)` references
5. Test fails if any `$(...)` references are found that shouldn't be there

### Benefits

- **Catches bugs early**: Prevents shipping configs with unresolved variable references
- **Per-service testing**: Each service tested with its actual configuration
- **Runs automatically**: Executes via `helm test` during CI
- **Easy maintenance**: Regenerate anytime with one command
- **Stable test image**: Uses `busybox:stable-musl` with `IfNotPresent` to avoid Docker Hub rate limits

### Example Bug Caught

```yaml
# ConfigMap with shell-style variable that won't be expanded
GORILLA_GLUE_CLICKHOUSE_ADDRESS: "http://$(WF_CLICKHOUSE_HOST):$(WF_CLICKHOUSE_PORT)"

# Test fails because WF_CLICKHOUSE_HOST isn't set in glue's envTpls
```
