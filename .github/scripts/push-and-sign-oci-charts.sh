#!/usr/bin/env bash

set -euo pipefail

: > pushed-refs.txt
pushed_count=0
for tarball in .cr-release-packages/*.tgz; do
  [ -e "$tarball" ] || continue
  echo "Pushing $tarball to $OCI_REPO"
  push_output=$(helm push \
    "$tarball" \
    "$OCI_REPO" \
    --registry-config "$HOME/.docker/config.json" 2>&1)
  echo "$push_output"
  pushed=$(awk '/^Pushed: /{print $2}' <<< "$push_output")
  digest=$(awk '/^Digest: /{print $2}' <<< "$push_output")
  if [ -z "$pushed" ] || [ -z "$digest" ]; then
    echo "::error::failed to parse push output for $tarball"
    exit 1
  fi
  ref="${pushed}@${digest}"
  echo "Signing $ref"
  cosign sign --yes "$ref"
  echo "$ref" >> pushed-refs.txt
  pushed_count=$((pushed_count + 1))
done
if [ "$pushed_count" -eq 0 ]; then
  echo "::error::chart-releaser reported changed charts, but no OCI artifacts were found in .cr-release-packages/"
  exit 1
fi
echo "--- pushed and signed refs ---"
cat pushed-refs.txt
