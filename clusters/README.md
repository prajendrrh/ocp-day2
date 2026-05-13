# Cluster layouts (GitOps)

These paths are **configuration as code** only (Kustomize + referenced YAML). Argo CD builds and applies them; you do not run shell scripts from this repo to roll out what they describe.

- **`clusters/all/<component>/`** — small Kustomize bundles that point at YAML in the **topic folders** at the repository root (for example `infra-nodes-and-monitoring-placement/`, `openshift-gitops-operator/`). Referenced by Argo CD `Application` objects declared in `gitops/bootstrap/` where applicable.
- **`clusters/phased/`** — ordered bundles (e.g. **NTP then etcd** via sync waves) for a single Argo CD sync; used by **`day2-ntp-and-etcd`**.
- **`clusters/hub/`** — optional single Argo CD `Application` path; reuses `clusters/phased/ntp-then-etcd` for the same ordering. Does **not** include the GitOps operator—apply `clusters/all/openshift-gitops-operator` **before** Argo CD exists on a new cluster.

On a **new** cluster, apply **`clusters/all/openshift-gitops-operator`** first (see `openshift-gitops-operator/README.md` or run [`scripts/bootstrap-fresh-cluster.sh`](../scripts/bootstrap-fresh-cluster.sh)), then bootstrap Argo CD from `gitops/`.

See `gitops/README.md` for install and bootstrap steps.
