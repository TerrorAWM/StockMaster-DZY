# StockMaster 仓库库存管理系统

StockMaster 是一个基于 Spring Cloud 微服务和 Vue 3 的仓库库存管理系统，适合云原生课程实验、Docker Compose 单机部署和 GitHub Actions CI/CD 演示。

## 功能说明

- 登录认证：JWT 登录认证，默认管理员账号可直接使用。
- 仪表盘：首页展示商品数量、库存总量、库存预警数量，并使用图形表展示库存分布。
- 商品管理：商品新增、查询、编辑、删除，支持搜索、状态筛选，点击查看按钮可在 Modal 中查看商品详情。
- 入库管理：选择商品并填写数量后增加库存。
- 出库管理：选择商品并填写数量后扣减库存。
- 库存查询：查看商品实时库存。
- 库存流水：查看所有入库、出库记录。
- 库存预警：库存低于预警阈值时显示。
- 用户管理：管理员可创建用户、启用或停用用户。

## 技术栈

前端：

- Vue 3
- Vite
- Bootstrap 5
- Chart.js
- Font Awesome
- Axios
- Nginx

后端：

- Java 17
- Spring Boot 3
- Spring Cloud Gateway
- Spring Cloud Netflix Eureka
- Spring Cloud Config
- Spring Cloud OpenFeign
- Spring Data JPA
- MySQL 8

部署与工程：

- Docker Desktop / Docker Engine
- Docker Compose
- Kubernetes（可选，`k8s/` 目录）
- GitHub Actions CI/CD
- GitHub Container Registry（GHCR）构建并发布镜像
- 虚拟机多节点 Kubernetes 自动部署
- Gateway 令牌桶限流
- Resilience4j 熔断降级

## 项目架构

```text
浏览器
  │  http://localhost:30081
  ▼
frontend-nginx (Vue 3 静态文件 + 反向代理)
  │  /api/* → gateway-service:8080
  ▼
gateway-service (Spring Cloud Gateway)
  │  服务发现（Eureka）+ JWT 鉴权
  ├─▶ user-service    :8081  登录 / 用户管理
  ├─▶ product-service :8082  商品管理
  ├─▶ stock-service   :8083  库存管理
  └─▶ order-service   :8084  入库 / 出库流水
          │
          ▼
        MySQL 8

eureka-service  :8761  服务注册中心
config-service  :8888  配置中心（native 模式挂载 config-repo/）
```

## 目录结构

```text
StockMaster/
├── backend/                  # Spring Cloud 微服务源码
│   ├── eureka-service/        # 服务注册中心
│   ├── config-service/        # 配置中心
│   ├── gateway-service/       # API 网关
│   ├── user-service/          # 用户认证与用户管理
│   ├── product-service/       # 商品管理
│   ├── stock-service/         # 库存管理
│   ├── order-service/         # 入库/出库流水
│   └── stockmaster-common/    # 公共响应、JWT 工具
├── config-repo/               # 配置中心本地配置仓库
├── frontend/                  # Vue 3 + Bootstrap 前端
├── k8s/                       # Kubernetes 部署清单
│   ├── namespace.yaml
│   ├── mysql/
│   │   ├── mysql.yaml
│   │   └── init.sql
│   ├── services/
│   │   ├── base-config.yaml   # ConfigMap + Secret
│   │   └── apps.yaml          # 所有服务 Deployment + Service
│   └── apply-all.sh
├── scripts/
│   └── export-images.sh       # 一键导出离线镜像包
├── docker-compose.yml         # Docker Compose 部署文件
└── .github/workflows/         # GitHub Actions CI/CD
```

## 默认账号

```text
用户名：admin
密码：admin123
角色：admin
```

## 端口说明

| 服务 | 宿主机端口 | 容器端口 | 说明 |
| --- | ---: | ---: | --- |
| frontend-nginx | 30081 | 80 | 前端页面入口 |
| gateway-service | 8080 | 8080 | 后端 API 网关 |
| eureka-service | 8761 | 8761 | 服务注册中心控制台 |
| config-service | 8888 | 8888 | 配置中心 |
| mysql | 13306 | 3306 | MySQL 数据库 |
| user-service | 不暴露 | 8081 | 用户服务 |
| product-service | 不暴露 | 8082 | 商品服务 |
| stock-service | 不暴露 | 8083 | 库存服务 |
| order-service | 不暴露 | 8084 | 订单/流水服务 |

访问地址：

- 前端页面：http://localhost:30081
- API 网关：http://localhost:8080
- Eureka 控制台：http://localhost:8761
- Config Server：http://localhost:8888
- MySQL：`127.0.0.1:13306`，用户 `root`，密码 `root`

---

## 部署方式

本项目支持多种部署方式，按需选择：

| 方式 | 适用场景 | 需要什么 |
| --- | --- | --- |
| **0. 单文件安装（在线）** | 一个脚本，有网络自动拉取镜像 | 只需 Docker |
| **0. 单文件安装（离线）** | 一个脚本 + 一个镜像包，无需网络 | 只需 Docker |
| A. 本地构建 + Docker Compose | 开发调试、首次部署 | Java + Maven + Node |
| B. GHCR 预构建镜像 + Docker Compose | 有网络的生产/演示环境 | 只需 Docker |
| C. 离线镜像包 + Docker Compose | 无外网机器、内网部署 | 只需 Docker |
| D. Kubernetes 部署 | 多节点集群环境 | kubectl + 集群 |

---

## 单文件安装

提供两个版本，根据系统选择：

| 脚本 | 适用系统 |
| --- | --- |
| `scripts/install.sh` | macOS / Linux / Windows WSL2 / Windows Git Bash |
| `scripts/install.ps1` | Windows PowerShell（原生，无需任何额外工具） |

两个脚本功能完全相同：内嵌所有配置文件（config-repo、init.sql、docker-compose），一条命令完成全部配置和启动。

---

### macOS / Linux 用法

**在线模式（有网络）：**

```bash
bash install.sh
```

**离线模式（无外网）：**

```bash
bash install.sh --offline ./stockmaster-images.tar.gz
```

---

### Windows 用法

Windows 上只需安装 **Docker Desktop for Windows**（WSL2 后端）。

**在线模式（有网络）：**

以管理员身份打开 PowerShell，执行：

```powershell
powershell -ExecutionPolicy Bypass -File install.ps1
```

**离线模式（无外网）：**

```powershell
powershell -ExecutionPolicy Bypass -File install.ps1 -Offline .\stockmaster-images.tar.gz
```

> **注意**：`-ExecutionPolicy Bypass` 仅对本次执行有效，不会修改系统策略。

#### Windows 使用 bash 脚本（可选）

如果已安装 **Git for Windows** 或 **WSL2**，也可以直接运行 bash 版本：

```bash
# Git Bash 或 WSL2 终端中
bash install.sh
bash install.sh --offline ./stockmaster-images.tar.gz
```

---

### 安装后管理

```bash
cd stockmaster                  # 安装脚本创建的工作目录
docker compose ps               # 查看状态
docker compose logs -f          # 查看日志
docker compose down             # 停止
docker compose up -d            # 重新启动
```

---

## 自动更新（代码推送后自动部署）

部署完成后，每次将代码推送到 GitHub，系统会自动同步最新版本，无需手动干预。

### 原理

```text
git push → GitHub Actions 构建新镜像 → 推送到 GHCR
                                              ↓
                                        Watchtower（每 5 分钟检查一次）
                                              ↓
                                        发现新镜像 → 自动拉取 → 重启对应容器
```

### 启用方式

**安装时直接启用（推荐）：**

```bash
# macOS / Linux
bash install.sh --watch

# Windows PowerShell
powershell -ExecutionPolicy Bypass -File install.ps1 -Watch
```

**已经安装后追加启用：**

```bash
cd stockmaster
docker compose -f docker-compose.yml -f docker-compose.watch.yml up -d watchtower
```

或者直接使用项目根目录里的 `docker-compose.watch.yml`：

```bash
docker compose -f docker-compose.yml -f docker-compose.watch.yml up -d
```

### 私有 GHCR 仓库的授权

如果 GitHub 仓库是私有的，Watchtower 拉取镜像前需要登录 GHCR。在部署机器上执行一次：

```bash
docker login ghcr.io -u <GitHub用户名> -p <GITHUB_TOKEN>
```

`GITHUB_TOKEN` 在 GitHub 个人设置 → Developer settings → Personal access tokens 中生成，需要 `read:packages` 权限。

登录后 Docker 会把凭据保存在本地，Watchtower 自动复用，无需再次配置。

### 查看 Watchtower 日志

```bash
docker logs -f stockmaster-watchtower
```

正常输出示例：

```text
time="..." level=info msg="Found new ghcr.io/terrorawm/stockmaster-gateway-service:latest image"
time="..." level=info msg="Stopping stockmaster-gateway (old image)"
time="..." level=info msg="Starting stockmaster-gateway (new image)"
```

### 关闭自动更新

```bash
docker stop stockmaster-watchtower
docker rm stockmaster-watchtower
```

### 调整检查间隔

默认 5 分钟检查一次。修改间隔：在 `stockmaster/` 目录下创建 `.env` 文件：

```bash
echo "WATCHTOWER_INTERVAL=600" > .env   # 改为 10 分钟
docker compose -f docker-compose.yml -f docker-compose.watch.yml up -d watchtower
```

---

## 方式 A：本地构建 + Docker Compose

### 前置要求

```bash
docker --version        # Docker Desktop 或 Docker Engine
docker compose version  # v2.x
java -version           # Java 17
mvn -version            # Maven 3.9+
node -v                 # Node.js 20+
npm -v
```

### 步骤

**1. 构建后端 JAR**

```bash
cd backend
mvn -DskipTests package
cd ..
```

**2. 启动全部服务**

```bash
docker compose up -d --build
```

首次启动会构建所有镜像，约需 3-5 分钟。

**3. 查看容器状态**

```bash
docker compose ps
```

正常状态下所有容器应为 `Up`：

```text
stockmaster-mysql
stockmaster-eureka
stockmaster-config
stockmaster-gateway
stockmaster-user
stockmaster-product
stockmaster-stock
stockmaster-order
stockmaster-frontend
```

**4. 打开系统**

浏览器访问 http://localhost:30081，使用 `admin / admin123` 登录。

---

## 方式 B：GHCR 预构建镜像 + Docker Compose

GitHub Actions 在每次 push 到 `main` 时自动构建镜像并推送到 GHCR，无需本地编译即可启动。

### GHCR 镜像列表

```text
ghcr.io/terrorawm/stockmaster-eureka-service:latest
ghcr.io/terrorawm/stockmaster-config-service:latest
ghcr.io/terrorawm/stockmaster-gateway-service:latest
ghcr.io/terrorawm/stockmaster-user-service:latest
ghcr.io/terrorawm/stockmaster-product-service:latest
ghcr.io/terrorawm/stockmaster-stock-service:latest
ghcr.io/terrorawm/stockmaster-order-service:latest
ghcr.io/terrorawm/stockmaster-frontend-nginx:latest
```

### 步骤

**1. 登录 GHCR**（仓库为私有时需要）

```bash
echo <GITHUB_TOKEN> | docker login ghcr.io -u <GITHUB_USERNAME> --password-stdin
```

公开仓库可跳过此步骤。

**2. 拉取全部镜像**

```bash
for svc in eureka-service config-service gateway-service user-service product-service stock-service order-service; do
  docker pull ghcr.io/terrorawm/stockmaster-${svc}:latest
done
docker pull ghcr.io/terrorawm/stockmaster-frontend-nginx:latest
docker pull mysql:8.0
```

**3. 为镜像打本地标签**（与 docker-compose.yml 中的 `image:` 字段保持一致）

```bash
for svc in eureka-service config-service gateway-service user-service product-service stock-service order-service; do
  docker tag ghcr.io/terrorawm/stockmaster-${svc}:latest stockmaster/${svc}:local
done
docker tag ghcr.io/terrorawm/stockmaster-frontend-nginx:latest stockmaster/frontend-nginx:local
```

**4. 启动（跳过构建）**

```bash
docker compose up -d
```

不加 `--build` 时 Docker Compose 直接使用已有的本地镜像。

---

## 方式 C：离线镜像包导入 + Docker Compose

适用于目标机器无法访问外网的场景。

### 在有网络的机器上打包

**前置条件**：已完成方式 A 或方式 B，本地镜像已就绪（`docker images | grep stockmaster` 能看到所有服务镜像）。

**一键生成完整离线包（推荐）**

```bash
bash scripts/package-offline.sh
```

脚本会自动完成：镜像导出 → 打包配置文件 → 生成启动脚本，最终输出：

```text
stockmaster-offline.tar.gz   (~1.5-2 GB)
```

内部结构：

```text
stockmaster-offline/
├── README.txt              # 快速启动说明
├── start.sh                # 一键启动脚本
├── stop.sh                 # 一键停止脚本
├── docker-compose.yml
├── config-repo/
├── k8s/mysql/init.sql
└── docker-images/
    └── stockmaster-images.tar.gz
```

将 `stockmaster-offline.tar.gz` 传输到目标机器（U 盘、内网共享、网盘等）。

### 目标机器操作步骤

目标机器只需安装 Docker，无需 Java、Maven、Node.js。

**只需三条命令：**

```bash
tar -xzf stockmaster-offline.tar.gz
cd stockmaster-offline
bash start.sh
```

`start.sh` 会自动导入镜像并启动所有服务，完成后打印访问地址：

```text
============================================
 StockMaster is ready!
 URL:      http://localhost:30081
 Account:  admin / admin123
============================================
```

停止服务：

```bash
bash stop.sh
```

---

## 方式 D：Kubernetes 部署

使用 `k8s/` 目录中的清单部署到虚拟机多节点 Kubernetes 集群。完整搭建步骤见 `docs/K8S-VM-GUIDE.md`。

### 前置要求

- `kubectl` 已配置集群连接
- 集群节点可访问 GHCR（或已通过 `docker load` 导入镜像，并将 `imagePullPolicy` 改为 `IfNotPresent`）

### 步骤

**1. 一键部署**

```bash
cd k8s
bash apply-all.sh
```

等价于依次执行：

```bash
kubectl apply -k .
```

**2. 查看 Pod 状态**

```bash
kubectl get pods -n stockmaster -w
```

**3. 访问地址（NodePort）**

| 服务 | NodePort |
| --- | --- |
| 前端页面 | http://\<Node-IP\>:30081 |
| API 网关 | http://\<Node-IP\>:30080 |
| Eureka 控制台 | http://\<Node-IP\>:30761 |

### k8s 关键配置

| 文件 | 说明 |
| --- | --- |
| `k8s/namespace.yaml` | 创建 `stockmaster` 命名空间 |
| `k8s/mysql/mysql.yaml` | MySQL StatefulSet + 8Gi PVC + Service |
| `k8s/services/base-config.yaml` | ConfigMap（环境变量）+ Secret（密码、JWT 密钥） |
| `k8s/services/apps.yaml` | 所有微服务 Deployment + Service |

config-service 在 K8s 模式下通过 ConfigMap 挂载本仓库的 `config-repo/` 配置，不依赖运行时访问 GitHub。修改密钥：

```bash
kubectl edit secret stockmaster-secret -n stockmaster
```

---

## 常用 Docker Compose 命令

```bash
# 启动（使用已有镜像，不重新构建）
docker compose up -d

# 重新构建并启动
docker compose up -d --build

# 查看所有服务日志
docker compose logs -f

# 查看某个服务日志
docker compose logs -f gateway-service
docker compose logs -f order-service
docker compose logs -f frontend-nginx

# 重启某个服务
docker compose restart gateway-service

# 停止所有服务
docker compose down

# 停止并删除数据库卷（数据清空）
docker compose down -v
```

注意：`docker compose down -v` 会删除 MySQL 数据，慎用。

---

## API 快速验证

**登录接口：**

```bash
curl -s -X POST http://127.0.0.1:30081/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123"}'
```

返回 JSON 包含 `token` 字段，说明登录和前后端代理正常。

**带 Token 请求商品列表：**

```bash
TOKEN="<替换为登录接口返回的 token>"

curl -s http://127.0.0.1:30081/api/products \
  -H "Authorization: Bearer $TOKEN"
```

---

## 本地开发

### 后端开发

```bash
cd backend

# 构建全部模块
mvn -DskipTests package

# 只构建某个模块（含依赖）
mvn -pl product-service -am -DskipTests package
```

### 前端开发

```bash
cd frontend
npm install
npm run dev      # 开发服务器（热更新）
npm run build    # 生产构建，输出到 dist/
```

生产环境由 Nginx 容器托管 `dist/`，并将 `/api/*` 反向代理到 `gateway-service:8080`。

---

## 配置说明

### Docker Compose 主要环境变量

| 变量 | 默认值 | 说明 |
| --- | --- | --- |
| `JWT_SECRET` | `stockmaster-docker-secret` | JWT 签名密钥，生产环境请替换 |
| `MYSQL_USER` | `root` | MySQL 用户名 |
| `MYSQL_PASSWORD` | `root` | MySQL 密码，生产环境请替换 |
| `USER_DB_URL` | `jdbc:mysql://mysql:3306/stockmaster_user...` | 用户服务数据库连接 |
| `PRODUCT_DB_URL` | `jdbc:mysql://mysql:3306/stockmaster_product...` | 商品服务数据库连接 |
| `STOCK_DB_URL` | `jdbc:mysql://mysql:3306/stockmaster_stock...` | 库存服务数据库连接 |
| `ORDER_DB_URL` | `jdbc:mysql://mysql:3306/stockmaster_order...` | 订单服务数据库连接 |

### config-repo 配置中心

`config-repo/` 目录下每个文件对应一个微服务的配置：

```text
config-repo/
├── gateway-service.yml    # 路由规则、JWT 密钥、Eureka 地址
├── user-service.yml       # 数据库、JWT、Eureka
├── product-service.yml    # 数据库、Eureka
├── stock-service.yml      # 数据库、Eureka
└── order-service.yml      # 数据库、Eureka
```

Docker Compose 通过 volume 挂载将目录暴露给 config-service（native 模式），无需额外 Git 仓库：

```yaml
volumes:
  - ./config-repo:/app/config-repo:ro
```

修改配置后重启相关服务生效：

```bash
docker compose restart config-service gateway-service user-service product-service stock-service order-service
```

### 修改端口

编辑 `docker-compose.yml` 中的 `ports` 字段，例如将前端改为 `8090`：

```yaml
frontend-nginx:
  ports:
    - "8090:80"
```

---

## GitHub Actions CI/CD

| 文件 | 触发方式 | 说明 |
| --- | --- | --- |
| `.github/workflows/ci.yml` | push / pull_request → main | 构建后端 Maven 项目 + 前端 Vite 项目 |
| `.github/workflows/images.yml` | push → main / 手动触发 | 构建各微服务 Docker 镜像并推送到 GHCR |
| `.github/workflows/compose-check.yml` | 手动触发 | 构建后端 JAR + 校验 `docker compose config` |

镜像推送使用仓库自带的 `GITHUB_TOKEN`，无需额外配置 Docker 凭据。私有仓库 Actions 会消耗 GitHub 账号的免费分钟数，公开仓库免费。

---

## 常见问题

### 前端登录 502

通常是 Nginx 解析到旧容器地址，重启即可：

```bash
docker compose restart frontend-nginx gateway-service
```

### 入库/出库 500

查看相关服务日志排查：

```bash
docker compose logs --tail=100 order-service
docker compose logs --tail=100 product-service
docker compose logs --tail=100 stock-service
```

### 端口被占用

修改 `docker-compose.yml` 中冲突服务的 `ports`（左侧为宿主机端口）：

```yaml
ports:
  - "30081:80"   # 改为未占用的端口，如 "8090:80"
```

### MySQL 数据重置

```bash
docker compose down -v
docker compose up -d
```

执行后数据库会重新执行 `k8s/mysql/init.sql` 初始化。

### 服务启动顺序问题

依赖关系：`mysql（健康）→ eureka → config → 各业务服务 → gateway → frontend`

若某服务启动失败，等待 30 秒后重试：

```bash
docker compose restart <service-name>
```

### 离线导入后找不到镜像

确保导入时包含所有镜像，且标签与 `docker-compose.yml` 中 `image:` 字段一致（均为 `stockmaster/*:local`）。

```bash
# 验证镜像是否导入成功
docker images | grep -E "stockmaster|mysql"
```
