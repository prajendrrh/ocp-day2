# OpenShift GitOps (single source of truth)

This directory wires the repository into **OpenShift GitOps** (Argo CD) so Day 2 manifests stay declarative, versioned, and reconciled from Git.

## Configuration as code

Everything Argo CD applies from this repo is **plain Kubernetes/OpenShift YAML** (including Kustomize composition). After the GitOps operator is running, **ongoing** Day 2 changes are Git commits and automated sync—no imperative shell for those resources. The first time on a **new** cluster you still need the operator plus the root `Application`; use your own automation or the optional [`scripts/bootstrap-fresh-cluster.sh`](../scripts/bootstrap-fresh-cluster.sh) (waits for readiness, then applies `day2-root`).

## Layout

| Path | Role |
|------|------|
| `clusters/phased/` | **All** cluster Kustomize bundles (self-contained). See [`clusters/phased/README.md`](../clusters/phased/README.md). |
| `gitops/argocd/` | Root `Application` (`day2-root`) only. |
| `gitops/bootstrap/` | Child `Application` and `AppProject` YAML synced by `day2-root` (same directory for Argo CD load rules). |

## Prerequisites

- OpenShift with the **Red Hat OpenShift GitOps** operator installed (default instance in `openshift-gitops`). On a **new** cluster, install it first from [`clusters/phased/openshift-gitops-operator`](../clusters/phased/openshift-gitops-operator) (see [`openshift-gitops-operator/README.md`](../openshift-gitops-operator/README.md)).
- This repository pushed to a Git remote Argo CD can reach (HTTPS or SSH + credentials if private).
- Cluster-admin (or equivalent) for first-time bootstrap objects.

## Configure the Git remote

The manifests default to `https://github.com/prajendrrh/ocp-day2.git` and `targetRevision: main`. To use a different remote or branch, edit:

- `gitops/argocd/root-application.yaml`
- Each `gitops/bootstrap/day2-*.yaml` listed under `gitops/bootstrap/kustomization.yaml` `resources:`

Use your fork URL and branch or tag.

Tighten `spec.sourceRepos` in `gitops/bootstrap/day2-appproject.yaml` for production instead of `*`.

## Bootstrap (in-cluster Argo CD)

1. If Argo CD is not installed yet, apply the operator from [`clusters/phased/openshift-gitops-operator`](../clusters/phased/openshift-gitops-operator). For a **fully unattended** first pass, run [`scripts/bootstrap-fresh-cluster.sh`](../scripts/bootstrap-fresh-cluster.sh) from a repo clone (requires `oc` and `KUBECONFIG`). The script also applies [`clusters/phased/argocd-day2-rbac`](../clusters/phased/argocd-day2-rbac) so the application controller can patch cluster-scoped operator configs (image registry, ingress, APIServer, etc.). The `day2-root` Application cannot install the operator first—there is no Argo CD until the operator exists.

2. If the cluster cannot reach your Git server without credentials, create a repository `Secret` in `openshift-gitops` per [Configuring Argo CD to access the Git repository](https://docs.openshift.com/gitops/latest/gitops/configuring_argo_cd_to_access_the_git_repository.html).

3. Create the root `Application` once from `gitops/argocd/root-application.yaml` (the bootstrap script does this after Argo CD is ready). It uses the built-in `default` Argo CD project so you do not need `day2-ops` to exist first.

4. With **automated** sync on `day2-root`, the child Application **`day2-ordered`** runs the full Day 2 sequence in one sync—see [`clusters/phased/day2-ordered/README.md`](../clusters/phased/day2-ordered/README.md).

### Default bootstrap: `day2-ordered`

`gitops/bootstrap/kustomization.yaml` enables **`day2-ordered`** (single Application):

| Wave | Step |
|------|------|
| 1 | NTP MachineConfig |
| 2 | Wait worker MCP Updated |
| 3 | Infra MachineSets |
| 4 | Wait infra nodes Ready |
| 5 | Ingress + registry + monitoring |
| 6 | Etcd encryption |

Infra MachineSets target cluster **`gitops-tfhd4`** (`eu-west-1a` / `eu-west-1b`). Edit `clusters/phased/day2-ordered/manifests/` if your cluster differs.

Legacy six-app bootstrap is commented in the same `kustomization.yaml`.

## Secrets and merge-sensitive resources

Keep secrets out of plain Git when possible; use operators or controllers that materialize `Secret` objects from encrypted or external stores (Sealed Secrets, External Secrets Operator, vault agents, and so on)—those integrations are themselves configured with more YAML in Git.

## Multiple clusters

This repo is structured for **one cluster per path** today. For many clusters, add paths such as `clusters/phased/<cluster-name>/` (Kustomize or Helm) and either duplicate `Application` manifests with different `destination` servers or move to an **ApplicationSet** with a cluster generator (often combined with **Red Hat Advanced Cluster Management**). See [ApplicationSet](https://argo-cd.readthedocs.io/en/stable/user-guide/application-set/) and the OpenShift GitOps documentation.

## References

- [Red Hat OpenShift GitOps](https://docs.openshift.com/gitops/latest/)
- [OpenShift Container Platform — Day two operations overview](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/day_two_operations_guide/index)
