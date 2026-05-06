#!/usr/bin/env bash
# StockMaster 一键安装脚本
#
# 用法 1 – 在线模式：
#   bash install.sh
#
# 用法 2 – 离线模式：
#   bash install.sh --offline /path/to/stockmaster-images.tar.gz
#
# 用法 3 – 启用自动更新（推送到 GitHub 后自动拉取新镜像）：
#   bash install.sh --watch
#   bash install.sh --offline /path/to/images.tar.gz --watch
#
# 前置要求：只需安装 Docker（无需 Java / Maven / Node）
set -euo pipefail

# ────────────────────────────────────────────────────────────────────────────
# 参数解析
# ────────────────────────────────────────────────────────────────────────────
OFFLINE_TAR=""
WATCH=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --offline) OFFLINE_TAR="$2"; shift 2 ;;
    --watch)   WATCH=true; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

REGISTRY="ghcr.io/terrorawm"
SERVICES=(eureka-service config-service gateway-service user-service product-service stock-service order-service)

# ────────────────────────────────────────────────────────────────────────────
# 检查 Docker
# ────────────────────────────────────────────────────────────────────────────
echo ">>> [1/5] Checking Docker..."
if ! docker info &>/dev/null; then
  echo "ERROR: Docker is not running. Please start Docker Desktop (or Docker Engine) and try again."
  exit 1
fi
echo "  Docker OK"

# ────────────────────────────────────────────────────────────────────────────
# 创建工作目录
# ────────────────────────────────────────────────────────────────────────────
INSTALL_DIR="$(pwd)/stockmaster"
mkdir -p "${INSTALL_DIR}/config-repo" "${INSTALL_DIR}/k8s/mysql"
cd "$INSTALL_DIR"
echo ">>> Install directory: ${INSTALL_DIR}"

# ────────────────────────────────────────────────────────────────────────────
# 写入配置文件（config-repo + init.sql）
# ────────────────────────────────────────────────────────────────────────────
echo ""
echo ">>> [2/5] Writing configuration files..."

cat > config-repo/gateway-service.yml << 'YAML'
server:
  port: 8080

spring:
  cloud:
    gateway:
      routes:
        - id: user-service
          uri: lb://user-service
          predicates:
            - Path=/api/auth/**,/api/users/**
          filters:
            - StripPrefix=1
        - id: product-service
          uri: lb://product-service
          predicates:
            - Path=/api/products/**
          filters:
            - StripPrefix=1
        - id: order-service
          uri: lb://order-service
          predicates:
            - Path=/api/orders/**
          filters:
            - StripPrefix=1
        - id: stock-service
          uri: lb://stock-service
          predicates:
            - Path=/api/stock/**
          filters:
            - StripPrefix=1

stockmaster:
  jwt:
    secret: ${JWT_SECRET:stockmaster-dev-secret}

eureka:
  client:
    service-url:
      defaultZone: ${EUREKA_URL:http://localhost:8761/eureka/}
YAML

cat > config-repo/user-service.yml << 'YAML'
server:
  port: 8081

spring:
  datasource:
    url: ${USER_DB_URL:jdbc:mysql://localhost:3306/stockmaster_user?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Shanghai}
    username: ${MYSQL_USER:root}
    password: ${MYSQL_PASSWORD:root}
  jpa:
    hibernate:
      ddl-auto: update
    open-in-view: false

stockmaster:
  jwt:
    secret: ${JWT_SECRET:stockmaster-dev-secret}

eureka:
  client:
    service-url:
      defaultZone: ${EUREKA_URL:http://localhost:8761/eureka/}
YAML

cat > config-repo/product-service.yml << 'YAML'
server:
  port: 8082

spring:
  datasource:
    url: ${PRODUCT_DB_URL:jdbc:mysql://localhost:3306/stockmaster_product?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Shanghai}
    username: ${MYSQL_USER:root}
    password: ${MYSQL_PASSWORD:root}
  jpa:
    hibernate:
      ddl-auto: update
    open-in-view: false

eureka:
  client:
    service-url:
      defaultZone: ${EUREKA_URL:http://localhost:8761/eureka/}
YAML

cat > config-repo/stock-service.yml << 'YAML'
server:
  port: 8083

spring:
  datasource:
    url: ${STOCK_DB_URL:jdbc:mysql://localhost:3306/stockmaster_stock?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Shanghai}
    username: ${MYSQL_USER:root}
    password: ${MYSQL_PASSWORD:root}
  jpa:
    hibernate:
      ddl-auto: update
    open-in-view: false

eureka:
  client:
    service-url:
      defaultZone: ${EUREKA_URL:http://localhost:8761/eureka/}
YAML

cat > config-repo/order-service.yml << 'YAML'
server:
  port: 8084

spring:
  datasource:
    url: ${ORDER_DB_URL:jdbc:mysql://localhost:3306/stockmaster_order?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Shanghai}
    username: ${MYSQL_USER:root}
    password: ${MYSQL_PASSWORD:root}
  jpa:
    hibernate:
      ddl-auto: update
    open-in-view: false

eureka:
  client:
    service-url:
      defaultZone: ${EUREKA_URL:http://localhost:8761/eureka/}
YAML

cat > k8s/mysql/init.sql << 'SQL'
CREATE DATABASE IF NOT EXISTS stockmaster_user CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS stockmaster_product CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS stockmaster_stock CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS stockmaster_order CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
SQL

echo "  Config files written."

# ────────────────────────────────────────────────────────────────────────────
# 写入 docker-compose.yml（使用 GHCR 镜像，无需本地构建）
# ────────────────────────────────────────────────────────────────────────────
cat > docker-compose.yml << YAML
services:
  mysql:
    image: mysql:8.0
    container_name: stockmaster-mysql
    environment:
      MYSQL_ROOT_PASSWORD: root
      TZ: Asia/Shanghai
    ports:
      - "13306:3306"
    volumes:
      - mysql-data:/var/lib/mysql
      - ./k8s/mysql/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-uroot", "-proot"]
      interval: 10s
      timeout: 5s
      retries: 10

  eureka-service:
    image: ${REGISTRY}/stockmaster-eureka-service:latest
    container_name: stockmaster-eureka
    ports:
      - "8761:8761"

  config-service:
    image: ${REGISTRY}/stockmaster-config-service:latest
    container_name: stockmaster-config
    depends_on:
      - eureka-service
    environment:
      SPRING_PROFILES_ACTIVE: native
      SPRING_CLOUD_CONFIG_SERVER_NATIVE_SEARCH_LOCATIONS: file:/app/config-repo
      EUREKA_URL: http://eureka-service:8761/eureka/
    ports:
      - "8888:8888"
    volumes:
      - ./config-repo:/app/config-repo:ro

  gateway-service:
    image: ${REGISTRY}/stockmaster-gateway-service:latest
    container_name: stockmaster-gateway
    depends_on:
      - eureka-service
      - config-service
    environment:
      CONFIG_URL: http://config-service:8888
      EUREKA_URL: http://eureka-service:8761/eureka/
      JWT_SECRET: stockmaster-docker-secret
    ports:
      - "8080:8080"

  user-service:
    image: ${REGISTRY}/stockmaster-user-service:latest
    container_name: stockmaster-user
    depends_on:
      mysql:
        condition: service_healthy
      eureka-service:
        condition: service_started
      config-service:
        condition: service_started
    environment:
      CONFIG_URL: http://config-service:8888
      EUREKA_URL: http://eureka-service:8761/eureka/
      MYSQL_USER: root
      MYSQL_PASSWORD: root
      USER_DB_URL: jdbc:mysql://mysql:3306/stockmaster_user?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Shanghai
      JWT_SECRET: stockmaster-docker-secret

  product-service:
    image: ${REGISTRY}/stockmaster-product-service:latest
    container_name: stockmaster-product
    depends_on:
      mysql:
        condition: service_healthy
      eureka-service:
        condition: service_started
      config-service:
        condition: service_started
    environment:
      CONFIG_URL: http://config-service:8888
      EUREKA_URL: http://eureka-service:8761/eureka/
      MYSQL_USER: root
      MYSQL_PASSWORD: root
      PRODUCT_DB_URL: jdbc:mysql://mysql:3306/stockmaster_product?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Shanghai

  stock-service:
    image: ${REGISTRY}/stockmaster-stock-service:latest
    container_name: stockmaster-stock
    depends_on:
      mysql:
        condition: service_healthy
      eureka-service:
        condition: service_started
      config-service:
        condition: service_started
      product-service:
        condition: service_started
    environment:
      CONFIG_URL: http://config-service:8888
      EUREKA_URL: http://eureka-service:8761/eureka/
      MYSQL_USER: root
      MYSQL_PASSWORD: root
      STOCK_DB_URL: jdbc:mysql://mysql:3306/stockmaster_stock?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Shanghai

  order-service:
    image: ${REGISTRY}/stockmaster-order-service:latest
    container_name: stockmaster-order
    depends_on:
      mysql:
        condition: service_healthy
      eureka-service:
        condition: service_started
      config-service:
        condition: service_started
      product-service:
        condition: service_started
      stock-service:
        condition: service_started
    environment:
      CONFIG_URL: http://config-service:8888
      EUREKA_URL: http://eureka-service:8761/eureka/
      MYSQL_USER: root
      MYSQL_PASSWORD: root
      ORDER_DB_URL: jdbc:mysql://mysql:3306/stockmaster_order?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Shanghai

  frontend-nginx:
    image: ${REGISTRY}/stockmaster-frontend-nginx:latest
    container_name: stockmaster-frontend
    depends_on:
      - gateway-service
    ports:
      - "30081:80"

volumes:
  mysql-data:
YAML

echo "  docker-compose.yml written."

# ────────────────────────────────────────────────────────────────────────────
# 准备镜像
# ────────────────────────────────────────────────────────────────────────────
echo ""
if [[ -n "$OFFLINE_TAR" ]]; then
  # 离线模式：加载 tar 包后重新打标签
  echo ">>> [3/5] Loading images from offline package: ${OFFLINE_TAR}"
  if [[ ! -f "$OFFLINE_TAR" ]]; then
    echo "ERROR: File not found: ${OFFLINE_TAR}"
    exit 1
  fi
  gunzip -c "$OFFLINE_TAR" | docker load

  echo "  Tagging images as GHCR references..."
  for svc in "${SERVICES[@]}"; do
    docker tag "stockmaster/${svc}:local" "${REGISTRY}/stockmaster-${svc}:latest" 2>/dev/null || true
  done
  docker tag "stockmaster/frontend-nginx:local" "${REGISTRY}/stockmaster-frontend-nginx:latest" 2>/dev/null || true
  echo "  Done."
else
  # 在线模式：从 GHCR 拉取
  echo ">>> [3/5] Pulling images from GHCR..."
  docker pull mysql:8.0
  for svc in "${SERVICES[@]}"; do
    docker pull "${REGISTRY}/stockmaster-${svc}:latest"
  done
  docker pull "${REGISTRY}/stockmaster-frontend-nginx:latest"
  echo "  All images pulled."
fi

# ────────────────────────────────────────────────────────────────────────────
# 写入 Watchtower 覆盖文件（--watch 模式）
# ────────────────────────────────────────────────────────────────────────────
if $WATCH; then
  cat > docker-compose.watch.yml << 'YAML'
services:
  watchtower:
    image: containrrr/watchtower
    container_name: stockmaster-watchtower
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      WATCHTOWER_POLL_INTERVAL: "300"
      WATCHTOWER_CLEANUP: "true"
      WATCHTOWER_INCLUDE_STOPPED: "false"
    command: >
      stockmaster-eureka
      stockmaster-config
      stockmaster-gateway
      stockmaster-user
      stockmaster-product
      stockmaster-stock
      stockmaster-order
      stockmaster-frontend
YAML
  echo "  Auto-update enabled: Watchtower will check GHCR every 5 minutes."
fi

# ────────────────────────────────────────────────────────────────────────────
# 启动服务
# ────────────────────────────────────────────────────────────────────────────
echo ""
echo ">>> [4/5] Starting StockMaster..."
if $WATCH; then
  REGISTRY="$REGISTRY" docker compose -f docker-compose.yml -f docker-compose.watch.yml up -d
else
  REGISTRY="$REGISTRY" docker compose up -d
fi
echo "  Services started."

# ────────────────────────────────────────────────────────────────────────────
# 等待就绪
# ────────────────────────────────────────────────────────────────────────────
echo ""
echo ">>> [5/5] Waiting for services to be ready (up to 90s)..."
for i in $(seq 1 30); do
  if curl -sf http://localhost:30081 &>/dev/null; then
    echo ""
    echo "================================================"
    echo "  StockMaster is ready!"
    echo "  URL:     http://localhost:30081"
    echo "  Account: admin / admin123"
    echo "================================================"
    echo ""
    if $WATCH; then
      echo "Auto-update: Watchtower checks GHCR every 5 min."
      echo "To disable: docker stop stockmaster-watchtower"
    fi
    echo ""
    echo "To stop:    cd ${INSTALL_DIR} && docker compose down"
    echo "To restart: cd ${INSTALL_DIR} && docker compose up -d"
    exit 0
  fi
  printf "  [%2d/30] waiting...\r" "$i"
  sleep 3
done

echo ""
echo "Services are still starting. Check status with:"
echo "  cd ${INSTALL_DIR} && docker compose ps"
echo "Then open: http://localhost:30081"
