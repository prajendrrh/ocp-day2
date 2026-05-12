# 07 — Install Red Hat OpenShift GitOps operator

This topic installs the **Red Hat OpenShift GitOps** operator (OLM) so the default Argo CD instance is created in `openshift-gitops`. Do this **before** you rely on in-cluster Argo CD to sync this repository’s `gitops/` Applications.

## Prerequisites

- OpenShift cluster access as `cluster-admin`
- Default **OperatorHub** catalog (`redhat-operators` in `openshift-marketplace`) available
- For air-gapped or custom catalogs, replace `spec.source` / `spec.sourceNamespace` in `subscription.yaml` to match your environment

## Procedure

### 1. Apply Namespace, OperatorGroup, and Subscription

From the repository root, apply the Kustomize bundle (order is defined in `clusters/all/openshift-gitops-operator/kustomization.yaml`):

```bash
oc apply -k ./clusters/all/openshift-gitops-operator
```

Alternatively, apply the three manifests in this folder in order: `namespace.yaml`, `operatorgroup.yaml`, `subscription.yaml`.

### 2. Wait for the operator and default Argo CD

```bash
oc get csv -n openshift-gitops-operator -w
oc get pods -n openshift-gitops-operator
oc get pods -n openshift-gitops
```

When the ClusterServiceVersion for OpenShift GitOps reaches **Succeeded**, the operator creates the default `ArgoCD` instance and workloads in `openshift-gitops`.

### 3. Continue GitOps bootstrap

Follow [`gitops/README.md`](../gitops/README.md): register your Git repository if needed, create the root `Application`, and sync.

## Why this is not in the app-of-apps by default

On a **brand-new** cluster, Argo CD does not exist until this operator is installed. The root `Application` in `gitops/argocd/` cannot sync the operator subscription onto the same cluster before that. Install the operator using this topic (or the console equivalent) first; after that, Argo CD can own the rest of Day 2 from Git.

## Expected output

- `Subscription` `openshift-gitops-operator` in `openshift-gitops-operator` with a resolved CSV
- Pods **Running** in `openshift-gitops-operator` and `openshift-gitops`
- Argo CD available from the console toolbar and/or the `openshift-gitops-server` route

## References

- [Installing Red Hat OpenShift GitOps](https://docs.redhat.com/en/documentation/red_hat_openshift_gitops/1.20/html/installing_gitops/installing-openshift-gitops)
- [Red Hat OpenShift GitOps — product documentation](https://docs.redhat.com/en/documentation/red_hat_openshift_gitops/)
