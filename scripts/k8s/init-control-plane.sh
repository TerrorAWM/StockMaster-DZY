#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run this script with sudo."
  exit 1
fi

POD_NETWORK_CIDR="${POD_NETWORK_CIDR:-192.168.0.0/16}"
CONTROL_PLANE_IP="${CONTROL_PLANE_IP:-$(hostname -I | awk '{print $1}')}"
CALICO_VERSION="${CALICO_VERSION:-v3.28.0}"
TARGET_USER="${SUDO_USER:-root}"
TARGET_HOME="$(getent passwd "${TARGET_USER}" | cut -d: -f6)"

kubeadm init \
  --apiserver-advertise-address="${CONTROL_PLANE_IP}" \
  --pod-network-cidr="${POD_NETWORK_CIDR}"

mkdir -p "${TARGET_HOME}/.kube"
cp /etc/kubernetes/admin.conf "${TARGET_HOME}/.kube/config"
chown "${TARGET_USER}:${TARGET_USER}" "${TARGET_HOME}/.kube/config"

export KUBECONFIG=/etc/kubernetes/admin.conf
kubectl apply -f "https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/calico.yaml"

echo "Run the following command on every worker node:"
kubeadm token create --print-join-command
