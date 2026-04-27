# Cluster layouts (GitOps)

These paths are **configuration as code** only (Kustomize + referenced YAML). Argo CD builds and applies them; you do not run shell scripts from this repo to roll out what they describe.

- **`clusters/all/<component>/`** — small Kustomize bundles that point at the topic YAML under `01-…` through `05-…`. Referenced by Argo CD `Application` objects in `gitops/applications/`.
- **`clusters/hub/`** — optional single Kustomize stack for one Argo CD Application covering several components.

See `gitops/README.md` for install and bootstrap steps.
