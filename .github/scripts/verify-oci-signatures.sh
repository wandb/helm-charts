#!/usr/bin/env bash

set -euo pipefail

while IFS= read -r ref; do
  [ -z "$ref" ] && continue
  echo "Verifying $ref"
  cosign verify \
    --certificate-identity-regexp "$CERT_IDENTITY_REGEXP" \
    --certificate-oidc-issuer "$CERT_OIDC_ISSUER" \
    "$ref" >/dev/null
done < pushed-refs.txt
echo "All published charts verified."
