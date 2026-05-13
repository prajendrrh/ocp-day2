# OpenShift GitOps (single source of truth)

This directory wires the repository into **OpenShift GitOps** (Argo CD) so Day 2 manifests stay declarative, versioned, and reconciled from Git.

## Configuration as code

Everything Argo CD applies from this repo is **plain Kubernetes/OpenShift YAML** (including Kustomize composition). After the GitOps operator is running, **ongoing** Day 2 changes are Git commits and automated sync—no imperative shell for those resources. The first time on a **new** cluster you still need the operator plus the root `Application`; use your own automation or the optional [`scripts/bootstrap-fresh-cluster.sh`](../scripts/bootstrap-fresh-cluster.sh) (waits for readiness, then applies `day2-root`).

## Layout

| Path | Role |
|------|------|
| `clusters/all/<component>/` | Kustomize entrypoints that reference topic YAML under the named topic folders (no duplicate copies). |
| `clusters/hub/` | Optional **single Application** stack; defaults to **NTP + etcd** (same order as phased testing). |
| `gitops/argocd/` | `AppProject` (`day2-ops`) and the **root** `Application` (app-of-apps). |
| `clusters/phased/` | Ordered bundles (for example **NTP then etcd** in one sync) using Argo CD sync waves. |
| `gitops/bootstrap/` | Kustomize that renders the child `Application` objects managed by `day2-root` (default: **`day2-ntp-and-etcd`** only). |
| `gitops/applications/` | Child `Application` manifests (one logical Day 2 area each). |
| `gitops/optional/` | Opt-in apps (for example LDAP OAuth) you add to bootstrap when ready. |

## Prerequisites

- OpenShift with the **Red Hat OpenShift GitOps** operator installed (default instance in `openshift-gitops`). On a **new** cluster, install it declaratively first using [`openshift-gitops-operator/README.md`](../openshift-gitops-operator/README.md) (or the equivalent Kustomize path `clusters/all/openshift-gitops-operator`).
- This repository pushed to a Git remote Argo CD can reach (HTTPS or SSH + credentials if private).
- Cluster-admin (or equivalent) for first-time bootstrap objects.

## Configure the Git remote

Replace every `https://github.com/example/ocp-day2.git` and `targetRevision: main` in:

- `gitops/argocd/root-application.yaml`
- `gitops/applications/*.yaml`
- `gitops/optional/*.yaml` (if used)

Use your fork URL and branch or tag.

Tighten `spec.sourceRepos` in `gitops/argocd/day2-appproject.yaml` for production instead of `*`.

## Bootstrap (in-cluster Argo CD)

1. If Argo CD is not installed yet, apply the operator manifests from [`openshift-gitops-operator`](../openshift-gitops-operator/README.md). For a **fully unattended** first pass, run [`scripts/bootstrap-fresh-cluster.sh`](../scripts/bootstrap-fresh-cluster.sh) from a repo clone (requires `oc`, `kubectl`, and `KUBECONFIG`). The `day2-root` Application cannot install the operator on the same cluster first—there is no Argo CD to run that sync until the operator exists.

   Operator install uses `kubectl kustomize --load-restrictor=LoadRestrictionsNone` because Kustomize references live under topic folders outside `clusters/all/openshift-gitops-operator/`; the same flag is set on Argo `Application` sources so in-cluster builds match.

2. If the cluster cannot reach your Git server without credentials, create a repository `Secret` in `openshift-gitops` per [Configuring Argo CD to access the Git repository](https://docs.openshift.com/gitops/latest/gitops/configuring_argo_cd_to_access_the_git_repository.html).

3. Create the root `Application` resource once from `gitops/argocd/root-application.yaml` (the bootstrap script does this after Argo CD is ready). It uses the built-in `default` Argo CD project so you do not need `day2-ops` to exist first.

4. With **automated** sync on `day2-root`, the first sync creates `day2-ops` (sync-wave `-2`) then **`day2-ntp-and-etcd`**, which applies **NTP (sync wave 5) then etcd encryption (wave 20)** without manual Sync clicks.

### Phased validation (default bootstrap)

`gitops/bootstrap/kustomization.yaml` ships a **single** child Application, **`day2-ntp-and-etcd`**, which points at [`clusters/phased/ntp-then-etcd`](../clusters/phased/ntp-then-etcd) so one automated sync orders NTP before etcd. Both use **automated** `syncPolicy` on that Application.

| Child `Application` | Sync | Notes |
|---------------------|------|--------|
| **day2-ntp-and-etcd** | Automated | MachineConfig (wave 5) then `APIServer` encryption (wave 20). |

To use **separate** Applications instead (for example manual etcd), replace `day2-ntp-and-etcd.yaml` in `gitops/bootstrap/kustomization.yaml` with the commented `day2-ntp-chrony.yaml` / `day2-etcd-encryption.yaml` lines and tune `syncPolicy` on etcd as needed.

### Other Application manifests (not in bootstrap by default)

Ready-to-use files live under `gitops/applications/`; copy the commented pattern from `gitops/bootstrap/kustomization.yaml` to enable them (add one line at a time, validate, repeat). LDAP OAuth is under `gitops/optional/application-ldap-oauth.yaml`.

## Secrets and merge-sensitive resources

Keep secrets out of plain Git when possible; still avoid shell glue by using operators or controllers that materialize `Secret` objects from encrypted or external stores (Sealed Secrets, External Secrets Operator, vault agents, and so on)—those integrations are themselves configured with more YAML in Git.

- **LDAP** (`clusters/all/ldap-oauth`): requires `Secret` / `ConfigMap` in `openshift-config` before sync; applying a full `OAuth` manifest can overwrite other identity providers if your live object differs—review [Configuring an LDAP identity provider](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/authentication_and_authorization/configuring-ldap-identity-provider) and prefer patches or a dedicated pipeline if you already have multiple IdPs. Enable via `gitops/optional/application-ldap-oauth.yaml` only when ready.
- **SIEM forwarding**: provide TLS CA material and adjust URLs as described in `log-forwarding-to-siem/README.md` before syncing **day2-log-forwarding** (again as declarative resources, not one-off shell).

## One Application instead of app-of-apps

Create an Argo CD `Application` with `spec.source.path: clusters/hub` (same `repoURL` / `targetRevision`, and `spec.source.kustomize.buildOptions: --load-restrictor LoadRestrictionsNone` like the other Applications). `clusters/hub` reuses `clusters/phased/ntp-then-etcd` for the same ordering.

## Multiple clusters

This repo is structured for **one cluster per path** today. For many clusters, add paths such as `clusters/<cluster-name>/` (Kustomize or Helm) and either duplicate `Application` manifests with different `destination` servers or move to an **ApplicationSet** with a cluster generator (often combined with **Red Hat Advanced Cluster Management**). See [ApplicationSet](https://argo-cd.readthedocs.io/en/stable/user-guide/application-set/) and the OpenShift GitOps documentation.

## References

- [Red Hat OpenShift GitOps](https://docs.openshift.com/gitops/latest/)
- [OpenShift Container Platform — Day two operations overview](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/day_two_operations_guide/index)
