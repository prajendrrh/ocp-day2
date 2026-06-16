# PoC — OCP Day 2 Operations

OpenShift **Day 2** configuration as code, reconciled by **OpenShift GitOps** (Argo CD).

One Application — **`day2-ordered`** — applies NTP, infra nodes, ingress, registry, monitoring, and etcd encryption in a **single ordered sync**, with two readiness wait Jobs between major steps.

## Repository layout

```text
ocp-day2/
├── clusters/
│   └── phased/
│       ├── openshift-gitops-operator/   # Step 0: install GitOps (before Argo exists)
│       └── day2-ordered/                # All Day 2 YAML + wait Jobs (Argo applies this)
│           ├── kustomization.yaml
│           ├── wait-jobs.yaml
│           ├── wait-job-rbac.yaml
│           ├── rbac/                    # Argo controller permissions
│           └── manifests/               # NTP, infra, ingress, registry, monitoring, etcd
├── gitops/
│   ├── argocd/root-application.yaml     # day2-root — apply once per cluster
│   └── bootstrap/                       # day2-appproject + day2-ordered
├── scripts/bootstrap-fresh-cluster.sh   # Operator → wait → day2-root
├── openshift-gitops-operator/           # Runbook for operator install
├── infra-nodes-configuration/           # Runbooks (optional reading)
├── ingress-on-infra/
├── registry-on-infra/
├── monitoring-on-infra/
├── ntp-chrony-configuration/
├── etcd-encryption/
└── topic-template/
```

| Area | Purpose |
|------|---------|
| **`clusters/phased/day2-ordered/`** | **Source of truth** for what Argo CD applies |
| **`gitops/`** | Wires the repo into Argo CD (`day2-root` → `day2-ordered`) |
| **Topic folders** | Runbooks and docs; edit `day2-ordered/manifests/` for GitOps changes |

Details: [`clusters/README.md`](clusters/README.md), [`gitops/README.md`](gitops/README.md).

## Apply on a fresh cluster

### Before you start

1. `oc login` as cluster-admin; set `KUBECONFIG`.
2. Push this repo to Git; set `repoURL` / `targetRevision` in `gitops/argocd/root-application.yaml` and `gitops/bootstrap/day2-ordered.yaml` if needed.
3. Customize infra MachineSets in `clusters/phased/day2-ordered/manifests/machineset-*.yaml` for your cluster (default: **`gitops-2c2d8`**, **eu-west-1a/b**).

### Bootstrap

```bash
cd /path/to/ocp-day2
./scripts/bootstrap-fresh-cluster.sh
```

Or manually: install operator → wait for Argo CD → `oc apply -f gitops/argocd/root-application.yaml`.

### Watch

```bash
oc get application day2-ordered -n openshift-gitops
oc get jobs -n openshift-gitops | grep wait-for
```

Full steps and wave table: [`clusters/phased/day2-ordered/README.md`](clusters/phased/day2-ordered/README.md).

## Rollout order

| After | Wait |
|-------|------|
| NTP applied | Worker MCP ready (wait Job) |
| Infra MachineSets applied | Infra nodes Ready (wait Job) |
| Ingress + registry + monitoring | No wait (same wave) |
| Then | Etcd encryption (last) |

## Ongoing changes

Edit `clusters/phased/day2-ordered/manifests/`, commit, push — Argo CD syncs automatically.

## Conventions

- Docs in English; prefer declarative YAML over manual `oc apply` for managed resources.
- Official links: [docs.redhat.com](https://docs.redhat.com), [docs.openshift.com](https://docs.openshift.com).
