#!/usr/bin/env bash

set -euo pipefail

anonymous_config="$RUNNER_TEMP/helm-anonymous/config.json"
download_dir="$RUNNER_TEMP/helm-anonymous/downloads"
mkdir -p "$download_dir"
while IFS= read -r ref; do
  [ -z "$ref" ] && continue
  tagged_ref=${ref%@*}
  chart_ref=${tagged_ref%:*}
  chart_version=${tagged_ref##*:}
  echo "Pulling $chart_ref:$chart_version without credentials"
  helm pull \
    "oci://${chart_ref}" \
    --version "$chart_version" \
    --destination "$download_dir" \
    --registry-config "$anonymous_config"
done < pushed-refs.txt
echo "All published charts are publicly accessible."
