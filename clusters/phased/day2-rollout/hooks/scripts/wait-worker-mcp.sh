#!/bin/bash
# Argo CD Sync hook: wait until worker MachineConfigPool is fully updated.
set -euo pipefail
TIMEOUT="${TIMEOUT_SECONDS:-7200}"
DEADLINE=$(($(date +%s) + TIMEOUT))
echo "Waiting for MachineConfigPool/worker Updated=True and Updating!=True (timeout ${TIMEOUT}s)..."
while [ "$(date +%s)" -lt "$DEADLINE" ]; do
  updated="$(oc get machineconfigpool worker -o jsonpath='{.status.conditions[?(@.type=="Updated")].status}' 2>/dev/null || true)"
  updating="$(oc get machineconfigpool worker -o jsonpath='{.status.conditions[?(@.type=="Updating")].status}' 2>/dev/null || true)"
  if [[ "${updated}" == "True" && "${updating}" != "True" ]]; then
    echo "worker MCP is updated."
    exit 0
  fi
  echo "worker MCP: Updated=${updated:-?} Updating=${updating:-?}; sleeping 30s..."
  sleep 30
done
echo "Timeout waiting for worker MCP"
exit 1
