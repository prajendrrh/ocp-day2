# PoC — OCP Day 2 Operations

This repository is a structured proof of concept (PoC) for **OpenShift Day 2 operations**.

- **GitOps path (recommended for SSOT):** cluster configuration is **configuration as code** only—Kubernetes/OpenShift manifests and Kustomize under `clusters/` and `gitops/`, reconciled by OpenShift GitOps. There are **no shell scripts** in this repo for delivering Day 2 settings; you change Git and let Argo CD sync.
- **Topic runbooks (`01-` … `06-`):** optional narrative procedures, sometimes with `oc` examples for learning, troubleshooting, or one-off tasks. They are not required when you manage the cluster through GitOps.

## Environment

- OpenShift: (fill in once chosen)
- Access: cluster-admin (recommended for most Day 2 tasks)
- CLI tools: `oc`, `kubectl` (optional), `jq` (optional)

## Repo map (topics)

Each topic is a numbered folder:

- `01-ldap-authentication/`: Add OpenShift authentication via LDAP
- `02-infra-nodes-and-monitoring-placement/`: Label infra nodes and move platform monitoring workloads
- `03-ntp-chrony-configuration/`: Configure NTP servers (chrony) via MachineConfig
- `04-log-forwarding-to-siem/`: Forward logs to a local SIEM system
- `05-etcd-encryption/`: Enable etcd encryption at rest
- `06-logging-and-monitoring-setup/`: Logging and monitoring setup (OpenShift 4.21 docs)
- `clusters/`: Kustomize paths consumed by OpenShift GitOps (see `clusters/README.md`)
- `gitops/`: Argo CD `Application` and `AppProject` manifests (see `gitops/README.md`)

Each folder must contain:

- `README.md` with prerequisites, numbered procedure, and expected output
- Minimal YAML manifests (only when required), stored alongside the README (no `manifests/` subfolder)

## GitOps (single source of truth)

To manage the same manifests with **OpenShift GitOps** (Argo CD), use the Kustomize paths under `clusters/` and the bootstrap manifests under `gitops/`. The numbered topic folders stay the authoring location for YAML; `clusters/all/<component>/` references them so you do not maintain two copies. After the platform has GitOps installed and the root `Application` exists, **day-to-day Day 2 changes are commits to this repository**, not ad hoc shell.

- Bootstrap and layout: [`gitops/README.md`](gitops/README.md)
- Cluster entrypoints: [`clusters/README.md`](clusters/README.md)

## Quick start

**GitOps:** install OpenShift GitOps, wire Git credentials if needed, apply the root `Application` manifest once, then use the Argo CD UI or CLI to sync—details in [`gitops/README.md`](gitops/README.md).

**Runbook (optional):** pick a numbered topic folder and follow its `README.md` for a guided walkthrough.

## Conventions

- All docs are in English.
- Prefer declarative resources (YAML) over manual imperative steps when possible.
- For GitOps, treat sensitive values with cluster-side patterns that are still declarative at the edge (for example Sealed Secrets, External Secrets Operator, or CSI driver volume mounts)—not checked-in shell that mutates the cluster.
- Include official documentation links for every operator/API/feature used: `https://docs.redhat.com` or `https://docs.openshift.com`.

