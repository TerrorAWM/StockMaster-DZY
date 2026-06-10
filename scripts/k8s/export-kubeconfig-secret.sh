#!/usr/bin/env bash
set -euo pipefail

KUBECONFIG_PATH="${KUBECONFIG:-${HOME}/.kube/config}"

echo "Add the following value as GitHub Environment secret production/KUBE_CONFIG:"
base64 < "${KUBECONFIG_PATH}" | tr -d '\n'
echo
