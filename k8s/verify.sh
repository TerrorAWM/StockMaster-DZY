#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-stockmaster}"

echo "=== Kubernetes nodes ==="
kubectl get nodes -o wide

echo "=== StockMaster workloads ==="
kubectl get pods,deployments,statefulsets,services -n "${NAMESPACE}" -o wide

echo "=== Waiting for rollouts ==="
kubectl rollout status statefulset/mysql -n "${NAMESPACE}" --timeout=300s
for deployment in eureka-service config-service gateway-service user-service product-service stock-service order-service frontend-nginx; do
  kubectl rollout status "deployment/${deployment}" -n "${NAMESPACE}" --timeout=300s
done

echo "=== Non-running pods (must be empty) ==="
kubectl get pods -n "${NAMESPACE}" --field-selector=status.phase!=Running
