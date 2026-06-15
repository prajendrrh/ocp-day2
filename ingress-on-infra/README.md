# Move ingress routers to infrastructure nodes

Move the **default** `IngressController` router pods to nodes labeled `node-role.kubernetes.io/infra`.

**Prerequisite:** [`infra-nodes-configuration`](../infra-nodes-configuration/README.md) is complete (≥ 2 infra nodes ready).

## Prerequisites

- Cluster-admin access
- Infrastructure nodes exist with the infra label and taint (from the infra nodes topic)

## Procedure

### 1. Review current router placement

```bash
oc get ingresscontroller default -n openshift-ingress-operator -o yaml
oc get pod -n openshift-ingress -o wide
```

### 2. Apply node placement

```bash
oc apply -f ./ingresscontroller-default.yaml
```

If you use GitOps, sync **`day2-ingress-on-infra`** only after infra nodes are validated.

### 3. Verify

```bash
oc get pod -n openshift-ingress -o wide
oc get node <router-node> --show-labels
```

The running router pod should be on a node with **`node-role.kubernetes.io/infra`**.

## Expected output

- `IngressController/default` has `spec.nodePlacement` targeting infra nodes
- Router pods run on infra nodes

## References

- [Moving the router](https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html/machine_management/creating-infrastructure-machinesets#infrastructure-moving-router_creating-infrastructure-machinesets)
- [Moving resources to infrastructure machine sets](https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html/machine_management/creating-infrastructure-machinesets#moving-resources-to-infrastructure-machinesets)
