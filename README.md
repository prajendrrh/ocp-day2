# PoC — OCP Day 2 Operations

This repository is a structured proof of concept (PoC) for **OpenShift Day 2 operations**.

- **GitOps path (recommended for SSOT):** cluster configuration is **configuration as code** only—Kubernetes/OpenShift manifests and Kustomize under `clusters/` and `gitops/`, reconciled by OpenShift GitOps. There are **no shell scripts** in this repo for delivering Day 2 settings; you change Git and let Argo CD sync.
- **Topic runbooks:** optional narrative folders (sometimes with `oc` examples for learning, troubleshooting, or one-off tasks). They are not required when you manage the cluster through GitOps.

## New cluster: phased validation (GitOps first, then one topic at a time)

The repo defaults to a **small, testable slice**: install GitOps, prove **NTP (chrony)**, then **etcd encryption**, before turning on other Argo CD `Application` objects.

1. **Install OpenShift GitOps** — apply [`openshift-gitops-operator`](openshift-gitops-operator/README.md) (or `oc apply -k ./clusters/all/openshift-gitops-operator` from the repo root). Argo CD does not exist until the operator finishes installing.
2. **Bootstrap Argo CD** — register Git access if needed, apply the root `Application`, sync **`day2-root`**. That creates only **NTP** and **etcd encryption** child apps (plus `day2-ops`). See [`gitops/README.md`](gitops/README.md).
3. **Validate NTP** — confirm **day2-ntp-chrony** is healthy (MachineConfig rolled out, chrony as expected). Fix Git or cluster issues before continuing.
4. **Validate etcd encryption** — in Argo CD, **Sync** **day2-etcd-encryption** manually when ready (maintenance window, backups). Confirm encryption completes per [`etcd-encryption/README.md`](etcd-encryption/README.md).
5. **Add more topics** — when this path is solid, uncomment or add one `Application` line at a time in [`gitops/bootstrap/kustomization.yaml`](gitops/bootstrap/kustomization.yaml), commit, sync, and validate before adding the next.

## Environment

- OpenShift: (fill in once chosen)
- Access: cluster-admin (recommended for most Day 2 tasks)
- CLI tools: `oc`, `kubectl` (optional), `jq` (optional)

## Repo map (topics)

Topic folders use **descriptive names** (no numeric prefixes). For a new cluster, start with **OpenShift GitOps operator**, then use GitOps for the rest.

| Folder | Summary |
|--------|---------|
| [`openshift-gitops-operator/`](openshift-gitops-operator/README.md) | Install the Red Hat OpenShift GitOps operator (OLM); do this **first** on a new cluster |
| [`infra-nodes-and-monitoring-placement/`](infra-nodes-and-monitoring-placement/README.md) | Label infra nodes; move platform monitoring onto infra |
| [`ldap-authentication/`](ldap-authentication/README.md) | LDAP identity provider (OAuth) |
| [`logging-and-monitoring-setup/`](logging-and-monitoring-setup/README.md) | Logging and monitoring setup (OpenShift 4.21 docs) |
| [`log-forwarding-to-siem/`](log-forwarding-to-siem/README.md) | Forward logs to a SIEM (syslog) |
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
