# Scripts

## generate-env-tests.go

Generates `test-env-expansion.yaml` from Chart.yaml and values.yaml to validate environment variables.

### Requirements

- Go 1.25+
- Network access (for `go run` to download module deps)

### Installation

```bash
# Install Go
brew install go

# Or download from https://go.dev/doc/install
```

### Usage

```bash
# Via snapshots.sh (recommended)
./snapshots.sh generate-env-tests

# Or directly
cd scripts && go run ./generate-env-tests.go -chart operator-wandb
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
