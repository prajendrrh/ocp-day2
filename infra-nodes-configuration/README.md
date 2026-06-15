# Configure infrastructure nodes

Create **at least two** infrastructure nodes (recommended across two availability zones), an **infra** `MachineConfigPool`, and the **infra** node label + taint pattern from the OpenShift 4.22 docs. **Complete and validate this topic before** moving ingress, registry, or monitoring.

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
oc get nodes -L node-role.kubernetes.io/infra
```

Copy an existing **worker** `MachineSet` in your cluster and use it as the source of truth for `providerSpec` (AMI, subnets, security groups, instance type).

### 2. Customize the MachineSet manifests

Edit **`machineset-infra-aws-zone-a.yaml`** and **`machineset-infra-aws-zone-b.yaml`**:

- Replace every `REPLACE_*` token (infrastructure ID, region, zones, AMI, and so on).
- Use **different** availability zones for zone A and zone B.
- For other clouds, follow the platform section in [Creating infrastructure machine sets](https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html/machine_management/creating-infrastructure-machinesets#machineset-yaml-aws_creating-infrastructure-machinesets) and add your own YAML alongside these AWS examples.

If you use GitOps, apply the same edits under **`clusters/phased/infra-nodes/`** (copies used by Argo CD).

### 3. Apply MachineSets and MachineConfigPool

```bash
oc apply -f ./machineconfigpool-infra.yaml
oc apply -f ./machineset-infra-aws-zone-a.yaml
oc apply -f ./machineset-infra-aws-zone-b.yaml
```

### 4. Wait for infra nodes and MCP

```bash
oc get machineset -n openshift-machine-api
oc get machine -n openshift-machine-api
oc get nodes -L node-role.kubernetes.io/infra
oc get mcp infra
```

Expect **at least two** nodes with roles including **`infra`** (and typically **`worker`**). Wait until `mcp/infra` reports **UPDATED=True**.

### 5. Resolve misscheduled DNS pods (if tainted)

After the infra taint is applied, fix any misscheduled DNS pods per the product doc (delete pods or add tolerations).

### 6. Validate before the next topic

Do **not** enable ingress, registry, or monitoring placement until:

- ≥ 2 infra nodes are **Ready**
- `mcp/infra` is healthy
- You can schedule a test pod with the infra toleration (optional)

## Expected output

- Two (or more) nodes labeled `node-role.kubernetes.io/infra`
- `MachineConfigPool/infra` exists and is updated
- Infra nodes carry the `node-role.kubernetes.io/infra` **NoSchedule** taint

## References

- [Creating infrastructure machine sets (AWS sample)](https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html/machine_management/creating-infrastructure-machinesets#machineset-yaml-aws_creating-infrastructure-machinesets)
- [Creating a machine config pool for infrastructure machines](https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html/machine_management/creating-infrastructure-machinesets#creating-a-machine-config-pool-for-infrastructure-machines_creating-infrastructure-machinesets)
- [Moving resources to infrastructure machine sets (overview)](https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html/machine_management/creating-infrastructure-machinesets#moving-resources-to-infrastructure-machinesets)
