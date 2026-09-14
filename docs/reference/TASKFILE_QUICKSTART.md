# Brightlab Taskfile Quick Start Guide

This guide helps you get started with the Taskfile automation for your Kubernetes GitOps repository.

## Prerequisites

1. **Install Task**: [Download from official site](https://taskfile.dev/installation/)

   ```bash
   # macOS
   brew install go-task/tap/go-task

   # Or download binary directly
   sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b ~/.local/bin
   ```

2. **Required Tools**:
   - `kubectl` - Kubernetes CLI
   - `flux` - Flux CLI (optional — installed automatically by `task install:flux` if missing)
   - `terraform` - For Keycloak configuration
   - `vagrant` - For local cluster provisioning
   - `yamllint` - For YAML validation
   - `prettier` - For code formatting

## Quick Commands

### Getting Started

```bash
# Show all available tasks
task

# Install the complete stack
task install

# Check cluster and application status
task status

# Validate cluster connectivity
task validate:cluster
```

### Flux Operations

```bash
# Show Flux status
task flux:status

# Show detailed status (sources, Kustomizations, HelmReleases across namespaces)
task flux:status-all

# Force reconcile all Flux resources
task flux:sync-all

# Re-apply the GitRepository pointing Flux at this repo
task flux:configure-repo
```

### Development & Maintenance

```bash
# Lint all YAML files
task lint

# Format code
task format

# Comprehensive health check
task health

# Check certificate status
task certificates:status

# Check Gateway API resources
task gateway:status

# Test DNS resolution
task dns:check

# Collect troubleshooting info
task troubleshoot
```

### Validation & Testing

```bash
# Validate all Kubernetes manifests (syntax validation only)
task validate:manifests

# Validate manifests against running cluster
task validate:manifests:cluster

# Validate cluster connectivity and prerequisites
task validate:cluster

# Run comprehensive security scan
task security:scan

# Validate security configurations
task security:validate
```

### Security & Compliance

```bash
# Run comprehensive security scan
task security:scan

# Validate security configurations
task security:validate

# Check external secrets status
task secrets:status

# Enhanced health check (includes security status)
task health
```

### Local Development (Vagrant)

```bash
# Start local Kubernetes cluster
task vagrant:up

# Check cluster status
task vagrant:status

# SSH into control plane
task vagrant:ssh

# Stop cluster
task vagrant:halt
```

### Keycloak Configuration

```bash
# Complete Keycloak setup
task terraform:keycloak:setup

# Apply Terraform changes only
task terraform:apply

# Create OAuth secrets
task terraform:secrets:create
```

## Common Workflows

### 1. Fresh Installation

```bash
# Validate cluster access
task validate:cluster

# Install everything
task install

# Check status
task status

# Configure Keycloak (after pods are running)
task terraform:keycloak:setup
```

### 2. Development Workflow

```bash
# Make changes to manifests
# Validate changes
task validate:manifests

# Format code
task format

# Lint YAML
task lint

# Push changes and let Flux pick them up (or force it immediately)
task gitops:push
task flux:sync-all
```

### 3. Troubleshooting

```bash
# Health check (includes certificate and gateway status)
task health

# Check certificate issues
task certificates:status
task certificates:describe

# Check Gateway API resources
task gateway:status

# Test DNS resolution
task dns:check

# View specific component logs
task logs -- keycloak
task logs -- alloy

# Collect debug info
task troubleshoot

# Show service URLs
task access

# Security troubleshooting
task security:scan
task security:validate

# Check Alloy status
kubectl get pods -n observability
kubectl get pods -n observability -l app.kubernetes.io/name=tempo
```

### 4. Certificate and DNS Management

```bash
# After deployment, check certificate status
task certificates:status

# If certificates are not ready, check issues
task certificates:describe

# Verify DNS resolution
task dns:check

# Check Gateway API resources
task gateway:status

# Show service access URLs
task access
```

### 5. Local Testing with Vagrant

```bash
# Start local cluster
task vagrant:up

# Wait for cluster to be ready
task vagrant:wait-ready

# Copy kubeconfig
task vagrant:kubeconfig
export KUBECONFIG=~/.kube/config-vagrant

# Install stack on local cluster
task install
```

## Service Access URLs

Access services via your `lbrightlab.com` domain:

```bash
# Show all service URLs and their status
task access

# Direct URLs (once deployed and certificates are ready):
# Grafana:    https://grafana.lbrightlab.com
# Keycloak:   https://keycloak.lbrightlab.com
# Prometheus: https://prometheus.lbrightlab.com
# MinIO:      https://minio.lbrightlab.com
```

### OpenTelemetry Quick Start

```bash
# Point your workloads to Alloy's OTLP gateway
export OTEL_EXPORTER_OTLP_ENDPOINT=http://alloy-gateway.observability:4318

# For gRPC exporters
export OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=grpc://alloy-gateway.observability:4317

# Tempo endpoints (direct access, if required)
export TEMPO_OTLP_GRPC_ENDPOINT=tempo-tempo-distributor.observability.svc.cluster.local:4317
export TEMPO_OTLP_HTTP_ENDPOINT=http://tempo-tempo-distributor.observability.svc.cluster.local:4318
```

## Cleanup Operations

```bash
# Clean temporary files
task clean

# Uninstall everything
task uninstall

# Complete reset (uninstall + clean + reinstall)
task reset
```

## Advanced Features

### Backup & Restore

```bash
# Backup cluster state
task backup

# Backup Vagrant cluster
task vagrant:backup
```

### Component-Specific Operations

```bash
# Terraform operations
task terraform:plan
task terraform:apply
task terraform:destroy

# Vagrant operations
task vagrant:logs
task vagrant:debug
task vagrant:restart
```

## Tips & Best Practices

1. **Always validate before applying**:

   ```bash
   task validate:manifests
   task lint
   ```

2. **Monitor installations**:

   ```bash
   # In one terminal
   task install

   # In another terminal
   watch -n 2 "task status"
   ```

3. **Use health checks regularly**:

   ```bash
   task health
   ```

4. **Keep documentation updated**:
   ```bash
   task docs  # Updates TASKS.md with current task list
   ```

## Environment Variables

Taskfile variables (defined in the `vars:` block at the top of `Taskfile.yml`) are overridden as CLI arguments, not shell `export`s:

```bash
# Change the Flux namespace
task install:flux FLUX_NAMESPACE=custom-flux-system

# Extend the kubectl wait timeout
task install:flux KUBECTL_TIMEOUT=600s
```

Actual shell environment variables — like `CLOUDFLARE_API_TOKEN` used in [Cluster Bootstrap](../../README.md#4-cluster-bootstrap) — are still set the normal way with `export`.

## Getting Help

- Run `task` to see all available commands
- Run `task <namespace>` to see commands for specific components:
  - `task terraform` - Terraform/Keycloak tasks
  - `task vagrant` - Vagrant/local cluster tasks
- Each task includes a description of what it does
- Use `task --list-all` to see all tasks including subtasks

For more details, see the main [README.md](../../README.md) and individual component documentation.
