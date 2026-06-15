# PoC — OCP Day 2 Operations

This repository is a structured proof of concept (PoC) for **OpenShift Day 2 operations**.

- **GitOps path (recommended for SSOT):** cluster configuration is **configuration as code**—manifests and Kustomize under `clusters/` and `gitops/`, reconciled by OpenShift GitOps. After the operator is running, **ongoing** Day 2 changes are Git commits only. A small **bootstrap script** (`scripts/bootstrap-fresh-cluster.sh`) is optional glue for a brand-new cluster (install operator, wait, apply root `Application`); it does not replace GitOps for configuration.
- **Topic runbooks:** optional narrative folders (sometimes with `oc` examples for learning, troubleshooting, or one-off tasks). They are not required when you manage the cluster through GitOps.

## New cluster: phased validation (GitOps first, then NTP + etcd automatically)

The default bootstrap uses a **single child Application** (**`day2-ntp-and-etcd`**) so Argo CD applies **MachineConfig (NTP) before APIServer (etcd encryption)** using sync waves—**no manual “Sync” clicks** for NTP or etcd once `day2-root` is syncing.

1. **Confirm Git remote** — `repoURL` / `targetRevision` default to **`https://github.com/prajendrrh/ocp-day2.git`** and **`main`** in `gitops/argocd/root-application.yaml` and in each `gitops/bootstrap/day2-*.yaml` you enable. Change them if you use another fork or branch.
2. **Unattended install (recommended on a fresh cluster):** from a clone of this repo, with `KUBECONFIG` pointing at the cluster and **cluster-admin**:

   ```bash
   ./scripts/bootstrap-fresh-cluster.sh
   ```

   That installs the OpenShift GitOps operator, waits until Argo CD is ready, applies **`day2-root`**, and Argo CD then **automatically** syncs NTP and etcd in order. If the repo is private, create a Git credential `Secret` in `openshift-gitops` before or after the script (see [`gitops/README.md`](gitops/README.md)).

3. **Validate** — watch `oc get applications.argoproj.io -n openshift-gitops`, MachineConfig pools, and API server encryption status per [`etcd-encryption/README.md`](etcd-encryption/README.md) and [`ntp-chrony-configuration/README.md`](ntp-chrony-configuration/README.md).

4. **Add more topics** — when this path is solid, uncomment or add one `Application` line at a time in [`gitops/bootstrap/kustomization.yaml`](gitops/bootstrap/kustomization.yaml), commit, let `day2-root` reconcile, and validate before adding the next.

**Manual alternative:** install the operator and root `Application` step-by-step as in [`openshift-gitops-operator/README.md`](openshift-gitops-operator/README.md) and [`gitops/README.md`](gitops/README.md). For `kubectl` / `oc apply -k` against `clusters/all/*` paths, you may need `--load-restrictor=LoadRestrictionsNone` (see script); Argo CD is configured in the `Application` manifests to use the same so builds from Git succeed.

## Environment

- OpenShift: (fill in once chosen)
- Access: cluster-admin (recommended for most Day 2 tasks)
- CLI tools: `oc`, `kubectl` (optional), `jq` (optional)

## Repo map (topics)

Topic folders use **descriptive names** (no numeric prefixes). For a new cluster, start with **OpenShift GitOps operator**, then use GitOps for the rest.

| Folder | Summary |
|--------|---------|
| [`openshift-gitops-operator/`](openshift-gitops-operator/README.md) | Install the Red Hat OpenShift GitOps operator (OLM); do this **first** on a new cluster |
| [`ntp-chrony-configuration/`](ntp-chrony-configuration/README.md) | NTP (chrony) via MachineConfig |
| [`etcd-encryption/`](etcd-encryption/README.md) | Etcd encryption at rest |
| [`topic-template/`](topic-template/README.md) | Copy as a starting point for new topics |
| [`clusters/`](clusters/README.md) | Kustomize paths consumed by OpenShift GitOps |
| [`gitops/`](gitops/README.md) | Argo CD `Application` and `AppProject` manifests |

Each topic folder should contain:

- `README.md` with prerequisites, a numbered procedure, and expected output
- Minimal YAML manifests (only when required), stored alongside the README (no `manifests/` subfolder)

## GitOps (single source of truth)

To manage manifests with **OpenShift GitOps** (Argo CD), use the Kustomize paths under `clusters/` and the bootstrap manifests under `gitops/`. Topic folders are the **authoring** location for YAML; `clusters/all/<component>/` references them so you do not maintain two copies. After GitOps is installed and the root `Application` exists, **ongoing Day 2 changes are commits to this repository**, not ad hoc shell.

- Bootstrap and layout: [`gitops/README.md`](gitops/README.md)
- Cluster entrypoints: [`clusters/README.md`](clusters/README.md)

## Quick start

**New cluster:** follow **New cluster: phased validation** above (GitOps → NTP → etcd), then [`gitops/README.md`](gitops/README.md).

**Runbook (optional):** open any topic folder and follow its `README.md` for a guided walkthrough.

## Conventions

- All docs are in English.
- Prefer declarative resources (YAML) over manual imperative steps when possible.
- For GitOps, treat sensitive values with cluster-side patterns that are still declarative at the edge (for example Sealed Secrets, External Secrets Operator, or CSI driver volume mounts)—not checked-in shell that mutates the cluster.
- Include official documentation links for every operator/API/feature used: `https://docs.redhat.com` or `https://docs.openshift.com`.
