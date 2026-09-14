# Service Access Guide

## ⚠️ Important: Use HTTPS, Not HTTP

All services use HTTPS with valid Let's Encrypt certificates. Always use `https://` URLs.

---

## 🌐 Services with Web UIs (Browser Access)

### ✅ Services You Can Access in Browser:

| Service | URL | Description |
|---------|-----|-------------|
| **Grafana** | https://grafana.lbrightlab.com | Observability dashboards |
| **Keycloak** | https://keycloak.lbrightlab.com | Identity management |
| **Prometheus** | https://prometheus.lbrightlab.com | Metrics & monitoring |
| **Alloy** | https://alloy.lbrightlab.com | Telemetry collector |

---

## ❌ Services WITHOUT Web UIs (API Only)

These services are **APIs** and don't have web interfaces. Don't try to access them in a browser:

### Tempo (http://tempo.lbrightlab.com)
- **Type:** Distributed tracing backend
- **Used by:** Grafana (as a data source)
- **Access:** Only via API or Grafana
- **Why 404:** No web UI exists

### Loki (http://loki.lbrightlab.com)
- **Type:** Log aggregation system
- **Used by:** Grafana (as a data source)
- **Access:** Only via API or Grafana
- **Why 404:** No web UI exists

---

## 🔧 How to Use API Services

### View Tempo Traces in Grafana

1. Open https://grafana.lbrightlab.com
2. Go to **Explore**
3. Select **Tempo** as data source
4. Query traces

### View Loki Logs in Grafana

1. Open https://grafana.lbrightlab.com
2. Go to **Explore**
3. Select **Loki** as data source
4. Query logs using LogQL

---

## 🐛 Troubleshooting

### "Not Secure" or Certificate Errors

**Problem:** Accessing via `http://` instead of `https://`

**Solution:**
✅ Use `https://grafana.lbrightlab.com`
❌ Don't use `http://grafana.lbrightlab.com`

All services have valid Let's Encrypt certificates for HTTPS.

### Pages Load Slowly

**Causes:**
1. Network congestion
2. Service resource constraints

**Solutions:**
```bash
# Check gateway status
kubectl get svc main-gateway-istio -n istio-system

# Check service pods are running
kubectl get pods -A --field-selector=status.phase!=Running
```

### 404 Errors on Tempo/Loki

**This is normal!** These services don't have web UIs.

Use them through Grafana instead.

---

## 📋 Quick Access Checklist

- [ ] Using `https://` URLs (not `http://`)
- [ ] Only accessing services with web UIs
- [ ] Gateway IP reachable (172.16.16.150)
- [ ] Certificates accepted in browser

---

## 🚀 Recommended Workflow

1. **Start with Grafana:** https://grafana.lbrightlab.com
   - View all metrics, logs, and traces here
   - Access Prometheus, Loki, and Tempo data sources

2. **Manage Users:** https://keycloak.lbrightlab.com
   - Configure authentication
   - Manage user access

---

## 💡 Pro Tips

1. **Bookmark the HTTPS URLs** - Save yourself typing
2. **Use Grafana for everything observability** - Don't access backends directly
3. **Trust the certificates** - They're valid Let's Encrypt certs
4. **Check gateway status** - Run `task gateway:status` to verify routing

---

## 🔗 Valid URLs Summary

Copy these to your browser:

```
https://grafana.lbrightlab.com
https://keycloak.lbrightlab.com
https://prometheus.lbrightlab.com
https://alloy.lbrightlab.com
```

**Do NOT access:**
- tempo.lbrightlab.com (no web UI)
- loki.lbrightlab.com (no web UI)
