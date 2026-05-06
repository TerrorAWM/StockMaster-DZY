# StockMaster Windows 一键安装脚本 (PowerShell)
#
# 用法 1 – 在线模式：
#   powershell -ExecutionPolicy Bypass -File install.ps1
#
# 用法 2 – 离线模式：
#   powershell -ExecutionPolicy Bypass -File install.ps1 -Offline .\stockmaster-images.tar.gz
#
# 用法 3 – 启用自动更新（推送到 GitHub 后自动拉取新镜像）：
#   powershell -ExecutionPolicy Bypass -File install.ps1 -Watch
#   powershell -ExecutionPolicy Bypass -File install.ps1 -Offline .\images.tar.gz -Watch
#
# 前置要求：只需安装 Docker Desktop for Windows（无需 Java / Maven / Node）
param(
    [string]$Offline = "",
    [switch]$Watch
)

$ErrorActionPreference = "Stop"
$REGISTRY = "ghcr.io/terrorawm"
$SERVICES  = @("eureka-service","config-service","gateway-service","user-service","product-service","stock-service","order-service")

# ── 1. 检查 Docker ────────────────────────────────────────────────────────────
Write-Host "`n>>> [1/5] Checking Docker..." -ForegroundColor Cyan
try { docker info 2>&1 | Out-Null } catch {
    Write-Host "ERROR: Docker is not running. Please start Docker Desktop and try again." -ForegroundColor Red
    exit 1
}
Write-Host "  Docker OK" -ForegroundColor Green

# ── 2. 创建工作目录 & 写入配置文件 ───────────────────────────────────────────
$InstallDir = Join-Path (Get-Location) "stockmaster"
Write-Host "`n>>> [2/5] Writing configuration files to $InstallDir ..." -ForegroundColor Cyan

New-Item -ItemType Directory -Force -Path "$InstallDir\config-repo" | Out-Null
New-Item -ItemType Directory -Force -Path "$InstallDir\k8s\mysql"   | Out-Null
Push-Location $InstallDir

Set-Content -Encoding UTF8 "config-repo\gateway-service.yml" @"
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
    secret: `${JWT_SECRET:stockmaster-dev-secret}

eureka:
  client:
    service-url:
      defaultZone: `${EUREKA_URL:http://localhost:8761/eureka/}
"@

Set-Content -Encoding UTF8 "config-repo\user-service.yml" @"
server:
  port: 8081

spring:
  datasource:
    url: `${USER_DB_URL:jdbc:mysql://localhost:3306/stockmaster_user?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Shanghai}
    username: `${MYSQL_USER:root}
    password: `${MYSQL_PASSWORD:root}
  jpa:
    hibernate:
      ddl-auto: update
    open-in-view: false

stockmaster:
  jwt:
    secret: `${JWT_SECRET:stockmaster-dev-secret}

eureka:
  client:
    service-url:
      defaultZone: `${EUREKA_URL:http://localhost:8761/eureka/}
"@

Set-Content -Encoding UTF8 "config-repo\product-service.yml" @"
server:
  port: 8082

spring:
  datasource:
    url: `${PRODUCT_DB_URL:jdbc:mysql://localhost:3306/stockmaster_product?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Shanghai}
    username: `${MYSQL_USER:root}
    password: `${MYSQL_PASSWORD:root}
  jpa:
    hibernate:
      ddl-auto: update
    open-in-view: false

eureka:
  client:
    service-url:
      defaultZone: `${EUREKA_URL:http://localhost:8761/eureka/}
"@

Set-Content -Encoding UTF8 "config-repo\stock-service.yml" @"
server:
  port: 8083

spring:
  datasource:
    url: `${STOCK_DB_URL:jdbc:mysql://localhost:3306/stockmaster_stock?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Shanghai}
    username: `${MYSQL_USER:root}
    password: `${MYSQL_PASSWORD:root}
  jpa:
    hibernate:
      ddl-auto: update
    open-in-view: false

eureka:
  client:
    service-url:
      defaultZone: `${EUREKA_URL:http://localhost:8761/eureka/}
"@

Set-Content -Encoding UTF8 "config-repo\order-service.yml" @"
server:
  port: 8084

spring:
  datasource:
    url: `${ORDER_DB_URL:jdbc:mysql://localhost:3306/stockmaster_order?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Shanghai}
    username: `${MYSQL_USER:root}
    password: `${MYSQL_PASSWORD:root}
  jpa:
    hibernate:
      ddl-auto: update
    open-in-view: false

eureka:
  client:
    service-url:
      defaultZone: `${EUREKA_URL:http://localhost:8761/eureka/}
"@

Set-Content -Encoding UTF8 "k8s\mysql\init.sql" @"
CREATE DATABASE IF NOT EXISTS stockmaster_user CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS stockmaster_product CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS stockmaster_stock CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS stockmaster_order CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
"@

# docker-compose.yml（使用 GHCR 镜像，无 build 步骤）
Set-Content -Encoding UTF8 "docker-compose.yml" @"
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
"@

Write-Host "  Config files written." -ForegroundColor Green

# ── 3. 准备镜像 ───────────────────────────────────────────────────────────────
Write-Host ""
if ($Offline -ne "") {
    Write-Host ">>> [3/5] Loading images from offline package: $Offline" -ForegroundColor Cyan
    if (-not (Test-Path $Offline)) {
        Write-Host "ERROR: File not found: $Offline" -ForegroundColor Red
        Pop-Location; exit 1
    }
    # docker load 原生支持 .tar.gz
    docker load -i $Offline

    Write-Host "  Tagging images as GHCR references..." -ForegroundColor Gray
    foreach ($svc in $SERVICES) {
        docker tag "stockmaster/${svc}:local" "${REGISTRY}/stockmaster-${svc}:latest" 2>$null
    }
    docker tag "stockmaster/frontend-nginx:local" "${REGISTRY}/stockmaster-frontend-nginx:latest" 2>$null
    Write-Host "  Done." -ForegroundColor Green
} else {
    Write-Host ">>> [3/5] Pulling images from GHCR..." -ForegroundColor Cyan
    docker pull mysql:8.0
    foreach ($svc in $SERVICES) {
        docker pull "${REGISTRY}/stockmaster-${svc}:latest"
    }
    docker pull "${REGISTRY}/stockmaster-frontend-nginx:latest"
    Write-Host "  All images pulled." -ForegroundColor Green
}

# ── 4. Watchtower（自动更新）────────────────────────────────────────────────
if ($Watch) {
    Set-Content -Encoding UTF8 "docker-compose.watch.yml" @"
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
"@
    Write-Host "  Auto-update enabled: Watchtower will check GHCR every 5 minutes." -ForegroundColor Yellow
}

# ── 5. 启动服务 ───────────────────────────────────────────────────────────────
Write-Host ""
Write-Host ">>> [4/5] Starting StockMaster..." -ForegroundColor Cyan
$env:REGISTRY = $REGISTRY
if ($Watch) {
    docker compose -f docker-compose.yml -f docker-compose.watch.yml up -d
} else {
    docker compose up -d
}
Write-Host "  Services started." -ForegroundColor Green

# ── 5. 等待就绪 ───────────────────────────────────────────────────────────────
Write-Host ""
Write-Host ">>> [5/5] Waiting for services to be ready (up to 90s)..." -ForegroundColor Cyan
$ready = $false
for ($i = 1; $i -le 30; $i++) {
    Start-Sleep -Seconds 3
    try {
        $resp = Invoke-WebRequest -Uri "http://localhost:30081" -UseBasicParsing -TimeoutSec 2 -ErrorAction SilentlyContinue
        if ($resp.StatusCode -eq 200) { $ready = $true; break }
    } catch {}
    Write-Host ("  [{0:D2}/30] waiting..." -f $i) -NoNewline
    Write-Host "`r" -NoNewline
}

Pop-Location

Write-Host ""
if ($ready) {
    Write-Host "================================================" -ForegroundColor Green
    Write-Host "  StockMaster is ready!" -ForegroundColor Green
    Write-Host "  URL:     http://localhost:30081" -ForegroundColor Green
    Write-Host "  Account: admin / admin123" -ForegroundColor Green
    if ($Watch) {
        Write-Host "  Auto-update: checks GHCR every 5 min" -ForegroundColor Green
    }
    Write-Host "================================================" -ForegroundColor Green
} else {
    Write-Host "Services are still starting. Check status with:" -ForegroundColor Yellow
    Write-Host "  cd $InstallDir && docker compose ps"
    Write-Host "Then open: http://localhost:30081"
}

Write-Host ""
Write-Host "To stop:    cd $InstallDir; docker compose down"
Write-Host "To restart: cd $InstallDir; docker compose up -d"
