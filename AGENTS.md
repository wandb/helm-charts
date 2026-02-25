## Cursor Cloud specific instructions

This is a **Helm Charts** repository (no application source code). The development workflow revolves around Helm chart linting, building, and snapshot testing.

### Required tools

Installed by the update script: `helm` v3.16.3, helm plugins (`chartsnap`, `cascade`), `yamllint`, `yamale`, `chart-testing` (`ct`), plus helm repos (`prometheus-community`, `stakater`).

### Key commands

| Task | Command |
|------|---------|
| Build charts | `./snapshots.sh build` (or `./snapshots.sh build <chart-name>`) |
| Run snapshot tests | `./snapshots.sh run` (or `./snapshots.sh run <chart-name>`) |
| Update snapshots | `./snapshots.sh update` |
| Lint all charts | `ct lint --config ct.yaml --all` |
| YAML lint | `yamllint -c .yamllint.yaml <file>` |
| Render templates | `helm template wandb ./charts/operator-wandb` |

### Gotchas

- Before building or testing, `helm repo add prometheus-community https://prometheus-community.github.io/helm-charts` and `helm repo add stakater https://stakater.github.io/stakater-charts` must have been run at least once. The update script handles this.
- `ct lint` requires `yamale` (Python package) and config files in `/etc/ct/`. The update script handles both.
- Snapshot tests compare rendered Helm templates against files in `test-configs/<chart>/__snapshots__/`. If chart templates change, run `./snapshots.sh update` to regenerate snapshots, then verify the diff is expected.
- There is no running application to start — this repo only produces Helm charts. The "hello world" equivalent is `helm template wandb ./charts/operator-wandb` which renders all K8s manifests.
- `PATH` must include `~/.local/bin` for `yamllint`/`yamale` installed via pip. The update script ensures this.
- Full local deployment (Kind cluster + Tilt) requires Docker. See `DEVELOPERS.md` for details.
