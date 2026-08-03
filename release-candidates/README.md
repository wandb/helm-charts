# MCP release candidate

The Server Release team has one handoff for MCP v0.4:

1. Promote the exact staging-tested image digest recorded in
   `mcp-v0.4.0.json` to the recorded public repository with tag `0.4.0`. Do not
   rebuild it.
2. Require the **MCP v0.4 release gate** check to pass.

That check verifies the package version and Git source SHA inside the image,
renders the exact digest through `operator-wandb`, checks the production MCP
settings and least-privilege environment, proves the public `0.4.0` tag resolves
to the same tested digest, starts the image, and requires the canonical
`/mcp/health` endpoint to pass. A different digest requires a new staging
acceptance run and a reviewed evidence update; a mutable image tag alone is not
release evidence.
