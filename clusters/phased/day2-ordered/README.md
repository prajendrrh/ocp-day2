# Ordered Day 2 rollout (`day2-ordered`)

One Argo CD Application applies every Day 2 use case in **one sync**, in order, with **two** readiness wait Jobs (inline bash + `ose-cli`).

## Directory layout

```text
day2-ordered/
├── kustomization.yaml          # Kustomize entrypoint (Argo CD builds this)
├── wait-jobs.yaml              # Sync hooks: wait-for-worker-mcp, wait-for-infra-nodes
├── wait-job-rbac.yaml          # ServiceAccount + ClusterRole for wait Jobs
├── rbac/                       # Argo CD application-controller permissions
│   ├── clusterrole.yaml
│   ├── clusterrolebinding.yaml
│   ├── role-openshift-monitoring.yaml
│   └── rolebinding-openshift-monitoring.yaml
└── manifests/                  # Cluster Day 2 resources (edit here for GitOps)
    ├── 99-worker-chrony.yaml
    ├── machineset-infra-aws-zone-a.yaml
    ├── machineset-infra-aws-zone-b.yaml
    ├── ingresscontroller-default.yaml
    ├── imageregistry-cluster.yaml
    ├── cluster-monitoring-config.yaml
    └── apiserver-encryption-aesgcm.yaml
```

| File / folder | What it does |
|---------------|--------------|
| `manifests/` | OpenShift resources: NTP, infra nodes, ingress, registry, monitoring, etcd |
| `rbac/` | Lets `openshift-gitops-argocd-application-controller` patch cluster-scoped operator APIs |
| `wait-jobs.yaml` | Pauses the sync until worker MCP and infra nodes are actually ready |
| `wait-job-rbac.yaml` | Lets wait Jobs run `oc get` on MCP and nodes |

Sync waves are set with `argocd.argoproj.io/sync-wave` on each resource (no separate patches folder).

## Sync order

| Wave | Step |
|------|------|
| -10 | Argo CD controller RBAC (`rbac/`) |
| 0 | Wait-job ServiceAccount + ClusterRole |
| 1 | NTP `MachineConfig` (`99-worker-chrony`) |
| 2 | **Job:** worker MCP includes `99-worker-chrony`, all workers updated/ready |
| 3 | Infra `MachineSet`s (×2) |
| 4 | **Job:** ≥ `MIN_INFRA_NODES` infra nodes Ready (default **2**) |
| 5 | Ingress + image registry + monitoring (same wave, no waits between) |
| 6 | Etcd encryption (`APIServer`) |

## Prerequisites

- OpenShift cluster, `cluster-admin` (`oc login`)
- Cluster reaches **GitHub** (or your `repoURL`), **`registry.redhat.io`** (operator + `ose-cli` wait Jobs), **OperatorHub**
- Infra MachineSets match your cluster (default: **`gitops-2c2d8`**, `eu-west-1a` / `eu-west-1b`) — edit `manifests/machineset-*.yaml`

## Apply on a fresh cluster

### 1. Configure Git remote (once)

Edit `repoURL` and `targetRevision` if not using the default:

- `gitops/argocd/root-application.yaml`
- `gitops/bootstrap/day2-ordered.yaml`

Push all changes to that branch.

### 2. Bootstrap OpenShift GitOps

**Option A — script (recommended)**

```bash
export KUBECONFIG=/path/to/kubeconfig
cd /path/to/ocp-day2
./scripts/bootstrap-fresh-cluster.sh
```

**Option B — manual**

```bash
oc apply -k clusters/phased/openshift-gitops-operator
# Wait: oc get csv -n openshift-gitops-operator → Succeeded
# Wait: oc get pods -n openshift-gitops

oc apply -f gitops/argocd/root-application.yaml
```

`day2-root` syncs `gitops/bootstrap/`, which creates **`day2-ordered`** (automated sync).

### 3. Watch

```bash
oc get applications.argoproj.io -n openshift-gitops
oc get application day2-ordered -n openshift-gitops -w

oc get jobs -n openshift-gitops | grep wait-for
oc logs -n openshift-gitops -f job/wait-for-worker-mcp
oc logs -n openshift-gitops -f job/wait-for-infra-nodes
```

OpenShift console → **GitOps** → **day2-ordered**.

### 4. Verify (after sync)

```bash
oc get mcp worker
oc get nodes -l node-role.kubernetes.io/infra
oc get po -n openshift-ingress -owide
oc get configs.imageregistry cluster -o yaml | grep -A3 nodeSelector
oc get apiserver cluster -o jsonpath='{.spec.encryption.type}{"\n"}'
```

## Ongoing changes

1. Edit YAML under `manifests/` (and topic runbooks at repo root if you keep them aligned).
2. Commit and push.
3. Argo CD reconciles `day2-ordered` automatically.

## Tuning

| Setting | Where | Default |
|---------|--------|---------|
| Infra node count for wait Job | `wait-jobs.yaml` → `MIN_INFRA_NODES` | `2` |
| Cluster / AWS IDs for infra | `manifests/machineset-*.yaml` | `gitops-2c2d8` |
| Wait Job timeout | `wait-jobs.yaml` → `activeDeadlineSeconds` | `7200` (2h) |

## Requirements

- `registry.redhat.io/openshift4/ose-cli:latest` pullable (wait Jobs)
- Private Git: repository `Secret` in `openshift-gitops` before sync
