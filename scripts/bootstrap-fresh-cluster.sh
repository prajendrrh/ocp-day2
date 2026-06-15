#!/usr/bin/env bash
# Unattended bootstrap: OpenShift GitOps operator -> wait for Argo CD -> day2-root Application.
# Requires: oc, KUBECONFIG to the cluster, cluster-admin, OperatorHub (or adjusted Subscription).
# Edit gitops/argocd/root-application.yaml and Application sources to your repo URL before running.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v oc >/dev/null 2>&1; then
  echo "error: oc must be in PATH" >&2
  exit 1
fi

echo "==> Applying OpenShift GitOps operator (OLM)"
oc apply -k "${ROOT}/clusters/phased/openshift-gitops-operator"

echo "==> Waiting for ClusterServiceVersion (up to ~20 minutes on first install)"
for _ in $(seq 1 120); do
  phase="$(oc get csv -n openshift-gitops-operator -o jsonpath='{.items[0].status.phase}' 2>/dev/null || true)"
  if [[ "${phase}" == "Succeeded" ]]; then
    break
  fi
  sleep 10
done
phase="$(oc get csv -n openshift-gitops-operator -o jsonpath='{.items[0].status.phase}' 2>/dev/null || true)"
if [[ "${phase}" != "Succeeded" ]]; then
  echo "error: CSV not Succeeded (last phase: ${phase})" >&2
  oc get csv -n openshift-gitops-operator || true
  exit 1
fi

echo "==> Waiting for Argo CD server Deployment"
if oc get deployment openshift-gitops-server -n openshift-gitops &>/dev/null; then
  oc rollout status deployment/openshift-gitops-server -n openshift-gitops --timeout=20m
else
  # Alternate labels/names on some versions
  oc wait --for=condition=Available deployment \
    -l app.kubernetes.io/name=openshift-gitops-server \
    -n openshift-gitops --timeout=20m 2>/dev/null \
    || oc wait --for=condition=Available deployment -n openshift-gitops --all --timeout=20m
fi

echo "==> Applying Argo CD RBAC for Day 2 cluster-scoped resources"
oc apply -k "${ROOT}/clusters/phased/argocd-day2-rbac"

echo "==> Applying root Application (automated Day 2 rollout)"
oc apply -f "${ROOT}/gitops/argocd/root-application.yaml"

echo "==> Done. Watch: oc get applications.argoproj.io -n openshift-gitops"
echo "    Argo CD will sync day2-root and all child Applications without manual Sync."
