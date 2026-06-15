# Cluster layouts (GitOps)

All cluster configuration consumed by OpenShift GitOps lives under **`clusters/phased/`**.

Each subdirectory is a **self-contained** Kustomize root (manifests stay inside the path so Argo CD does not need `buildOptions: --load-restrictor LoadRestrictionsNone`).

| Path | Applied by | Role |
|------|------------|------|
| `argocd-day2-rbac/` | Bootstrap script **and** `day2-argocd-rbac` (wave **-1**) | RBAC for Argo CD application controller |
| `day2-ordered/` | `day2-ordered` (default) | Single-app ordered rollout + 2 wait Jobs |
| `openshift-gitops-operator/` | Pre-Argo bootstrap | OLM install |
| `ntp-then-etcd/` | `day2-ntp-and-etcd` | NTP chrony → delay → etcd encryption |
| `infra-nodes/` | `day2-infra-nodes` | Infra MachineSets → delay |
| `ingress-on-infra/` | `day2-ingress-on-infra` | Default ingress on infra → delay |
| `registry-on-infra/` | `day2-registry-on-infra` | Image registry on infra → delay |
| `monitoring-on-infra/` | `day2-monitoring-on-infra` | Cluster monitoring on infra |

Topic folders at the repository root (`ntp-chrony-configuration/`, `infra-nodes-configuration/`, etc.) are **runbooks** and authoring references. When you change YAML there, update the matching copy under `clusters/phased/<bundle>/` and commit both.

Timing, sync waves, and delay hooks: [`phased/README.md`](phased/README.md).

Bootstrap: [`scripts/bootstrap-fresh-cluster.sh`](../scripts/bootstrap-fresh-cluster.sh) or [`gitops/README.md`](../gitops/README.md).
