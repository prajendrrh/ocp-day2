# Sequential Day 2 rollout (experimental)

One Argo CD `Application` (`day2-rollout-sequential`) applies **all** Day 2 use cases in a **single sync** with global sync waves and **readiness** hook Jobs (not fixed sleeps).

Reuses manifests from sibling `clusters/phased/*` bundles (no duplicate YAML). Kustomize references parent paths, so the Application sets `buildOptions: --load-restrictor LoadRestrictionsNone`.

## Do not run both rollout modes on one cluster

| Mode | Applications |
|------|----------------|
| **Multi-app (default)** | `day2-argocd-rbac`, `day2-ntp-and-etcd`, `day2-infra-nodes`, … |
| **Sequential (this)** | `day2-rollout-sequential` only |

Both target the same cluster singletons (`APIServer/cluster`, image registry `Config`, etc.). Enable **one** mode in `gitops/bootstrap/kustomization.yaml`.

## Sync wave order

| Wave | What |
|------|------|
| -15 | Hook ServiceAccount, hook ClusterRole/Binding, hook scripts ConfigMap |
| -10 | Argo CD application-controller RBAC (`argocd-day2-rbac`) |
| 5 | NTP `MachineConfig` |
| 10 | **Hook:** worker `MachineConfigPool` Updated |
| 30 | Infra `MachineSet`s (×2) |
| 35 | **Hook:** ≥2 infra nodes Ready |
| 40 | `IngressController/default` on infra |
| 45 | **Hook:** ingress available on infra |
| 50 | Image registry `Config` on infra |
| 55 | **Hook:** registry ready on infra |
| 60 | `cluster-monitoring-config` |
| 70 | Etcd encryption (`APIServer`) |
| 75 | **Hook:** encryption active, `kube-apiserver` Available |

Etcd runs **after** monitoring so infra/ingress/registry moves finish before API/etcd migration.

## Enable sequential mode

1. Edit `gitops/bootstrap/kustomization.yaml`:
   - **Comment out:** `day2-argocd-rbac.yaml` and all `day2-ntp-and-etcd` … `day2-monitoring-on-infra` lines.
   - **Uncomment:** `day2-rollout-sequential.yaml`
2. Commit and push; sync `day2-root` (or apply bootstrap on a fresh cluster).
3. On a cluster that already ran multi-app mode: **suspend or delete** the old child `Application`s in `openshift-gitops` before syncing sequential mode.

**Fresh test cluster:** bootstrap operator + RBAC script still works; only enable sequential line in bootstrap before `day2-root`.

## Hook images

Readiness Jobs use `registry.redhat.io/openshift4/ose-cli:latest` (cluster must pull from `registry.redhat.io`).

## Tuning

| Variable | Default | Job |
|----------|---------|-----|
| `TIMEOUT_SECONDS` | 7200 (ingress/registry 3600) | All hooks |
| `MIN_INFRA_NODES` | 2 | `wait-infra-nodes` |

Edit `hooks/scripts/*.sh` or add env to Job manifests.

## Watch

```bash
oc get application day2-rollout-sequential -n openshift-gitops
oc get jobs -n openshift-gitops -l 'job-name' | grep day2-rollout
```
