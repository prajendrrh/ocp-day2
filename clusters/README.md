# Cluster layouts (GitOps)

These paths are **configuration as code** only (Kustomize + referenced YAML). Argo CD builds and applies them; you do not run shell scripts from this repo to roll out what they describe.

- **`clusters/all/<component>/`** — small Kustomize bundles that point at topic YAML under the numbered folders (for example `02-…` through `07-…`). Referenced by Argo CD `Application` objects in `gitops/applications/` where applicable. The **OpenShift GitOps operator** bundle is applied **before** Argo CD exists on a new cluster (see `07-openshift-gitops-operator/README.md`).
- **`clusters/hub/`** — optional single Kustomize stack for one Argo CD Application covering several components.

See `gitops/README.md` for install and bootstrap steps.
