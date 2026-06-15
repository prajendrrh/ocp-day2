# PoC — OCP Day 2 Operations

This repository is a structured proof of concept (PoC) for **OpenShift Day 2 operations**.

- **GitOps path (recommended for SSOT):** cluster configuration is **configuration as code**—manifests and Kustomize under `clusters/` and `gitops/`, reconciled by OpenShift GitOps. After the operator is running, **ongoing** Day 2 changes are Git commits only. A small **bootstrap script** (`scripts/bootstrap-fresh-cluster.sh`) is optional glue for a brand-new cluster (install operator, wait, apply root `Application`); it does not replace GitOps for configuration.
- **Topic runbooks:** optional narrative folders (sometimes with `oc` examples for learning, troubleshooting, or one-off tasks). They are not required when you manage the cluster through GitOps.

## New cluster: fully automated GitOps rollout

After the OpenShift GitOps operator is running and **`day2-root`** is applied, Argo CD **automatically** syncs all Day 2 use cases in order—**no manual Sync clicks** and **no `oc apply`** for manifests in this repo.

1. **Confirm Git remote** — `repoURL` / `targetRevision` default to **`https://github.com/prajendrrh/ocp-day2.git`** and **`main`**.
2. **Bootstrap (once per cluster):** run [`scripts/bootstrap-fresh-cluster.sh`](scripts/bootstrap-fresh-cluster.sh) or apply `gitops/argocd/root-application.yaml` after the operator is ready.
3. **Watch** — `oc get applications.argoproj.io -n openshift-gitops` and the Argo CD UI. Total elapsed time includes built-in **delay hooks** (see [timing](#automated-timing) below).

### Automated timing

| Step | Wait before next step |
|------|------------------------|
| NTP → infra MachineSets | Worker MCP **Updated** (wait Job) |
| Infra MachineSets → ingress/registry/monitoring | Infra nodes **Ready** (wait Job) |
| Ingress / registry / monitoring | None (same sync wave) |
| Workloads → etcd | None (etcd is last wave) |

Details: [`clusters/phased/day2-ordered/README.md`](clusters/phased/day2-ordered/README.md).

**Caveats:** delay Jobs use `registry.redhat.io/ubi9/ubi-minimal` (must be pullable). Hooks enforce **minimum** wait time—they do not wait for every node reboot or operator condition. Large clusters may need longer `sleep` values in the `delay-*.yaml` Jobs.

## Environment

- OpenShift: (fill in once chosen)
- Access: cluster-admin (recommended for most Day 2 tasks)
- CLI tools: `oc`, `kubectl` (optional), `jq` (optional)

## Repo map (topics)

Topic folders use **descriptive names** (no numeric prefixes). For a new cluster, start with **OpenShift GitOps operator**, then use GitOps for the rest.

| Folder | Summary |
|--------|---------|
| [`openshift-gitops-operator/`](openshift-gitops-operator/README.md) | Install the Red Hat OpenShift GitOps operator (OLM); do this **first** on a new cluster |
| [`infra-nodes-configuration/`](infra-nodes-configuration/README.md) | Create ≥ 2 infrastructure nodes (MachineSet); **first** infra step |
| [`ingress-on-infra/`](ingress-on-infra/README.md) | Move default ingress router to infra nodes |
| [`registry-on-infra/`](registry-on-infra/README.md) | Move integrated image registry to infra nodes |
| [`monitoring-on-infra/`](monitoring-on-infra/README.md) | Move cluster monitoring to infra nodes |
| [`ntp-chrony-configuration/`](ntp-chrony-configuration/README.md) | NTP (chrony) via MachineConfig |
| [`etcd-encryption/`](etcd-encryption/README.md) | Etcd encryption at rest |
| [`topic-template/`](topic-template/README.md) | Copy as a starting point for new topics |
| [`clusters/phased/`](clusters/phased/README.md) | Self-contained Kustomize bundles for GitOps (all Day 2 use cases) |
| [`gitops/`](gitops/README.md) | Argo CD `Application` and `AppProject` manifests |

Each topic folder should contain:

- `README.md` with prerequisites, a numbered procedure, and expected output
- Minimal YAML manifests (only when required), stored alongside the README (no `manifests/` subfolder)

## GitOps (single source of truth)

All cluster manifests consumed by Argo CD live under **`clusters/phased/`** (self-contained Kustomize bundles). Topic folders at the repo root are **runbooks** and authoring references—when you change YAML there, update the matching copy under `clusters/phased/<bundle>/`. Bootstrap and layout: [`gitops/README.md`](gitops/README.md), [`clusters/README.md`](clusters/README.md).

## Quick start

**New cluster:** follow **New cluster: fully automated GitOps rollout** above, then [`gitops/README.md`](gitops/README.md).

**Runbook (optional):** open any topic folder and follow its `README.md` for a guided walkthrough.

## Conventions

- All docs are in English.
- Prefer declarative resources (YAML) over manual imperative steps when possible.
- For GitOps, treat sensitive values with cluster-side patterns that are still declarative at the edge (for example Sealed Secrets, External Secrets Operator, or CSI driver volume mounts)—not checked-in shell that mutates the cluster.
- Include official documentation links for every operator/API/feature used: `https://docs.redhat.com` or `https://docs.openshift.com`.
