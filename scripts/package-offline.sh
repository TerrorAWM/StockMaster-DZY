#!/usr/bin/env bash
# Build a self-contained offline deployment package.
# Run from the project root after `docker compose up -d --build`.
#
# Output: stockmaster-offline.tar.gz
# Recipient only needs Docker installed, then: tar -xzf ... && bash start.sh
set -euo pipefail

WORK_DIR="$(cd "$(dirname "$0")/.." && pwd)"
STAGING="$(mktemp -d)/stockmaster-offline"
OUTPUT="${WORK_DIR}/stockmaster-offline.tar.gz"

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

cd "$WORK_DIR"

# ── 1. Check images ──────────────────────────────────────────────────────────
echo ">>> [1/4] Checking Docker images..."
for img in "${IMAGES[@]}"; do
  if ! docker image inspect "$img" &>/dev/null; then
    echo "ERROR: Image not found: $img"
    echo "  Run 'docker compose up -d --build' first, then re-run this script."
    exit 1
  fi
  echo "  OK  $img"
done

# ── 2. Export images ─────────────────────────────────────────────────────────
echo ""
echo ">>> [2/4] Exporting images (this may take a few minutes)..."
mkdir -p "${STAGING}/docker-images"
docker save "${IMAGES[@]}" | gzip > "${STAGING}/docker-images/stockmaster-images.tar.gz"
SIZE=$(du -sh "${STAGING}/docker-images/stockmaster-images.tar.gz" | cut -f1)
echo "  Images saved: ${SIZE}"

# ── 3. Copy config files ─────────────────────────────────────────────────────
echo ""
echo ">>> [3/4] Copying configuration files..."
cp docker-compose.yml "${STAGING}/"
cp -r config-repo "${STAGING}/"
mkdir -p "${STAGING}/k8s/mysql"
cp k8s/mysql/init.sql "${STAGING}/k8s/mysql/"

# ── 4. Write helper scripts ──────────────────────────────────────────────────
cat > "${STAGING}/start.sh" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# Check Docker
if ! docker info &>/dev/null; then
  echo "ERROR: Docker is not running. Please start Docker and try again."
  exit 1
fi

echo ">>> Loading Docker images (first run may take a few minutes)..."
if docker image inspect stockmaster/eureka-service:local &>/dev/null; then
  echo "  Images already loaded, skipping import."
else
  gunzip -c docker-images/stockmaster-images.tar.gz | docker load
fi

echo ""
echo ">>> Starting StockMaster..."
docker compose up -d

echo ""
echo ">>> Waiting for services to be ready..."
for i in $(seq 1 30); do
  if curl -sf http://localhost:30081 &>/dev/null; then
    break
  fi
  printf "  [%d/30] waiting...\r" "$i"
  sleep 3
done

echo ""
echo "============================================"
echo " StockMaster is ready!"
echo " URL:      http://localhost:30081"
echo " Account:  admin / admin123"
echo "============================================"
EOF

cat > "${STAGING}/stop.sh" << 'EOF'
#!/usr/bin/env bash
cd "$(dirname "$0")"
docker compose down
echo "StockMaster stopped."
EOF

chmod +x "${STAGING}/start.sh" "${STAGING}/stop.sh"

cat > "${STAGING}/README.txt" << 'EOF'
StockMaster 离线部署包
=====================

前置要求：
  - Docker Desktop 或 Docker Engine（无需 Java / Maven / Node）

启动：
  bash start.sh

停止：
  bash stop.sh

访问地址：
  http://localhost:30081

默认账号：
  admin / admin123

端口说明：
  30081  前端页面
   8080  API 网关
   8761  Eureka 控制台
  13306  MySQL（宿主机端口，用户 root，密码 root）

如果 30081 被占用，编辑 docker-compose.yml 修改 ports 左侧的端口号，然后重新运行 start.sh。
EOF

# ── 5. Pack everything ───────────────────────────────────────────────────────
echo ""
echo ">>> [4/4] Creating final package..."
tar -czf "$OUTPUT" -C "$(dirname "$STAGING")" "$(basename "$STAGING")"
rm -rf "$(dirname "$STAGING")"

TOTAL=$(du -sh "$OUTPUT" | cut -f1)
echo ""
echo "========================================"
echo " Package ready: stockmaster-offline.tar.gz"
echo " Size: ${TOTAL}"
echo "========================================"
echo ""
echo "Send this file to the recipient."
echo ""
echo "Recipient runs:"
echo "  tar -xzf stockmaster-offline.tar.gz"
echo "  cd stockmaster-offline"
echo "  bash start.sh"
