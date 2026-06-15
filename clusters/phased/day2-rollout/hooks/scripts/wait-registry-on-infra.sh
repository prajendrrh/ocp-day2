#!/bin/bash
# Argo CD Sync hook: wait until image registry is scheduled on infra and ready.
set -euo pipefail
TIMEOUT="${TIMEOUT_SECONDS:-3600}"
DEADLINE=$(($(date +%s) + TIMEOUT))
echo "Waiting for image registry on infra nodes (timeout ${TIMEOUT}s)..."
while [ "$(date +%s)" -lt "$DEADLINE" ]; do
  infra="$(oc get configs.imageregistry cluster -o jsonpath='{.spec.nodeSelector.node-role\.kubernetes\.io/infra}' 2>/dev/null || true)"
  ready="$(oc get deployment image-registry -n openshift-image-registry -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo 0)"
  if [[ -n "${infra}" && "${ready:-0}" -ge 1 ]]; then
    echo "Image registry readyReplicas=${ready} with infra nodeSelector."
    exit 0
  fi
  echo "Registry infra selector='${infra:-}' readyReplicas=${ready:-0}; sleeping 30s..."
  sleep 30
done
echo "Timeout waiting for registry on infra"
exit 1
