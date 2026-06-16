# Move monitoring to infrastructure nodes

Redeploy the **cluster monitoring stack** (Prometheus, Alertmanager, Thanos Querier, and related components) onto infrastructure nodes via the Cluster Monitoring Operator `cluster-monitoring-config` ConfigMap.

**Prerequisites:**

1. [`infra-nodes-configuration`](../infra-nodes-configuration/README.md) is complete.
2. [`ingress-on-infra`](../ingress-on-infra/README.md) is complete.
3. [`registry-on-infra`](../registry-on-infra/README.md) is complete.

## Prerequisites

- Cluster-admin access as `cluster-admin`
- Infrastructure nodes with infra label and taint
- At least **three** infra nodes are recommended for HA monitoring (anti-affinity); two is the minimum for this PoC sequence

## Procedure

### 1. Confirm monitoring ConfigMap (create if missing)

```bash
oc get configmap cluster-monitoring-config -n openshift-monitoring
```

If it does not exist, applying `cluster-monitoring-config.yaml` creates it.

### 2. Apply infra placement

```bash
oc apply -f ./cluster-monitoring-config.yaml
```

If you use GitOps, **`day2-ordered`** applies this at sync wave **5** with ingress and registry. Edit `clusters/phased/day2-ordered/manifests/cluster-monitoring-config.yaml`.

### 3. Watch pods reschedule

```bash
watch 'oc get pod -n openshift-monitoring -o wide'
```

If a component does not move, delete its pod so the operator recreates it on an infra node (per product doc).

### 4. Verify

Confirm monitoring pods run on nodes with **`node-role.kubernetes.io/infra`**.

## Expected output

- `ConfigMap/cluster-monitoring-config` in `openshift-monitoring` sets infra `nodeSelector` and tolerations for platform monitoring components
- Monitoring pods schedule on infra nodes

## References

- [Moving the monitoring solution](https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html/machine_management/creating-infrastructure-machinesets#infrastructure-moving-monitoring_creating-infrastructure-machinesets)
- [Moving resources to infrastructure machine sets](https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html/machine_management/creating-infrastructure-machinesets#moving-resources-to-infrastructure-machinesets)
