# Phased GitOps bundles (Argo CD)

Everything under `clusters/phased/` is a **self-contained** Kustomize root. Manifests stay inside each directory so Argo CD does not need `buildOptions: --load-restrictor LoadRestrictionsNone`.

Delay hook Jobs run in `openshift-gitops` and use `registry.redhat.io/ubi9/ubi-minimal` (cluster must pull from `registry.redhat.io`).

## Bundles

| Path | How it is applied |
|------|-------------------|
| `argocd-day2-rbac/` | Bootstrap script + Argo CD `day2-argocd-rbac` (wave **-1**, before other apps) |
| `openshift-gitops-operator/` | **Before** Argo CD: `oc apply -k` or bootstrap script. Not in app-of-apps. |
| `ntp-then-etcd/` | Argo CD `day2-ntp-and-etcd` |
| `infra-nodes/` | Argo CD `day2-infra-nodes` |
| `ingress-on-infra/` | Argo CD `day2-ingress-on-infra` |
| `registry-on-infra/` | Argo CD `day2-registry-on-infra` |
| `monitoring-on-infra/` | Argo CD `day2-monitoring-on-infra` |

Keep phased copies in sync with topic folders at the repo root when you edit manifests.

## Application order (`day2-root` child apps)

| App sync wave | Application | What runs |
|---------------|-------------|-----------|
| -1 | `day2-argocd-rbac` | RBAC for application controller (registry, ingress, etc.) |
| 5 | `day2-ntp-and-etcd` | NTP → **20 min** → etcd encryption |
| 30 | `day2-infra-nodes` | Infra MachineSets → **20 min** |
| 40 | `day2-ingress-on-infra` | Ingress on infra → **10 min** |
| 50 | `day2-registry-on-infra` | Registry on infra → **10 min** |
| 60 | `day2-monitoring-on-infra` | Monitoring on infra |

## In-application timing

| Bundle | Wave 5 | Wave 10 | Wave 20 |
|--------|--------|---------|---------|
| `ntp-then-etcd` | MachineConfig (NTP) | Job sleeps **1200s** (20 min) | APIServer etcd encryption |
| `infra-nodes` | 2× MachineSet | Job sleeps **1200s** (20 min) | — |
| `ingress-on-infra` | IngressController | Job sleeps **600s** (10 min) | — |
| `registry-on-infra` | Image registry Config | Job sleeps **600s** (10 min) | — |
| `monitoring-on-infra` | cluster-monitoring-config | — | — |

### Why delay NTP → etcd?

The NTP `MachineConfig` triggers a **worker MCP rolling update** (reboots). Etcd encryption is high-impact. The **20-minute** hook gives nodes time to start rolling out chrony before the `APIServer` encryption change is applied. Increase `sleep` in `ntp-then-etcd/delay-after-ntp.yaml` if your worker pool is large.

### Why delay infra → ingress?

MachineSets must **provision** infra nodes and register them Ready. The **20-minute** hook after MachineSets runs before moving the router.

### Tuning delays

Edit the `sleep` value in the relevant `delay-*.yaml` Job under each phased folder, commit, and let Argo CD reconcile.

**Note:** Hooks enforce **minimum wait time**, not full health (for example MCP `UPDATED` or all infra nodes Ready). Watch cluster state in Argo CD and with `oc` during long rollouts.
