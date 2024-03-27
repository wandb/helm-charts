#!/bin/sh
#
# helm-dep-build-recursive
#
# Recursive version of `helm dep build`.
#
# Will hopefully become obsolete after: https://github.com/helm/helm/issues/2247

refreshdone=0
subcharts=$(ls `find . -name charts | sed 's/$/\/*\/Chart.yaml/'` 2>/dev/null | sed 's/\/Chart\.yaml$//')
for chart in . $subcharts; do
  echo $chart
  if helm dep list $chart | grep -v '\(^\|WARNING: no dependencies.*\|STATUS\|ok\|unpacked\)\s*$' >/dev/null; then
    if [ "$refreshdone" = 0 ]; then
      helm dep build $chart
      refreshdone=1
    else
      helm dep build --skip-refresh $chart
    fi
  fi
done