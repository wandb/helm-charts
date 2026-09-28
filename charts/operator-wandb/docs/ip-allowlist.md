# Traefik ingress and IP allowlists
Intended as a internally used feature, the presense of these mechanics doesn't introduce support for self-host deployments.

---

The proposed operator-wandb **0.44.25** release introduces this contract. Downstream
Terraform/operator consumers must wait for publication of a chart containing this
change and select that version before propagating these values. Older charts may
silently ignore them. This working-tree implementation is not a published release.

```yaml
global:
  legacyIngress: true
  traefikIngress: false
  ipAllowList:
    enabled: true
    systemCIDRs: [10.0.0.0/8]
    userCIDRs: [192.0.2.0/24, '2001:db8::/32']
```

With `traefikIngress: false`, this validates and stages values only. Defaults are
`legacyIngress: true`, `traefikIngress: false`, and a disabled allowlist with both
lists empty. Existing serving behavior is preserved by default.

`systemCIDRs` belongs to platform automation; `userCIDRs` belongs to the customer.
Both accept IPv4 and IPv6 CIDRs. The middleware uses their union, removing exact
duplicates while preserving system-first order. Host bits are accepted. An empty
customer list permits only configured system ranges. Unrestricted access must be
explicit (`0.0.0.0/0` and `::/0`); `*` is invalid. IPv6 values do not enable IPv6
connectivity.

Helm validation runs even while Traefik ingress is off. It rejects malformed
CIDRs (including prefixes outside 0–32 for IPv4 or 0–128 for IPv6), enabled policy
with both lists empty, and Traefik activation with policy disabled. Errors identify
the list/index or corrective setting. A disabled policy with valid CIDRs succeeds
and emits a `# WARNING:` comment in the rendered YAML explaining that the ranges
are not enforced. No middleware is created. Malformed CIDRs still fail validation
even when the policy is disabled.

Setting `traefikIngress: true` creates `<release>-traefik`, an Ingress with class
`traefik`, and `<release>-ip-allowlist`, a Middleware in the release namespace.
The Ingress uses `websecure` with TLS enabled and attaches
`<namespace>-<release>-ip-allowlist@kubernetescrd` to every generated application
route. It shares the primary ingress's paths, including enabled API paths, `/mcp`
and `/traces`, and uses `global.host` plus named `ingress.additionalHosts`.
Duplicate names are removed; empty aliases used for AWS hostless PrivateLink are
excluded. Legacy annotations are not copied, so the new Ingress does not request
external-DNS changes or cloud load balancers.

HTTP-to-HTTPS redirects use the existing Traefik `web` entrypoint redirect. The
allowlist is attached only to HTTPS application routing, leaving HTTP redirects
independent of membership. Geographic filtering remains on `websecure`; the chart
does not duplicate it per route. Confirm both entrypoint settings before activation.
See [Traefik's ingress annotation reference](https://doc.traefik.io/traefik/v3.6/reference/routing-configuration/kubernetes/ingress/#on-ingress).

TLS binds all named hosts to the static `wandb-ssl-cert` Secret on every cloud.
The Traefik Ingress always specifies `cert-manager.io/cluster-issuer: cert-issuer`,
including on Azure. It references
the same existing Secret when present; the chart does not create a second Secret.
Check that the certificate's SANs cover all named hosts.

DNS-01 selection comes from the ClusterIssuer's
`spec.acme.solvers`, and requires working DNS configuration/delegation for every
alias. The deployment wrapper only adds its DNS-01 solver when `hostedZoneName`
is populated; Azure otherwise retains HTTP-01. See [ACME solver selection](https://cert-manager.io/docs/configuration/acme/#adding-multiple-solver-types).

**Azure legacy removal remains a separate readiness check.** Its current
certificate can be owned by the legacy Ingress through ingress-shim. Adding an
issuer annotation on the new Ingress does not transfer that ownership. Referencing
the Secret from the new Ingress does not transfer ownership or prevent garbage
collection. Inspect the Certificate and Secret owner references and establish a
renewable certificate lifecycle independent of the old Ingress before disabling
legacy ingress. This chart does not automatically adopt or patch live certificate
ownership. Keep legacy ingress enabled until that migration is verified.

Activation also requires the Traefik Middleware CRD, operator permissions to manage
Ingress/Middleware resources, both Traefik Kubernetes providers watching the release
namespace, and a working trusted source-IP configuration. No forwarded-header
`ipStrategy` is set. Rendering verifies resource references, not live enforcement,
redirects, certificate issuance/renewal, or missing/rejected middleware behavior.
Those integration checks remain in T-026 and commissioning tickets.

`legacyIngress: false` suppresses existing primary and secondary Ingress objects,
regardless of their install/create settings. It retains existing Issuer and
ManagedCertificate resources. When true, the existing subordinate behavior remains
unchanged (including secondary creation independent of primary install/create).
Both gates false is valid and removes all chart application ingress. With Traefik
enabled, disabling legacy leaves the new Ingress, middleware and TLS binding intact.
Certificate renewal after legacy removal still needs runtime verification.

Validate a values file before reconciliation:

```sh
helm lint charts/operator-wandb -f staged-values.yaml
helm template preview charts/operator-wandb -f staged-values.yaml > rendered.yaml
```

Inspect `rendered.yaml` for the expected legacy Ingress resources and absence of
Traefik Ingress/Middleware while staging. When activating, inspect the new Ingress's
entrypoint, namespace-qualified middleware annotation, named rules and TLS hosts;
compare the Middleware's `sourceRange` with the union of the two input lists.
Verify redirects and allowed/denied requests through the Traefik endpoint using
Host/SNI before any customer DNS change.

For rollback, retain or restore a verified legacy serving path before disabling
`traefikIngress`. To clear the policy, disable it and empty both CIDR lists. Leaving
CIDRs with policy disabled emits the warning described above. Removing the new
Ingress can affect an ingress-shim-owned certificate, so inspect ownership before
rollback as well. No DNS cutover or certificate cleanup is performed by this change.
