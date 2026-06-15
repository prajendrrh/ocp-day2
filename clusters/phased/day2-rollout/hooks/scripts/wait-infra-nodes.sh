#!/bin/bash
# Argo CD Sync hook: wait until enough infrastructure nodes are Ready.
set -euo pipefail
TIMEOUT="${TIMEOUT_SECONDS:-7200}"
MIN_NODES="${MIN_INFRA_NODES:-2}"
DEADLINE=$(($(date +%s) + TIMEOUT))
echo "Waiting for at least ${MIN_NODES} Ready infra nodes (timeout ${TIMEOUT}s)..."
while [ "$(date +%s)" -lt "$DEADLINE" ]; do
  ready="$(oc get nodes -l node-role.kubernetes.io/infra -o jsonpath='{range .items[*]}{.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}' 2>/dev/null | grep -c '^True$' || true)"
  if [[ "${ready}" -ge "${MIN_NODES}" ]]; then
    echo "Ready infra nodes: ${ready}"
    oc get nodes -l node-role.kubernetes.io/infra -o wide
    exit 0
  fi
  echo "Ready infra nodes: ${ready}/${MIN_NODES}; sleeping 30s..."
  sleep 30
done
echo "Timeout waiting for infra nodes"
exit 1
