# Configure infrastructure nodes

Create **at least two** infrastructure nodes across **eu-west-1a** and **eu-west-1b** using the `MachineSet` manifests in this folder (cluster **`gitops-2c2d8`**). **Complete and validate this topic before** moving ingress, registry, or monitoring.

This PoC does **not** create a dedicated infra `MachineConfigPool`; infra nodes use the default worker machine config pool unless you add one separately.

## Prerequisites

- OpenShift **4.22** (or compatible) with **Machine API** operational (`oc get infrastructure cluster -o jsonpath='{.status.platform}'`)
- Cluster-admin access
- For AWS: installer-provisioned infrastructure (IPI) or validated UPI with Machine API
- Plan for **≥ 2 infra nodes** — `machineset-infra-aws-zone-a.yaml` and `machineset-infra-aws-zone-b.yaml` (1 replica each in `eu-west-1a` / `eu-west-1b`)

## Procedure

### 1. Review cluster and manifests

```bash
oc get -o jsonpath='{.status.infrastructureName}{"\n"}' infrastructure cluster
oc get machineset -n openshift-machine-api
oc get nodes -l node-role.kubernetes.io/infra
```

MachineSets target cluster **`gitops-2c2d8`**, instance type **`m6i.xlarge`**, AMI **`ami-0b8c325b7499597c6`**, private subnets per zone. Edit the YAML if your cluster IDs differ.

If you use GitOps, edit the same settings in **`clusters/phased/day2-ordered/manifests/`** (Argo CD applies those files via `day2-ordered`).

### 2. GitOps (default)

With **`day2-ordered`**, Argo CD applies infra MachineSets at sync wave **3**, after NTP and the worker MCP wait Job, then waits for infra nodes Ready before ingress/registry/monitoring. Edit `clusters/phased/day2-ordered/manifests/machineset-*.yaml`. See [`clusters/phased/day2-ordered/README.md`](../clusters/phased/day2-ordered/README.md).

Optional manual apply:

```bash
oc apply -f ./machineset-infra-aws-zone-a.yaml
oc apply -f ./machineset-infra-aws-zone-b.yaml
```

### 3. Wait for infra nodes

```bash
oc get machineset -n openshift-machine-api
oc get machine -n openshift-machine-api
oc get nodes -l node-role.kubernetes.io/infra
```

Expect **at least two** nodes with roles including **`infra`** (and typically **`worker`**).

### 4. Resolve misscheduled DNS pods (if tainted)

After the infra taint is applied, fix any misscheduled DNS pods per the product doc (delete pods or add tolerations).

### 5. Validate before the next topic

Do **not** enable ingress, registry, or monitoring placement until **≥ 2 infra nodes** are **Ready**.

## Expected output

- Two (or more) nodes labeled `node-role.kubernetes.io/infra`
- Infra nodes carry the `node-role.kubernetes.io/infra=reserved:NoSchedule` taint (must match tolerations on ingress, registry, and monitoring)

## References

- [Creating infrastructure machine sets (AWS sample)](https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html/machine_management/creating-infrastructure-machinesets#machineset-yaml-aws_creating-infrastructure-machinesets)
- [Moving resources to infrastructure machine sets (overview)](https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html/machine_management/creating-infrastructure-machinesets#moving-resources-to-infrastructure-machinesets)
