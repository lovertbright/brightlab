#!/bin/bash

# Script to copy kubeconfig from Kubernetes controller VM to local machine
# This script safely merges the new config with your existing ~/.kube/config

set -e

CONTROLLER_IP="172.16.16.100"
CONTROLLER_USER="root"
CONTROLLER_PASSWORD="kubeadmin"
KUBECONFIG_DIR="$HOME/.kube"
KUBECONFIG_DEFAULT="$KUBECONFIG_DIR/config"
KUBECONFIG_NEW="$KUBECONFIG_DIR/config.brightlab"

echo "🔐 Setting up kubeconfig for brightlab local access..."
# Remove the old context if it exists
kubectl config delete-context brightlab >/dev/null 2>&1 || true
kubectl config delete-cluster brightlab >/dev/null 2>&1 || true
kubectl config delete-user brightlab >/dev/null 2>&1 || true

# Create .kube directory in home if it doesn't exist
if [ ! -d "$KUBECONFIG_DIR" ]; then
    mkdir -p "$KUBECONFIG_DIR"
fi

# Check if kcontroller is running
echo "Checking if kcontroller is running..."
if ! vagrant status kcontroller | grep -q "running"; then
    echo "❌ Error: kcontroller VM is not running."
    echo "   Run: task vagrant:up"
    exit 1
fi

# Copy kubeconfig from controller VM using vagrant ssh (bypasses network IP issues)
echo "📥 Downloading kubeconfig from controller..."
vagrant ssh kcontroller -c "sudo cat /etc/kubernetes/admin.conf" > "$KUBECONFIG_NEW"

if [ ! -s "$KUBECONFIG_NEW" ]; then
    echo "❌ Error: Failed to retrieve kubeconfig or file is empty."
    exit 1
fi

# Set permissions
chmod 600 "$KUBECONFIG_NEW"

# Modify the new kubeconfig (Context/User/Cluster renaming to avoid conflicts)
echo "🔄 Configuring context as 'brightlab'..."

# Normalize line endings (avoid sed $ not matching on CRLF)
if command -v tr >/dev/null 2>&1; then
    tr -d '\r' < "$KUBECONFIG_NEW" > "${KUBECONFIG_NEW}.cr" && mv "${KUBECONFIG_NEW}.cr" "$KUBECONFIG_NEW"
fi

# Create a temporary environment to modify ONLY the new config
export KUBECONFIG="$KUBECONFIG_NEW"

# Remove certificate-authority-data (we will use insecure-skip-verify in dev)
sed -i.bak2 '/certificate-authority-data:/d' "$KUBECONFIG_NEW"

# Add insecure-skip-tls-verify to the cluster config
# We replace the private IP with localhost since port 6443 is forwarded
awk -v ip="$CONTROLLER_IP" '$0 ~ ("server: https://" ip ":6443") { print "    server: https://127.0.0.1:6443"; print "    insecure-skip-tls-verify: true"; next } 1' "$KUBECONFIG_NEW" > "${KUBECONFIG_NEW}.tmp" && mv "${KUBECONFIG_NEW}.tmp" "$KUBECONFIG_NEW"

# Rename context, user, and cluster to 'brightlab'
# Use global replace for context name (works with trailing space or no $); only this string appears as context name
sed -i.bak4 's/kubernetes-admin@kubernetes/brightlab/g' "$KUBECONFIG_NEW"
sed -i.bak5 's/name: kubernetes$/name: brightlab/' "$KUBECONFIG_NEW"
sed -i.bak6 's/cluster: kubernetes$/cluster: brightlab/' "$KUBECONFIG_NEW"
sed -i.bak7 's/user: kubernetes-admin$/user: brightlab/' "$KUBECONFIG_NEW"
sed -i.bak8 's/name: kubernetes-admin$/name: brightlab/' "$KUBECONFIG_NEW"

# Clean up backups
rm -f "${KUBECONFIG_NEW}.bak"*

# Now Merge with existing config
echo "Merging with existing kubeconfig..."

# Backup existing config
if [ -f "$KUBECONFIG_DEFAULT" ]; then
    cp "$KUBECONFIG_DEFAULT" "${KUBECONFIG_DEFAULT}.bak"
    
    # Remove existing brightlab context if it exists to ensure we use the new one
    # We do this on the DEFAULT file using a temporary KUBECONFIG env
    (
        export KUBECONFIG="$KUBECONFIG_DEFAULT"
        if kubectl config get-contexts brightlab >/dev/null 2>&1; then
             echo "   Removing existing 'brightlab' context to prevent conflicts..."
             kubectl config delete-context brightlab >/dev/null 2>&1 || true
             kubectl config delete-cluster brightlab >/dev/null 2>&1 || true
             kubectl config delete-user brightlab >/dev/null 2>&1 || true
        fi
    )

    # Merge using KUBECONFIG env var
    # Put NEW first to ensure it takes precedence
    export KUBECONFIG="$KUBECONFIG_NEW:$KUBECONFIG_DEFAULT"
    kubectl config view --flatten > "${KUBECONFIG_DEFAULT}.merged"
    mv "${KUBECONFIG_DEFAULT}.merged" "$KUBECONFIG_DEFAULT"
    chmod 600 "$KUBECONFIG_DEFAULT"
    echo "✅ Kubeconfig merged."
else
    # No existing config, just move the new one
    mv "$KUBECONFIG_NEW" "$KUBECONFIG_DEFAULT"
    chmod 600 "$KUBECONFIG_DEFAULT"
    echo "✅ Created new ~/.kube/config"
fi

# Clean up temp file
rm -f "$KUBECONFIG_NEW"

# Use the merged config for the remainder
export KUBECONFIG="$KUBECONFIG_DEFAULT"

echo ""
echo "🔄 Switching to context 'brightlab'..."
if kubectl config get-contexts brightlab &>/dev/null; then
    kubectl config use-context brightlab
    echo ""
    echo "🎉 Context 'brightlab' is ready and active!"
else
    # Fallback: set current-context to the context that points to our cluster (127.0.0.1:6443)
    CONTEXT_FOR_6443=$(kubectl config get-contexts -o name 2>/dev/null | while read -r ctx; do
        if kubectl config view --context="$ctx" -o jsonpath='{.clusters[0].cluster.server}' 2>/dev/null | grep -q '127.0.0.1:6443'; then
            echo "$ctx"
            break
        fi
    done)
    if [ -n "$CONTEXT_FOR_6443" ]; then
        kubectl config use-context "$CONTEXT_FOR_6443"
        echo ""
        echo "✅ Switched to context '$CONTEXT_FOR_6443' (cluster at 127.0.0.1:6443)."
        echo "   To rename it to 'brightlab': kubectl config rename-context '$CONTEXT_FOR_6443' brightlab"
    else
        echo "⚠️  Context 'brightlab' not found in merged config. Available contexts:"
        kubectl config get-contexts -o name 2>/dev/null || true
        echo "   Run: kubectl config use-context <name> to select your cluster."
        exit 1
    fi
fi
unset KUBECONFIG 2>/dev/null || true
echo "   Verify with: kubectl cluster-info"
