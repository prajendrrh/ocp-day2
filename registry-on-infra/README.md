# Move image registry to infrastructure nodes

Configure the **integrated OpenShift image registry** to run on infrastructure nodes.

**Prerequisites:**

1. [`infra-nodes-configuration`](../infra-nodes-configuration/README.md) is complete.
2. [`ingress-on-infra`](../ingress-on-infra/README.md) is complete and the default router is healthy on infra nodes.

## Prerequisites

- Cluster-admin access
- Infrastructure nodes with infra label and taint

## Procedure

### 1. Review current registry placement

```bash
oc get configs.imageregistry.operator.openshift.io/cluster -o yaml
oc get pods -o wide -n openshift-image-registry
```

### 2. Apply node selector and tolerations

```bash
oc apply -f ./imageregistry-cluster.yaml
```

If you use GitOps, sync **`day2-registry-on-infra`** only after ingress on infra is validated.

### 3. Verify

```bash
oc get pods -o wide -n openshift-image-registry
oc describe node <registry-node> | grep node-role.kubernetes.io/infra
```

## Expected output

- Registry pods run on nodes with the **infra** label
- `Config/cluster` (`imageregistry.operator.openshift.io`) includes infra `nodeSelector` and matching tolerations

## References

- [Moving the default registry](https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html/machine_management/creating-infrastructure-machinesets#infrastructure-moving-registry_creating-infrastructure-machinesets)
- [Moving resources to infrastructure machine sets](https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html/machine_management/creating-infrastructure-machinesets#moving-resources-to-infrastructure-machinesets)
