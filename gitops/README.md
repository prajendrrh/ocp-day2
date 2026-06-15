# OpenShift GitOps (single source of truth)

This directory wires the repository into **OpenShift GitOps** (Argo CD) so Day 2 manifests stay declarative, versioned, and reconciled from Git.

## Configuration as code

Everything Argo CD applies from this repo is **plain Kubernetes/OpenShift YAML** (including Kustomize composition). After the GitOps operator is running, **ongoing** Day 2 changes are Git commits and automated sync—no imperative shell for those resources. The first time on a **new** cluster you still need the operator plus the root `Application`; use your own automation or the optional [`scripts/bootstrap-fresh-cluster.sh`](../scripts/bootstrap-fresh-cluster.sh) (waits for readiness, then applies `day2-root`).

## Layout

| Path | Role |
|------|------|
| `clusters/all/<component>/` | Kustomize entrypoints that reference topic YAML under the named topic folders (no duplicate copies). |
| `clusters/hub/` | Optional **single Application** stack; defaults to **NTP + etcd** (same order as phased testing). |
| `gitops/argocd/` | Root `Application` (`day2-root`) only. |
| `clusters/phased/` | Ordered bundles (for example **NTP then etcd** in one sync) using Argo CD sync waves. |
| `gitops/bootstrap/` | `kustomization.yaml` plus **all** child `Application` and `AppProject` YAML used by `day2-root` (same directory so Kustomize works under Argo CD load rules). |

## Prerequisites

- OpenShift with the **Red Hat OpenShift GitOps** operator installed (default instance in `openshift-gitops`). On a **new** cluster, install it declaratively first using [`openshift-gitops-operator/README.md`](../openshift-gitops-operator/README.md) (or the equivalent Kustomize path `clusters/all/openshift-gitops-operator`).
- This repository pushed to a Git remote Argo CD can reach (HTTPS or SSH + credentials if private).
- Cluster-admin (or equivalent) for first-time bootstrap objects.

## Configure the Git remote

The manifests default to `https://github.com/prajendrrh/ocp-day2.git` and `targetRevision: main`. To use a different remote or branch, edit:

- `gitops/argocd/root-application.yaml`
- Each `gitops/bootstrap/day2-*.yaml` you list under `gitops/bootstrap/kustomization.yaml` `resources:`

Use your fork URL and branch or tag.

Tighten `spec.sourceRepos` in `gitops/bootstrap/day2-appproject.yaml` for production instead of `*`.

## Bootstrap (in-cluster Argo CD)

1. If Argo CD is not installed yet, apply the operator manifests from [`openshift-gitops-operator`](../openshift-gitops-operator/README.md). For a **fully unattended** first pass, run [`scripts/bootstrap-fresh-cluster.sh`](../scripts/bootstrap-fresh-cluster.sh) from a repo clone (requires `oc`, `kubectl`, and `KUBECONFIG`). The `day2-root` Application cannot install the operator on the same cluster first—there is no Argo CD to run that sync until the operator exists.

   Child `Application` sources that use **`clusters/all/<component>/`** still set `spec.source.kustomize.buildOptions: --load-restrictor LoadRestrictionsNone` because those Kustomizations reference topic YAML outside `clusters/`. The combined path **`clusters/phased/ntp-then-etcd`** keeps all manifests under that directory, so it does **not** need `buildOptions`. The **`day2-root`** build of `gitops/bootstrap` also does not (all YAML is under `gitops/bootstrap/`).

2. If the cluster cannot reach your Git server without credentials, create a repository `Secret` in `openshift-gitops` per [Configuring Argo CD to access the Git repository](https://docs.openshift.com/gitops/latest/gitops/configuring_argo_cd_to_access_the_git_repository.html).

3. Create the root `Application` resource once from `gitops/argocd/root-application.yaml` (the bootstrap script does this after Argo CD is ready). It uses the built-in `default` Argo CD project so you do not need `day2-ops` to exist first.

4. With **automated** sync on `day2-root`, the first sync creates `day2-ops` (sync-wave `-2`) then **`day2-ntp-and-etcd`**, which applies **NTP (sync wave 5) then etcd encryption (wave 20)** without manual Sync clicks.

### Phased validation (default bootstrap)

`gitops/bootstrap/kustomization.yaml` ships a **single** child Application, **`day2-ntp-and-etcd`**, which points at [`clusters/phased/ntp-then-etcd`](../clusters/phased/ntp-then-etcd). That folder contains **copies** of the NTP MachineConfig and etcd `APIServer` manifests (with sync-wave annotations) so Kustomize stays within the directory—**edit the topic YAML and the copies together** when you change chrony or encryption settings.

| Child `Application` | Sync | Notes |
|---------------------|------|--------|
| **day2-ntp-and-etcd** | Automated | MachineConfig (wave 5) then `APIServer` encryption (wave 20). |

To use **separate** Applications instead (for example manual etcd), replace `day2-ntp-and-etcd.yaml` in `gitops/bootstrap/kustomization.yaml` with the commented `day2-ntp-chrony.yaml` / `day2-etcd-encryption.yaml` lines and tune `syncPolicy` on etcd as needed.

### Infrastructure rollout (ordered, manual sync)

Enable **one** infra `Application` at a time in `gitops/bootstrap/kustomization.yaml`. Each file uses an Argo CD **sync-wave** annotation so when multiple are enabled, order is: **infra nodes (30) → ingress (40) → registry (50) → monitoring (60)**. None use automated `syncPolicy`—sync and validate in the UI/CLI before enabling the next.

| Application | Path | Topic |
|-------------|------|--------|
| `day2-infra-nodes` | `clusters/phased/infra-nodes` | [`infra-nodes-configuration`](../infra-nodes-configuration/README.md) |
| `day2-ingress-on-infra` | `clusters/phased/ingress-on-infra` | [`ingress-on-infra`](../ingress-on-infra/README.md) |
| `day2-registry-on-infra` | `clusters/phased/registry-on-infra` | [`registry-on-infra`](../registry-on-infra/README.md) |
| `day2-monitoring-on-infra` | `clusters/phased/monitoring-on-infra` | [`monitoring-on-infra`](../monitoring-on-infra/README.md) |

Customize `REPLACE_*` in `clusters/phased/infra-nodes/` MachineSet YAML before syncing `day2-infra-nodes`. Keep copies in sync with the topic folder under `infra-nodes-configuration/`.

## Secrets and merge-sensitive resources

Keep secrets out of plain Git when possible; use operators or controllers that materialize `Secret` objects from encrypted or external stores (Sealed Secrets, External Secrets Operator, vault agents, and so on)—those integrations are themselves configured with more YAML in Git.

## One Application instead of app-of-apps

Create an Argo CD `Application` with `spec.source.path: clusters/hub` (same `repoURL` / `targetRevision`). `clusters/hub` reuses `clusters/phased/ntp-then-etcd` (self-contained Kustomize).

## Multiple clusters

This repo is structured for **one cluster per path** today. For many clusters, add paths such as `clusters/<cluster-name>/` (Kustomize or Helm) and either duplicate `Application` manifests with different `destination` servers or move to an **ApplicationSet** with a cluster generator (often combined with **Red Hat Advanced Cluster Management**). See [ApplicationSet](https://argo-cd.readthedocs.io/en/stable/user-guide/application-set/) and the OpenShift GitOps documentation.

## References

- [Red Hat OpenShift GitOps](https://docs.openshift.com/gitops/latest/)
- [OpenShift Container Platform — Day two operations overview](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/day_two_operations_guide/index)
