#!/usr/bin/env bash
set -euo pipefail

GATEWAY_URL="${GATEWAY_URL:-http://127.0.0.1:30080}"
REQUESTS="${REQUESTS:-100}"

echo "Sending ${REQUESTS} requests to ${GATEWAY_URL}/api/products"
for i in $(seq 1 "${REQUESTS}"); do
  status="$(curl -s -o /dev/null -w '%{http_code}' "${GATEWAY_URL}/api/products")"
  printf '%02d -> HTTP %s\n' "${i}" "${status}"
done

echo "HTTP 429 means the Gateway rate limiter is working."
