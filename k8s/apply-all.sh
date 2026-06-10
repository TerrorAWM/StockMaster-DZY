#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl apply -k "${SCRIPT_DIR}"
kubectl rollout status statefulset/mysql -n stockmaster --timeout=300s

for deployment in eureka-service config-service gateway-service user-service product-service stock-service order-service frontend-nginx; do
  kubectl rollout status "deployment/${deployment}" -n stockmaster --timeout=300s
done

kubectl get nodes -o wide
kubectl get pods,services -n stockmaster -o wide
