# Lbrightlab - Kubernetes GitOps Repository

Lbrightlab is a production-grade Kubernetes platform managed via GitOps (Flux CD). It bundles infrastructure provisioning, platform services, and observability into a single, automated repository.

All services are exposed under **`lbrightlab.com`** (e.g. `grafana.lbrightlab.com`, `keycloak.lbrightlab.com`) via Cloudflare DNS + Istio Gateway API. If you're forking this repo for your own domain, see [Configuring your own domain](#-configuring-your-own-domain) before you deploy.

## 🚀 Quick Start

### 0. Clone this repository

```bash
git clone https://github.com/lovertbright/brightlab.git
cd brightlab
```

### Interactive local deployment (recommended)

From the repo root, run:

```bash
task deploy:local
```

This guides you through: checking prerequisites → bringing up the Vagrant cluster → installing prerequisites → (optional) Cloudflare token → Flux → deploying apps. You can also use **step-by-step mode**:

```bash
task deploy:menu
```

---

### Manual steps

Follow this chronological order to deploy the platform from scratch.

### 1. Prerequisites
Ensure you have the following installed:
- **Vagrant** & **VirtualBox** (for local cluster)
- **Task** (Automation tool): `brew install go-task/tap/go-task`
- **Kubectl** & **Flux CLI**: `curl -s https://fluxcd.io/install.sh | sudo bash`
- A **Cloudflare account** with the `lbrightlab.com` zone added (needed for DNS + TLS — see below)

### 2. Infrastructure (Vagrant)
Provision the local Kubernetes cluster.
```bash
# Default: 1 Controller + 2 Workers
task vagrant:up

# Optional: Customize worker count
task vagrant:up WORKER_COUNT=3

# Scale nodes dynamically (Up or Down)
task scale COUNT=1
```

### 3. Cluster Bootstrap
Install essential cluster components (Gateway API, Storage, Cert-Manager) and set up secrets.
```bash
# 1. Install Prerequisites
task install:prerequisites

# 2. Cloudflare Token (needed for DNS-01 TLS certs + external-dns)
# Create a token at https://dash.cloudflare.com/profile/api-tokens with
# Zone:DNS:Edit and Zone:Zone:Read permissions, scoped to the lbrightlab.com zone.
export CLOUDFLARE_API_TOKEN=your_token
task certificates:configure-token
```

### 4. GitOps Deployment (Flux)
Deploy the platform and applications using Flux.
```bash
# 1. Install Flux controllers
task install:flux

# 2. Configure the GitRepository
task flux:configure-repo

# 3. Deploy Applications
task install:apps
```
flux will now automatically reconcile the state. You can check progress with:
```bash
task flux:status
# or
flux get all -n flux-system
```

### 5. Post-Installation
Configure sensitive resources that are not in Git.
- **Keycloak & Secrets**: See `infrastructure/terraform/keycloak-realm`.

---

## 🌐 Configuring your own domain

This repo ships pre-configured for `lbrightlab.com`. To point it at your own domain instead, update these locations before running `task deploy:local`:

| What | File | Setting |
| --- | --- | --- |
| Service hostnames | `platform/istio/httproutes.yaml`, `platform/*/gateway.yaml`, `platform/*/certificate.yaml` | Replace `*.lbrightlab.com` with `*.yourdomain.com` |
| External-DNS zone filter | `platform/networking/external-dns/helmrelease.yaml` | `domainFilters` and `txtOwnerId` |
| ACME (Let's Encrypt) contact email | `platform/cert-manager/cluster-issuer.yaml` | `spec.acme.email` |
| Keycloak realm defaults | `infrastructure/terraform/keycloak-realm/variable.tf` | `kc_url` default |
| Flux GitRepository source | `platform/flux/manifests/git-repository.yaml`, `Taskfile.yml` (`GIT_REPO_URL`) | Point at your fork's URL |

A quick way to find every occurrence: `grep -rl "lbrightlab" --exclude-dir=.git .`

You'll also need your domain's zone added to Cloudflare (for DNS-01 cert validation and External-DNS record management) before step 3 above.

---

## 🏗 Repository Structure

| Directory | Description |
| --------- | ----------- |
| `platform/` | **Core Platform**: Flux, Istio, Observability, Identity (Keycloak) |
| `platform/observability/` | **Consolidated Observability Stack**: Prometheus, Grafana, Alloy, Tempo (all in `observability` namespace). |
| `infrastructure/` | **IaC**: Terraform (Cloudflare) and Vagrant (local VMs) |
| `docs/` | **Documentation**: Runbooks and Tasks reference. |

## 🛠 Observability
All observability components are consolidated in the **`observability`** namespace:
- **Grafana Alloy**: OTLP collector (Metrics, Logs, Traces).
- **Prometheus**: Metrics storage.
- **Loki**: Log aggregation.
- **Tempo**: Distributed tracing.
- **Grafana**: Visualization.

Instrument your applications to send telemetry to Alloy:
```
OTEL_EXPORTER_OTLP_ENDPOINT=http://alloy-gateway.observability:4318
```

## 🔒 Security
- **Pod Security Standards**: Enforced (Restricted/Baseline).
- **Network Policies**: Default deny + allow-listing.
- **Secrets**: Managed via External Secrets Operator.
- **NeuVector**: Container and runtime security (CVE scanning, network segmentation). Deployed in the `neuvector` namespace. To access the manager UI: `kubectl port-forward -n neuvector svc/neuvector-manager-svc 8443:8443` then open https://localhost:8443 (default credentials in [NeuVector docs](https://open-docs.neuvector.com)).

## 📚 Documentation
- [Available Tasks](./docs/reference/TASKS.md)
- [Security Features](./docs/security/SECURITY_ENHANCEMENTS.md)
- [Gateway API with ClusterIP Setup](./docs/guides/GATEWAY_API_CLUSTERIP_SETUP.md)
