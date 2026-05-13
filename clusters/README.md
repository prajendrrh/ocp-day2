# Cluster layouts (GitOps)

These paths are **configuration as code** only (Kustomize + referenced YAML). Argo CD builds and applies them; you do not run shell scripts from this repo to roll out what they describe.

- **`clusters/all/<component>/`** — small Kustomize bundles that point at YAML in the **topic folders** at the repository root (for example `infra-nodes-and-monitoring-placement/`, `openshift-gitops-operator/`). Referenced by Argo CD `Application` objects in `gitops/applications/` where applicable.
- **`clusters/hub/`** — optional single Argo CD `Application` path; defaults to **NTP + etcd** only (aligned with phased testing). Does **not** include the GitOps operator—apply `clusters/all/openshift-gitops-operator` **before** Argo CD exists on a new cluster.

On a **new** cluster, apply **`clusters/all/openshift-gitops-operator`** first (see `openshift-gitops-operator/README.md`), then bootstrap Argo CD from `gitops/`.

See `gitops/README.md` for install and bootstrap steps.
