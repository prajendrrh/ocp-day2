# OpenShift GitOps (single source of truth)

Argo CD reconciles **one** Day 2 Application — **`day2-ordered`** — from `clusters/phased/day2-ordered/`.

## Repository layout

```text
ocp-day2/
├── clusters/phased/
│   ├── openshift-gitops-operator/   # Pre-Argo: install GitOps operator
│   └── day2-ordered/              # All Day 2 manifests + wait Jobs (Argo path)
├── gitops/
│   ├── argocd/root-application.yaml   # day2-root (app-of-apps)
│   └── bootstrap/
│       ├── day2-appproject.yaml
│       ├── day2-ordered.yaml          # Child Application → clusters/phased/day2-ordered
│       └── kustomization.yaml
├── scripts/bootstrap-fresh-cluster.sh
└── <topic>/                           # Runbooks (ntp, infra, ingress, …)
```

| Path | Role |
|------|------|
| `gitops/argocd/` | Root `Application` (`day2-root`) — apply once per cluster |
| `gitops/bootstrap/` | Renders `day2-appproject` + `day2-ordered` (synced by `day2-root`) |
| `clusters/phased/day2-ordered/` | Kustomize bundle Argo builds and applies |

Full apply steps: [`clusters/phased/day2-ordered/README.md`](../clusters/phased/day2-ordered/README.md).

## Prerequisites

- OpenShift with cluster-admin access
- OpenShift GitOps operator (see [`openshift-gitops-operator/README.md`](../openshift-gitops-operator/README.md))
- Git remote reachable from the cluster
- `registry.redhat.io` for operator and wait Job images

## Configure Git remote

Default: `https://github.com/prajendrrh/ocp-day2.git`, branch `main`. Edit:

- `gitops/argocd/root-application.yaml`
- `gitops/bootstrap/day2-ordered.yaml`

Tighten `spec.sourceRepos` in `day2-appproject.yaml` for production.

## Bootstrap (fresh cluster)

1. **Install operator** — `oc apply -k clusters/phased/openshift-gitops-operator` or run [`scripts/bootstrap-fresh-cluster.sh`](../scripts/bootstrap-fresh-cluster.sh).
2. **Private Git** — repository `Secret` in `openshift-gitops` if needed.
3. **Apply root Application** — `oc apply -f gitops/argocd/root-application.yaml` (script does this).
4. **Watch** — `oc get application day2-ordered -n openshift-gitops`.

`day2-root` uses automated sync; `day2-ordered` runs the full ordered rollout without manual Sync clicks.

## Rollout order (summary)

| Wave | Step |
|------|------|
| 1 | NTP |
| 2 | Wait worker MCP |
| 3 | Infra MachineSets |
| 4 | Wait infra Ready |
| 5 | Ingress + registry + monitoring |
| 6 | Etcd encryption |

Infra defaults: cluster **`gitops-2c2d8`**, zones **eu-west-1a/b**. Edit `clusters/phased/day2-ordered/manifests/`.

## References

- [Red Hat OpenShift GitOps](https://docs.openshift.com/gitops/latest/)
- [OpenShift Day two operations](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/day_two_operations_guide/index)
