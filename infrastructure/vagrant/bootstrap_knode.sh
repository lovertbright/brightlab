#!/bin/bash
set -euo pipefail

SSH_OPTS="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
CONTROLLER="kcontroller.example.com"

echo "[TASK 1] Join node to Kubernetes Cluster"
export DEBIAN_FRONTEND=noninteractive
apt-get install -qq -y sshpass

HOSTNAME=$(hostname -s)

if [ -f /etc/kubernetes/kubelet.conf ]; then
  echo "Node already joined; skipping kubeadm join"
else
  # Bootstrap tokens expire after 24h and their JWS signatures are removed
  # from kube-public/cluster-info. Always mint a fresh join command so later
  # worker provisioning (or scale-up) does not reuse a stale token.
  sshpass -p "kubeadmin" ssh $SSH_OPTS "$CONTROLLER" \
    "sudo kubeadm token create --print-join-command" > /joincluster.sh
  chmod +x /joincluster.sh
  bash /joincluster.sh
fi

echo "[TASK 2] Add worker role label to node"
for _ in $(seq 1 30); do
  if sshpass -p "kubeadmin" ssh $SSH_OPTS "$CONTROLLER" \
    "sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl get node ${HOSTNAME} >/dev/null 2>&1"; then
    break
  fi
  sleep 2
done

sshpass -p "kubeadmin" ssh $SSH_OPTS "$CONTROLLER" \
  "sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl label node ${HOSTNAME} node-role.kubernetes.io/worker=worker --overwrite"

