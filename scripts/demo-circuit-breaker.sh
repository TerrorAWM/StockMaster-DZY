#!/usr/bin/env bash
set -euo pipefail

GATEWAY_URL="${GATEWAY_URL:-http://127.0.0.1:30080}"
NAMESPACE="${NAMESPACE:-stockmaster}"

command -v jq >/dev/null || {
  echo "jq is required."
  exit 1
}

token="$(
  curl -sS "${GATEWAY_URL}/api/auth/login" \
    -H 'Content-Type: application/json' \
    -d '{"username":"admin","password":"admin123"}' |
    jq -r '.data.token'
)"

product_id="$(
  curl -sS "${GATEWAY_URL}/api/products" \
    -H "Authorization: Bearer ${token}" |
    jq -r '.data[0].id'
)"

if [[ -z "${product_id}" || "${product_id}" == "null" ]]; then
  echo "Create at least one product before running this demo."
  exit 1
fi

restore() {
  kubectl scale deployment/product-service -n "${NAMESPACE}" --replicas=2 >/dev/null
}
trap restore EXIT

echo "Stopping product-service to demonstrate circuit-breaker fallback..."
kubectl scale deployment/product-service -n "${NAMESPACE}" --replicas=0
kubectl wait --for=delete pod -l app=product-service -n "${NAMESPACE}" --timeout=120s

for i in 1 2 3 4 5; do
  echo "Request ${i}:"
  curl -sS "${GATEWAY_URL}/api/orders/inbound" \
    -H "Authorization: Bearer ${token}" \
    -H 'Content-Type: application/json' \
    -d "{\"productId\":${product_id},\"quantity\":1,\"remark\":\"circuit-breaker-demo\"}"
  echo
done

echo "Restoring product-service..."
restore
trap - EXIT
kubectl rollout status deployment/product-service -n "${NAMESPACE}" --timeout=300s
