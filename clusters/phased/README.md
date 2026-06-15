# Phased GitOps bundles (Argo CD)

## Default rollout: `day2-ordered` (one Application)

[`day2-ordered/`](day2-ordered/README.md) applies all Day 2 use cases in **one sync** with **two** inline bash wait Jobs (worker MCP, then infra nodes Ready). Ingress, registry, and monitoring share the same wave; etcd runs last.

| Wave | Step |
|------|------|
| -10 | Argo CD RBAC |
| 1 | NTP |
| 2 | Wait worker MCP |
| 3 | Infra MachineSets |
| 4 | Wait infra Ready |
| 5 | Ingress + registry + monitoring |
| 6 | Etcd encryption |

Bootstrap: `gitops/bootstrap/kustomization.yaml` → `day2-ordered.yaml`.

---

## Legacy bundles (multi-app, optional)

Self-contained Kustomize roots under each folder. Used when bootstrap lists separate `day2-*` Applications (commented out by default). Those apps auto-sync **in parallel**; sleep Jobs only apply inside each app.

| Path | Application |
|------|-------------|
| `argocd-day2-rbac/` | `day2-argocd-rbac` |
| `openshift-gitops-operator/` | Pre-Argo bootstrap only |
| `ntp-then-etcd/` | `day2-ntp-and-etcd` |
| `infra-nodes/` | `day2-infra-nodes` |
| `ingress-on-infra/` | `day2-ingress-on-infra` |
| `registry-on-infra/` | `day2-registry-on-infra` |
| `monitoring-on-infra/` | `day2-monitoring-on-infra` |

Keep copies in sync with topic folders at the repo root when editing manifests.
