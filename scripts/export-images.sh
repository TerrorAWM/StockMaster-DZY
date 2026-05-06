#!/usr/bin/env bash
# Export all StockMaster Docker images to a tar.gz offline package.
# Run from the project root after `docker compose up -d --build`.
set -euo pipefail

OUTPUT_DIR="${1:-docker-images}"
ARCHIVE="${OUTPUT_DIR}/stockmaster-images.tar"

IMAGES=(
  mysql:8.0
  stockmaster/eureka-service:local
  stockmaster/config-service:local
  stockmaster/gateway-service:local
  stockmaster/user-service:local
  stockmaster/product-service:local
  stockmaster/stock-service:local
  stockmaster/order-service:local
  stockmaster/frontend-nginx:local
)

echo ">>> Checking images..."
for img in "${IMAGES[@]}"; do
  if ! docker image inspect "$img" &>/dev/null; then
    echo "ERROR: Image not found: $img"
    echo "  Run 'docker compose up -d --build' first."
    exit 1
  fi
done

mkdir -p "$OUTPUT_DIR"
echo ">>> Saving images to ${ARCHIVE} ..."
docker save "${IMAGES[@]}" -o "$ARCHIVE"

echo ">>> Compressing..."
gzip -f "$ARCHIVE"

SIZE=$(du -sh "${ARCHIVE}.gz" | cut -f1)
echo ""
echo "Done: ${ARCHIVE}.gz  (${SIZE})"
echo ""
echo "Copy the following to the target machine:"
echo "  ${ARCHIVE}.gz"
echo "  docker-compose.yml"
echo "  config-repo/"
echo "  k8s/mysql/init.sql  (must be at k8s/mysql/init.sql relative to docker-compose.yml)"
