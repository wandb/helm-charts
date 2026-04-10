#!/bin/bash
# ============================================================
# MCP Server QA Verification
# ============================================================
#
# Covers the full QA workflow Zachary described:
#   1. Claim instance in #deploy-alerts
#   2. Go to https://<host>/console > Settings > Advanced > User Spec
#   3. Paste user spec with chart version + MCP config
#   4. Wait for operator to reconcile
#   5. Run verification checks
#   6. RESET User Spec to {} when done
#
# USAGE:
#   ./scripts/verify_qa_mcp.sh <QA_HOST>         Run all checks
#   ./scripts/verify_qa_mcp.sh --user-spec       Print User Spec JSON for console
#   ./scripts/verify_qa_mcp.sh --checklist        Print step-by-step QA checklist
#   ./scripts/verify_qa_mcp.sh --cleanup          Print cleanup reminder
#   ./scripts/verify_qa_mcp.sh --connect <name>   Connect to cluster via wandbctl
#
# EXAMPLES:
#   ./scripts/verify_qa_mcp.sh qa-azure.wandb.io
#   ./scripts/verify_qa_mcp.sh --user-spec | pbcopy   # copy to clipboard
#
# ============================================================

set -euo pipefail

# --- Configuration (edit for new releases) ---
CHART_VERSION="0.42.0-PR571-f0f6e79e"
IMAGE_REPO="us-central1-docker.pkg.dev/wandb-mcp-production/cloud-run-source-deploy/mcp-server"
IMAGE_TAG="0.3.0"
SOURCE_SHA="88c36a0a8a4b50de2396722cc0077d754e18ff9b"
PR_URL="https://github.com/wandb/helm-charts/pull/571"

# Production registry (use once IT grants access):
# PROD_IMAGE_REPO="wandb/mcp-server"
# Then remove the image override from the user spec.

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

pass()  { echo -e "${GREEN}[PASS]${NC} $1"; }
fail()  { echo -e "${RED}[FAIL]${NC} $1"; FAILURES=$((FAILURES + 1)); }
info()  { echo -e "${YELLOW}[INFO]${NC} $1"; }
header(){ echo -e "\n${BOLD}$1${NC}"; }

# ============================================================
# Mode: --user-spec
# ============================================================
if [ "${1:-}" = "--user-spec" ]; then
cat <<EOF
{
  "chart": {
    "url": "https://charts.wandb.ai",
    "name": "operator-wandb",
    "version": "${CHART_VERSION}"
  },
  "values": {
    "mcp-server": {
      "install": true,
      "image": {
        "repository": "${IMAGE_REPO}",
        "tag": "${IMAGE_TAG}"
      }
    },
    "weave-trace": {
      "install": true
    }
  }
}
EOF
echo "" >&2
echo "Paste this into: https://<QA_HOST>/console > Settings > Advanced > User Spec" >&2
echo "IMPORTANT: Reset User Spec to {} when done testing!" >&2
exit 0
fi

# ============================================================
# Mode: --cleanup
# ============================================================
if [ "${1:-}" = "--cleanup" ]; then
echo -e "${RED}${BOLD}============================================================${NC}"
echo -e "${RED}${BOLD}  CLEANUP REQUIRED: Reset User Spec to {}${NC}"
echo -e "${RED}${BOLD}============================================================${NC}"
echo ""
echo "Go to: https://<QA_HOST>/console > Settings > Advanced > User Spec"
echo ""
echo "Replace the entire User Spec content with:"
echo ""
echo "  {}"
echo ""
echo "Then click Save."
echo ""
echo -e "${RED}WARNING: Leaving stale config in User Spec can break the"
echo -e "instance for the next person. Always clean up.${NC}"
echo ""
echo "After cleanup: add a checkmark reaction to your #deploy-alerts claim."
exit 0
fi

# ============================================================
# Mode: --connect
# ============================================================
if [ "${1:-}" = "--connect" ]; then
DEPLOYMENT="${2:-}"
if [ -z "$DEPLOYMENT" ]; then
    echo "Usage: $0 --connect <deployment-name>"
    echo ""
    echo "Common names:"
    echo "  wandbctl mi access k8s 'local QA Azure'"
    echo "  wandbctl mi access k8s 'local QA AWS'"
    echo "  wandbctl mi access k8s 'local QA Google'"
    echo ""
    echo "After connecting, use k9s to navigate the cluster."
    exit 1
fi
echo "Connecting to cluster: $DEPLOYMENT"
echo "Running: wandbctl mi access k8s '$DEPLOYMENT'"
export PATH="$HOME/go/bin:$PATH"
wandbctl mi access k8s "$DEPLOYMENT"
exit $?
fi

# ============================================================
# Mode: --checklist
# ============================================================
if [ "${1:-}" = "--checklist" ]; then
cat <<'CHECKLIST'
============================================================
MCP Server QA Checklist
============================================================

BEFORE:
  [x] PR #571 pushed with image tag 0.3.0
  [x] Docker image built via Cloud Build
  [x] Pre-release chart on charts.wandb.ai
  [x] All snapshot tests pass locally
  [x] wandbctl and k9s installed

STEP 1: Claim instance
  [ ] Go to #deploy-alerts in Slack
  [ ] Check which QA env is free (azure/aws/google)
  [ ] Post: "Claiming qa-<env> for MCP server helm chart testing"
  [ ] Verify nobody responds claiming it's in use

STEP 2: Open console
  [ ] Go to https://qa-<env>.wandb.io/console
  [ ] You need ADMIN permissions (not just member)
  [ ] If no access: ask Zachary to grant admin on the instance

STEP 3: Check for stale config
  [ ] Settings > Advanced > look at User Spec
  [ ] If it has leftover config from someone else, note it
  [ ] Ideally it should be {} or empty before you start

STEP 4: Copy Active Spec chart section
  [ ] Settings > Advanced > Active Spec
  [ ] Note the current chart.version (so you can revert)

STEP 5: Apply our config
  [ ] Run: ./scripts/verify_qa_mcp.sh --user-spec | pbcopy
  [ ] Paste into User Spec field
  [ ] Click Save
  [ ] Wait 2-3 minutes for operator to reconcile

STEP 6: Verify
  [ ] Run: ./scripts/verify_qa_mcp.sh qa-<env>.wandb.io
  [ ] All checks should pass (health, 9 tools, auth 401)
  [ ] If pod fails: likely image pull (cross-project permissions)

STEP 7: Debug if needed (requires cluster access)
  [ ] Run: ./scripts/verify_qa_mcp.sh --connect "local QA Azure"
  [ ] Then: k9s (navigate to mcp-server pod)
  [ ] Check pod events, logs, image pull status

STEP 8: CLEANUP (CRITICAL)
  [ ] Run: ./scripts/verify_qa_mcp.sh --cleanup
  [ ] Go to console > Settings > Advanced > User Spec
  [ ] Replace entire content with: {}
  [ ] Click Save
  [ ] Add checkmark to your #deploy-alerts claim

AFTER:
  [ ] Screenshot/copy verification results
  [ ] If image pull failed: file IT request for wandb-production access
  [ ] If all passed: PR #571 is QA-validated
============================================================
CHECKLIST
exit 0
fi

# ============================================================
# Mode: verify (default)
# ============================================================
QA_HOST="${1:-}"
if [ -z "$QA_HOST" ]; then
    echo "MCP Server QA Verification"
    echo ""
    echo "Usage:"
    echo "  $0 <QA_HOST>              Run all verification checks"
    echo "  $0 --user-spec            Print User Spec JSON for console paste"
    echo "  $0 --user-spec | pbcopy   Copy User Spec to clipboard"
    echo "  $0 --checklist            Print step-by-step QA checklist"
    echo "  $0 --cleanup              Print cleanup reminder"
    echo "  $0 --connect <name>       Connect to cluster via wandbctl"
    echo ""
    echo "Examples:"
    echo "  $0 qa-azure.wandb.io"
    echo "  $0 qa-aws.wandb.io"
    exit 1
fi

FAILURES=0
CHECKS=0

echo "============================================================"
echo "MCP Server QA Verification"
echo "============================================================"
echo "Host:    https://$QA_HOST"
echo "Console: https://$QA_HOST/console"
echo "Chart:   $CHART_VERSION"
echo "Image:   $IMAGE_REPO:$IMAGE_TAG"
echo "Source:  $SOURCE_SHA"
echo "PR:      $PR_URL"
echo "Date:    $(date -u +'%Y-%m-%d %H:%M:%S UTC')"
echo "============================================================"

# ---- Check 1: Health endpoint ----
header "Check 1/5: Health endpoint"
CHECKS=$((CHECKS + 1))
HEALTH=$(curl -sf "https://${QA_HOST}/mcp/health" 2>/dev/null || echo "UNREACHABLE")
if echo "$HEALTH" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['status']=='healthy'" 2>/dev/null; then
    pass "Health endpoint returns healthy"
    echo "$HEALTH" | python3 -m json.tool 2>/dev/null || echo "$HEALTH"
else
    fail "Health endpoint: $HEALTH"
    if [ "$HEALTH" = "UNREACHABLE" ]; then
        info "Possible causes:"
        info "  - Operator hasn't reconciled yet (wait 2-3 min)"
        info "  - /mcp nginx route missing (check _mcp.tpl in helm chart)"
        info "  - Pod crashed (connect to cluster: $0 --connect 'local QA Azure')"
    fi
fi

# ---- Check 2: Tools count ----
header "Check 2/5: Tools count"
CHECKS=$((CHECKS + 1))
TOOLS=$(echo "$HEALTH" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tools_registered', 0))" 2>/dev/null || echo "0")
if [ "$TOOLS" = "9" ]; then
    pass "9 tools registered"
else
    fail "Tools registered: $TOOLS (expected 9)"
fi

# ---- Check 3: Auth enforcement ----
header "Check 3/5: Auth enforcement (unauthenticated -> 401)"
CHECKS=$((CHECKS + 1))
HTTP_CODE=$(curl -sf -o /dev/null -w "%{http_code}" \
    -X POST "https://${QA_HOST}/mcp" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json, text/event-stream" \
    -d '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"qa-check","version":"1.0"}},"id":1}' \
    2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "401" ]; then
    pass "Unauthenticated request returns 401"
else
    fail "Expected 401, got $HTTP_CODE"
    [ "$HTTP_CODE" = "404" ] && info "/mcp path not configured in nginx"
    [ "$HTTP_CODE" = "200" ] && info "Auth not enforced -- check MCP_AUTH_DISABLED env var"
fi

# ---- Check 4: Authenticated MCP initialize ----
header "Check 4/5: Authenticated MCP initialize"
CHECKS=$((CHECKS + 1))
if [ -n "${WANDB_API_KEY:-}" ]; then
    AUTH_RESP=$(curl -sf -X POST "https://${QA_HOST}/mcp" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json, text/event-stream" \
        -H "Authorization: Bearer $WANDB_API_KEY" \
        -d '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"qa-check","version":"1.0"}},"id":1}' \
        2>/dev/null || echo "FAILED")
    if echo "$AUTH_RESP" | grep -q '"result"'; then
        pass "Authenticated MCP initialize succeeded"
    else
        fail "Authenticated initialize failed: ${AUTH_RESP:0:300}"
    fi
else
    info "WANDB_API_KEY not set -- skipping"
    info "To test: export WANDB_API_KEY=<key> && $0 $QA_HOST"
fi

# ---- Check 5: Cluster inspection (optional) ----
header "Check 5/5: Cluster inspection (requires kubectl)"
CHECKS=$((CHECKS + 1))
if command -v kubectl &>/dev/null && kubectl cluster-info &>/dev/null 2>&1; then
    POD_STATUS=$(kubectl get pods -l app.kubernetes.io/name=mcp-server -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "NOT_FOUND")
    IMAGE=$(kubectl get pods -l app.kubernetes.io/name=mcp-server -o jsonpath='{.items[0].spec.containers[0].image}' 2>/dev/null || echo "UNKNOWN")
    if [ "$POD_STATUS" = "Running" ]; then
        pass "Pod running, image: $IMAGE"
    else
        fail "Pod status: $POD_STATUS, image: $IMAGE"
        info "Debug: kubectl describe pod -l app.kubernetes.io/name=mcp-server"
        info "Or use: k9s"
    fi
else
    info "No kubectl context -- skipping cluster check"
    info "To connect: $0 --connect 'local QA Azure'"
    info "Then re-run: $0 $QA_HOST"
fi

# ---- Summary ----
echo ""
echo "============================================================"
PASSED=$((CHECKS - FAILURES))
echo "RESULTS: ${PASSED}/${CHECKS} checks passed"
if [ "$FAILURES" -eq 0 ]; then
    echo -e "${GREEN}${BOLD}ALL CHECKS PASSED${NC}"
else
    echo -e "${RED}${BOLD}${FAILURES} CHECK(S) FAILED${NC}"
fi
echo "============================================================"
echo ""
echo -e "${YELLOW}${BOLD}REMEMBER: Reset User Spec to {} when done!${NC}"
echo "Run: $0 --cleanup"

exit $FAILURES
