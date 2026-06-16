# Cluster layouts (GitOps)

All Day 2 cluster configuration for Argo CD lives under **`clusters/phased/`**.

| Path | Role |
|------|------|
| [`phased/openshift-gitops-operator/`](phased/openshift-gitops-operator/) | Install OpenShift GitOps **before** Argo CD exists (not synced by Argo) |
| [`phased/day2-ordered/`](phased/day2-ordered/) | **Single** Kustomize bundle — synced by Argo CD `day2-ordered` |

Topic folders at the repo root (`ntp-chrony-configuration/`, `infra-nodes-configuration/`, etc.) are **runbooks**. The manifests Argo applies are in **`clusters/phased/day2-ordered/manifests/`** — keep them in sync when you edit settings.

Apply steps and sync-wave order: [`phased/day2-ordered/README.md`](phased/day2-ordered/README.md).

Bootstrap: [`scripts/bootstrap-fresh-cluster.sh`](../scripts/bootstrap-fresh-cluster.sh) or [`gitops/README.md`](../gitops/README.md).
