#!/bin/bash
# Argo CD Sync hook: wait until APIServer etcd encryption (aesgcm) is active and kube-apiserver is Available.
set -euo pipefail
TIMEOUT="${TIMEOUT_SECONDS:-7200}"
DEADLINE=$(($(date +%s) + TIMEOUT))
echo "Waiting for etcd encryption and kube-apiserver Available (timeout ${TIMEOUT}s)..."
while [ "$(date +%s)" -lt "$DEADLINE" ]; do
  enc="$(oc get apiserver cluster -o jsonpath='{.spec.encryption.type}' 2>/dev/null || true)"
  avail="$(oc get clusteroperator kube-apiserver -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' 2>/dev/null || true)"
  degraded="$(oc get clusteroperator kube-apiserver -o jsonpath='{.status.conditions[?(@.type=="Degraded")].status}' 2>/dev/null || true)"
  if [[ "${enc}" == "aesgcm" && "${avail}" == "True" && "${degraded}" != "True" ]]; then
    echo "APIServer encryption.type=${enc}, kube-apiserver Available."
    exit 0
  fi
  echo "encryption.type=${enc:-?} kube-apiserver Available=${avail:-?} Degraded=${degraded:-?}; sleeping 60s..."
  sleep 60
done
echo "Timeout waiting for etcd encryption"
exit 1
