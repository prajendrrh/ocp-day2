# Ordered Day 2 rollout (single Application)

One Argo CD app applies all Day 2 use cases in **one sync** with **two** inline bash wait Jobs (`ose-cli`). No separate script files or ConfigMaps.

Keep `manifests/` copies in sync with sibling `clusters/phased/*` bundles when editing.

## Sync waves

| Wave | What |
|------|------|
| -10 | Argo CD application-controller RBAC |
| 0 | `wait-job` ServiceAccount + read-only ClusterRole for hooks |
| 1 | NTP `MachineConfig` (worker pool) |
| 2 | **Job:** worker `MachineConfigPool` Updated |
| 3 | Infra `MachineSet`s (×2) |
| 4 | **Job:** ≥ `MIN_INFRA_NODES` infra nodes Ready (default **2**) |
| 5 | Ingress + registry + monitoring (same wave, no waits between) |
| 6 | Etcd encryption (`APIServer`) |

## Bootstrap

`gitops/bootstrap/kustomization.yaml` enables **`day2-ordered`** by default (replaces six separate workload apps).

## Tuning

Edit `wait-jobs.yaml`:

- Infra count: set `MIN_INFRA_NODES` env on the infra wait container (default `2`; use `3` if you run three infra nodes).

## Requirements

- Cluster pulls `registry.redhat.io/openshift4/ose-cli:latest`
- Hook Jobs run in `openshift-gitops`

## Watch

```bash
oc get application day2-ordered -n openshift-gitops
oc get jobs -n openshift-gitops | grep wait-for
```
