#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLUSTER_NAME="${CLUSTER_NAME:-stockmaster-local}"
SERVICES=(eureka-service config-service gateway-service user-service product-service stock-service order-service)

cd "${ROOT_DIR}"

if ! kind get clusters | grep -qx "${CLUSTER_NAME}"; then
  kind create cluster --config k8s/kind-config.yaml
fi

mvn --batch-mode -DskipTests -f backend/pom.xml package

for service in "${SERVICES[@]}"; do
  docker build -t "ghcr.io/terrorawm/stockmaster-${service}:local" "backend/${service}"
  kind load docker-image "ghcr.io/terrorawm/stockmaster-${service}:local" --name "${CLUSTER_NAME}"
done

docker build -t ghcr.io/terrorawm/stockmaster-frontend-nginx:local frontend
kind load docker-image ghcr.io/terrorawm/stockmaster-frontend-nginx:local --name "${CLUSTER_NAME}"

docker image inspect mysql:8.0.26 >/dev/null 2>&1 || docker pull mysql:8.0.26
kind load docker-image mysql:8.0.26 --name "${CLUSTER_NAME}"

kubectl apply -k k8s
for service in "${SERVICES[@]}" frontend-nginx; do
  kubectl patch "deployment/${service}" -n stockmaster --type json \
    -p '[{"op":"replace","path":"/spec/template/spec/containers/0/imagePullPolicy","value":"IfNotPresent"}]'
done

for service in "${SERVICES[@]}"; do
  kubectl set image "deployment/${service}" "${service}=ghcr.io/terrorawm/stockmaster-${service}:local" -n stockmaster
done
kubectl set image deployment/frontend-nginx frontend-nginx=ghcr.io/terrorawm/stockmaster-frontend-nginx:local -n stockmaster

bash k8s/verify.sh

echo "Frontend: http://127.0.0.1:30081"
echo "Gateway:  http://127.0.0.1:30080"
echo "Eureka:   http://127.0.0.1:30761"
