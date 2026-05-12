# OpenShift GitOps (single source of truth)

This directory wires the repository into **OpenShift GitOps** (Argo CD) so Day 2 manifests stay declarative, versioned, and reconciled from Git.

## Configuration as code

Everything Argo CD applies from this repo is **plain Kubernetes/OpenShift YAML** (including Kustomize composition). There is **no bash automation** here for rolling out or updating Day 2 settings: you merge to Git, Argo CD reconciles, and the live object is the API server’s view of those manifests. One-time platform concerns (installing the GitOps operator, registering a repository credential, applying the root `Application` the first time) are still small, declarative steps—apply the same YAML with whatever workflow your organization uses (console, pipeline, or a single `kubectl`/`oc` apply of a resource file), not a maintained script in this repository.

## Layout

| Path | Role |
|------|------|
| `clusters/all/<component>/` | Kustomize entrypoints that reference the numbered topic YAML (no duplicate copies). |
| `clusters/hub/` | Optional **all-in-one** Kustomize stack if you prefer one Argo CD Application instead of several. |
| `gitops/argocd/` | `AppProject` (`day2-ops`) and the **root** `Application` (app-of-apps). |
| `gitops/bootstrap/` | Kustomize that renders the child `Application` objects managed by `day2-root`. |
| `gitops/applications/` | Child `Application` manifests (one logical Day 2 area each). |
| `gitops/optional/` | Opt-in apps (for example LDAP OAuth) you add to bootstrap when ready. |

## Prerequisites

- OpenShift with the **Red Hat OpenShift GitOps** operator installed (default instance in `openshift-gitops`). On a **new** cluster, install it declaratively first using [`07-openshift-gitops-operator/README.md`](../07-openshift-gitops-operator/README.md) (or the equivalent Kustomize path `clusters/all/openshift-gitops-operator`).
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

1. If Argo CD is not installed yet, apply the operator manifests from topic **07** (for example `oc apply -k clusters/all/openshift-gitops-operator` from the repo root). The `day2-root` Application cannot install the operator on the same cluster first—there is no Argo CD to run the sync until the operator exists.
2. If the cluster cannot reach your Git server without credentials, create a repository `Secret` in `openshift-gitops` per [Configuring Argo CD to access the Git repository](https://docs.openshift.com/gitops/latest/gitops/configuring_argo_cd_to_access_the_git_repository.html).
3. Create the root `Application` resource once from `gitops/argocd/root-application.yaml` (it uses the built-in `default` Argo CD project so you do not need `day2-ops` to exist first). Use the OpenShift console, your CI/CD apply step, or any Kubernetes client—same manifest, no repo-local script.

4. In the Argo CD UI or CLI, open the `day2-root` Application and **Sync**. The first sync creates `day2-ops` (sync-wave `-2`) then the child Applications.

Child apps:

- **day2-monitoring-placement** and **day2-ntp-chrony** use automated sync.
- **day2-log-forwarding** and **day2-etcd-encryption** are **manual** sync until you trigger them in Argo CD (after prerequisites in each topic README).

## Secrets and merge-sensitive resources

Keep secrets out of plain Git when possible; still avoid shell glue by using operators or controllers that materialize `Secret` objects from encrypted or external stores (Sealed Secrets, External Secrets Operator, vault agents, and so on)—those integrations are themselves configured with more YAML in Git.

- **LDAP** (`clusters/all/ldap-oauth`): requires `Secret` / `ConfigMap` in `openshift-config` before sync; applying a full `OAuth` manifest can overwrite other identity providers if your live object differs—review [Configuring an LDAP identity provider](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/authentication_and_authorization/configuring-ldap-identity-provider) and prefer patches or a dedicated pipeline if you already have multiple IdPs. Enable via `gitops/optional/application-ldap-oauth.yaml` only when ready.
- **SIEM forwarding**: provide TLS CA material and adjust URLs as described in `04-log-forwarding-to-siem/README.md` before syncing **day2-log-forwarding** (again as declarative resources, not one-off shell).

## One Application instead of app-of-apps

Create an Argo CD `Application` with `spec.source.path: clusters/hub` (and the same `repoURL` / `targetRevision`). Enable commented `resources` in `clusters/hub/kustomization.yaml` for etcd and LDAP if you want them in the same bundle.

## Multiple clusters

This repo is structured for **one cluster per path** today. For many clusters, add paths such as `clusters/<cluster-name>/` (Kustomize or Helm) and either duplicate `Application` manifests with different `destination` servers or move to an **ApplicationSet** with a cluster generator (often combined with **Red Hat Advanced Cluster Management**). See [ApplicationSet](https://argo-cd.readthedocs.io/en/stable/user-guide/application-set/) and the OpenShift GitOps documentation.

## References

- [Red Hat OpenShift GitOps](https://docs.openshift.com/gitops/latest/)
- [OpenShift Container Platform — Day two operations overview](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/day_two_operations_guide/index)
