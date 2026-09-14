# Incident Response Runbook

## 🚨 Emergency Contacts & Escalation

### Primary Contacts

- **On-Call Engineer**: [Your Name] - [Phone/Email]
- **Team Lead**: [Name] - [Phone/Email]
- **DevOps Manager**: [Name] - [Phone/Email]

### Escalation Matrix

| Severity          | Response Time | Escalation                          |
| ----------------- | ------------- | ----------------------------------- |
| **P1 - Critical** | 15 minutes    | Immediate escalation to Team Lead   |
| **P2 - High**     | 1 hour        | Escalate if not resolved in 2 hours |
| **P3 - Medium**   | 4 hours       | Escalate if not resolved in 8 hours |
| **P4 - Low**      | 24 hours      | Next business day                   |

## 🔍 Quick Assessment Commands

### 1. Cluster Health Check

```bash
# Quick cluster status
task health

# Detailed cluster info
kubectl cluster-info --request-timeout=10s

# Node status
kubectl get nodes -o wide

# Resource usage
kubectl top nodes
```

### 2. Application Status

```bash
# All application status
task status

# Flux Kustomizations and HelmReleases
kubectl get kustomizations,helmreleases -n flux-system

# Pod status across all namespaces
kubectl get pods --all-namespaces --field-selector=status.phase!=Running,status.phase!=Succeeded
```

### 3. Security Status

```bash
# Security scan
task security:scan

# Network policies
kubectl get networkpolicies -A

# RBAC status
kubectl get roles,clusterroles,rolebindings,clusterrolebindings -A
```

## 🚨 Severity Level Definitions

### P1 - Critical (Service Down)

- **Symptoms**: Complete service outage, data loss, security breach
- **Examples**:
  - All pods in namespace are down
  - Database corruption
  - Security incident detected
  - Complete cluster failure

### P2 - High (Major Impact)

- **Symptoms**: Significant service degradation, partial outage
- **Examples**:
  - Multiple pods failing
  - Certificate expiration
  - High error rates
  - Performance degradation >50%

### P3 - Medium (Minor Impact)

- **Symptoms**: Limited service impact, workarounds available
- **Examples**:
  - Single pod failures
  - Minor configuration issues
  - Non-critical alerts
  - Performance degradation <50%

### P4 - Low (Minimal Impact)

- **Symptoms**: Cosmetic issues, no service impact
- **Examples**:
  - UI glitches
  - Non-critical warnings
  - Documentation updates
  - Minor feature requests

## 🔧 Common Incident Scenarios

### Scenario 1: Pod CrashLoopBackOff

#### Symptoms

- Pods continuously restarting
- `kubectl get pods` shows `CrashLoopBackOff` status

#### Immediate Actions

```bash
# 1. Identify failing pods
kubectl get pods --all-namespaces --field-selector=status.phase!=Running

# 2. Check pod logs
kubectl logs <pod-name> -n <namespace> --previous

# 3. Describe pod for events
kubectl describe pod <pod-name> -n <namespace>

# 4. Check resource limits
kubectl top pod <pod-name> -n <namespace>
```

#### Resolution Steps

1. **Check logs** for error messages
2. **Verify resource limits** - increase if needed
3. **Check configuration** - validate ConfigMaps/Secrets
4. **Restart deployment** if configuration issue
5. **Rollback** to previous version if needed

#### Commands

```bash
# Restart deployment
kubectl rollout restart deployment/<deployment-name> -n <namespace>

# Rollback deployment
kubectl rollout undo deployment/<deployment-name> -n <namespace>

# Scale down and up
kubectl scale deployment/<deployment-name> --replicas=0 -n <namespace>
kubectl scale deployment/<deployment-name> --replicas=1 -n <namespace>
```

### Scenario 2: Certificate Issues

#### Symptoms

- TLS certificate errors
- Certificate expiration warnings
- HTTPS connection failures

#### Immediate Actions

```bash
# 1. Check certificate status
task certificates:status

# 2. Describe certificate issues
task certificates:describe

# 3. Check certificate requests
kubectl get certificaterequests -A

# 4. Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager
```

#### Resolution Steps

1. **Verify DNS** - ensure domain points to cluster
2. **Check cert-manager** - ensure it's running
3. **Validate certificate issuer** - check Let's Encrypt status
4. **Renew certificate** manually if needed
5. **Check rate limits** - Let's Encrypt has limits

#### Commands

```bash
# Force certificate renewal
kubectl delete certificate <cert-name> -n <namespace>

# Check cert-manager status
kubectl get pods -n cert-manager

# Check certificate issuer
kubectl get clusterissuers
```

### Scenario 3: Flux Reconciliation Issues

#### Symptoms

- Kustomizations/HelmReleases stuck "Not Ready" or "Unknown"
- `task flux:status` shows stale reconciliations
- GitOps not applying changes pushed to the repo

#### Immediate Actions

```bash
# 1. Check Flux Kustomizations and HelmReleases
task flux:status-all

# 2. Check Flux controller logs
kubectl logs -n flux-system -l app=source-controller
kubectl logs -n flux-system -l app=kustomize-controller
kubectl logs -n flux-system -l app=helm-controller

# 3. Force reconciliation of everything
task flux:sync-all

# 4. Check GitRepository connectivity
kubectl describe gitrepository brightlab -n flux-system
```

#### Resolution Steps

1. **Check Git connectivity** - verify the GitRepository can reach GitHub (DNS is a common culprit — see `task fix:dns`)
2. **Validate manifests** - check for YAML syntax errors
3. **Check permissions** - ensure Flux's service account has cluster access
4. **Force reconciliation**
5. **Restart Flux controllers** if needed

#### Commands

```bash
# Force reconcile a specific Kustomization
flux reconcile kustomization <name> -n flux-system --with-source

# Restart Flux controllers
kubectl rollout restart deployment -n flux-system
```

### Scenario 4: Network Connectivity Issues

#### Symptoms

- Services unreachable
- DNS resolution failures
- Network policy violations

#### Immediate Actions

```bash
# 1. Check network policies
kubectl get networkpolicies -A

# 2. Test DNS resolution
task dns:check

# 3. Check service endpoints
kubectl get endpoints -A

# 4. Test connectivity from pod
kubectl exec -it <pod-name> -n <namespace> -- nslookup <service-name>
```

#### Resolution Steps

1. **Check network policies** - ensure they allow required traffic
2. **Verify DNS** - check CoreDNS pods
3. **Test service connectivity** - check service and endpoints
4. **Check firewall rules** - ensure ports are open
5. **Temporarily disable network policies** for testing

#### Commands

```bash
# Test DNS from pod
kubectl exec -it <pod-name> -n <namespace> -- nslookup kubernetes.default.svc.cluster.local

# Check service connectivity
kubectl exec -it <pod-name> -n <namespace> -- curl <service-name>.<namespace>.svc.cluster.local

# Temporarily disable network policy
kubectl delete networkpolicy <policy-name> -n <namespace>
```

### Scenario 5: Resource Exhaustion

#### Symptoms

- Pods pending due to resource constraints
- High CPU/memory usage
- Node not ready status

#### Immediate Actions

```bash
# 1. Check node status
kubectl get nodes -o wide

# 2. Check resource usage
kubectl top nodes
kubectl top pods --all-namespaces

# 3. Check pending pods
kubectl get pods --all-namespaces --field-selector=status.phase=Pending

# 4. Check resource quotas
kubectl get resourcequota -A
```

#### Resolution Steps

1. **Scale down non-critical workloads** - free up resources
2. **Increase resource limits** - if possible
3. **Add more nodes** - scale cluster
4. **Check resource quotas** - increase if needed
5. **Optimize resource requests** - right-size containers

#### Commands

```bash
# Scale down deployment
kubectl scale deployment/<deployment-name> --replicas=0 -n <namespace>

# Check resource quotas
kubectl describe resourcequota -n <namespace>

# Check node capacity
kubectl describe node <node-name>
```

## 🔄 Post-Incident Procedures

### 1. Incident Resolution

- [ ] **Root cause identified**
- [ ] **Service restored**
- [ ] **Monitoring alerts cleared**
- [ ] **Users notified of resolution**

### 2. Documentation

- [ ] **Incident details recorded**
- [ ] **Timeline documented**
- [ ] **Resolution steps documented**
- [ ] **Lessons learned captured**

### 3. Follow-up Actions

- [ ] **Post-incident review scheduled**
- [ ] **Prevention measures identified**
- [ ] **Runbook updated** if needed
- [ ] **Monitoring improved** if gaps found

## 📞 Communication Templates

### Initial Alert

```
🚨 INCIDENT ALERT
Severity: P[1-4]
Service: [Service Name]
Description: [Brief description]
Status: Investigating
ETA: [Estimated resolution time]
```

### Status Update

```
📊 INCIDENT UPDATE
Severity: P[1-4]
Service: [Service Name]
Status: [Investigating/Resolved]
Progress: [Current status]
ETA: [Updated resolution time]
```

### Resolution

```
✅ INCIDENT RESOLVED
Severity: P[1-4]
Service: [Service Name]
Resolution: [Brief description]
Duration: [Total time]
Post-incident review: [Scheduled time]
```

## 🛠 Emergency Commands Reference

### Quick Fixes

```bash
# Restart all deployments in namespace
kubectl rollout restart deployment -n <namespace>

# Scale down all deployments
kubectl scale deployment --replicas=0 -n <namespace>

# Delete stuck pods
kubectl delete pod <pod-name> -n <namespace> --force --grace-period=0

# Force Flux to reconcile everything from Git right now
task flux:sync-all
```

### Emergency Access

```bash
# Get Keycloak admin password
kubectl get secret keycloak-admin -n keycloak -o jsonpath='{.data.password}' | base64 -d

# Port forward to service
kubectl port-forward svc/<service-name> -n <namespace> 8080:80

# Execute into pod
kubectl exec -it <pod-name> -n <namespace> -- /bin/bash
```

## 📋 Incident Checklist

### Pre-Incident Preparation

- [ ] **Monitoring alerts configured**
- [ ] **Runbooks accessible**
- [ ] **Emergency contacts updated**
- [ ] **Access credentials available**
- [ ] **Backup procedures tested**

### During Incident

- [ ] **Severity level determined**
- [ ] **Stakeholders notified**
- [ ] **Incident channel created**
- [ ] **Progress documented**
- [ ] **Escalation triggered** if needed

### Post-Incident

- [ ] **Service fully restored**
- [ ] **Monitoring confirmed**
- [ ] **Users notified**
- [ ] **Incident documented**
- [ ] **Review scheduled**
