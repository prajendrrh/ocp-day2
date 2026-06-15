#!/bin/bash
# Argo CD Sync hook: wait until default IngressController is on infra and available.
set -euo pipefail
TIMEOUT="${TIMEOUT_SECONDS:-3600}"
DEADLINE=$(($(date +%s) + TIMEOUT))
echo "Waiting for IngressController/default on infra nodes (timeout ${TIMEOUT}s)..."
while [ "$(date +%s)" -lt "$DEADLINE" ]; do
  infra="$(oc get ingresscontroller default -n openshift-ingress-operator -o jsonpath='{.spec.nodePlacement.nodeSelector.matchLabels.node-role\.kubernetes\.io/infra}' 2>/dev/null || true)"
  avail="$(oc get ingresscontroller default -n openshift-ingress-operator -o jsonpath='{.status.availableReplicas}' 2>/dev/null || echo 0)"
  if [[ -n "${infra}" && "${avail:-0}" -ge 1 ]]; then
    echo "IngressController availableReplicas=${avail} on infra."
    exit 0
  fi
  echo "IngressController infra selector='${infra:-}' availableReplicas=${avail:-0}; sleeping 30s..."
  sleep 30
done
echo "Timeout waiting for ingress on infra"
exit 1
