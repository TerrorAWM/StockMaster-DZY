#!/usr/bin/env bash
set -euo pipefail

GATEWAY_URL="${GATEWAY_URL:-http://127.0.0.1:30080}"

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
  curl -fsS -X POST \
    "${GATEWAY_URL}/api/orders/admin/circuit-breakers/productService/reset" \
    -H "Authorization: Bearer ${token}" >/dev/null
}
trap restore EXIT

echo "Forcing productService circuit breaker open..."
forced_open="$(
  curl -fsS -X POST \
    "${GATEWAY_URL}/api/orders/admin/circuit-breakers/productService/force-open" \
    -H "Authorization: Bearer ${token}"
)"
echo "${forced_open}" | jq
[[ "$(echo "${forced_open}" | jq -r '.data.state')" == "FORCED_OPEN" ]]

echo "Calling order API; request should use the circuit-breaker fallback:"
fallback_response="$(
  curl -fsS "${GATEWAY_URL}/api/orders/inbound" \
    -H "Authorization: Bearer ${token}" \
    -H 'Content-Type: application/json' \
    -d "{\"productId\":${product_id},\"quantity\":1,\"remark\":\"circuit-breaker-demo\"}"
)"
echo "${fallback_response}" | jq
[[ "$(echo "${fallback_response}" | jq -r '.code')" == "1" ]]
echo "${fallback_response}" | jq -er '.message | contains("触发熔断降级")' >/dev/null

echo "Resetting productService circuit breaker..."
restore
trap - EXIT

status="$(
  curl -fsS "${GATEWAY_URL}/api/orders/admin/circuit-breakers" \
    -H "Authorization: Bearer ${token}"
)"
echo "${status}" | jq
[[ "$(echo "${status}" | jq -r '.data[] | select(.name == "productService") | .state')" == "CLOSED" ]]

echo "Circuit-breaker force-open and reset test passed."
