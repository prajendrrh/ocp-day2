# Configure infrastructure nodes

Create **at least two** infrastructure nodes (recommended across two availability zones) using infrastructure `MachineSet`s with the **infra** node label and taint from the OpenShift 4.22 docs. **Complete and validate this topic before** moving ingress, registry, or monitoring.

This PoC does **not** create a dedicated infra `MachineConfigPool`; infra nodes use the default worker machine config pool unless you add one separately.

## Prerequisites

- OpenShift **4.22** (or compatible) with **Machine API** operational (`oc get infrastructure cluster -o jsonpath='{.status.platform}'`)
- Cluster-admin access
- For AWS: installer-provisioned infrastructure (IPI) or validated UPI with Machine API
- Plan for **≥ 2 infra nodes** (this repo ships two AWS `MachineSet` templates, one per zone)

## Procedure

### 1. Gather cluster values

```bash
oc get -o jsonpath='{.status.infrastructureName}{"\n"}' infrastructure cluster
oc get machineset -n openshift-machine-api
oc get nodes -l node-role.kubernetes.io/infra
```

Copy an existing **worker** `MachineSet` in your cluster and use it as the source of truth for `providerSpec` (AMI, subnets, security groups, instance type).

### 2. Customize the MachineSet manifests

Edit **`machineset-infra-aws-zone-a.yaml`** and **`machineset-infra-aws-zone-b.yaml`**:

- Replace every `REPLACE_*` token (infrastructure ID, region, zones, AMI, and so on).
- Use **different** availability zones for zone A and zone B.
- For other clouds, follow the platform section in [Creating infrastructure machine sets](https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html/machine_management/creating-infrastructure-machinesets#machineset-yaml-aws_creating-infrastructure-machinesets) and add your own YAML alongside these AWS examples.

If you use GitOps, apply the same edits under **`clusters/phased/infra-nodes/`** (copies used by Argo CD).

### 3. Apply MachineSets (or sync via GitOps)

```bash
oc apply -f ./machineset-infra-aws-zone-a.yaml
oc apply -f ./machineset-infra-aws-zone-b.yaml
```

Or enable **`day2-infra-nodes`** in `gitops/bootstrap/kustomization.yaml` and let Argo CD sync `clusters/phased/infra-nodes/`.

### 4. Wait for infra nodes

```bash
oc get machineset -n openshift-machine-api
oc get machine -n openshift-machine-api
oc get nodes -l node-role.kubernetes.io/infra
```

Expect **at least two** nodes with roles including **`infra`** (and typically **`worker`**).

### 5. Resolve misscheduled DNS pods (if tainted)

After the infra taint is applied, fix any misscheduled DNS pods per the product doc (delete pods or add tolerations).

### 6. Validate before the next topic

Do **not** enable ingress, registry, or monitoring placement until **≥ 2 infra nodes** are **Ready**.

## Expected output

- Two (or more) nodes labeled `node-role.kubernetes.io/infra`
- Infra nodes carry the `node-role.kubernetes.io/infra` **NoSchedule** taint

## References

- [Creating infrastructure machine sets (AWS sample)](https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html/machine_management/creating-infrastructure-machinesets#machineset-yaml-aws_creating-infrastructure-machinesets)
- [Moving resources to infrastructure machine sets (overview)](https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html/machine_management/creating-infrastructure-machinesets#moving-resources-to-infrastructure-machinesets)
