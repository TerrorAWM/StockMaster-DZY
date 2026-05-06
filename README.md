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
- GitHub Actions CI/CD
- GitHub Container Registry 构建镜像

## 项目架构

```text
前端浏览器
  |
  | http://localhost:30081
  v
frontend-nginx
  |
  | /api/*
  v
gateway-service
  |
  | 服务发现
  v
eureka-service
  |
  +--> user-service
  +--> product-service
  +--> stock-service
  +--> order-service
          |
          v
        MySQL

config-service 从 config-repo 读取各服务配置。
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
├── k8s/mysql/init.sql         # MySQL 初始化脚本
├── docker-compose.yml         # Docker Compose 部署文件
├── .github/workflows/         # GitHub Actions CI/CD
└── docs/                      # 额外部署说明
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
- MySQL：`127.0.0.1:13306`

MySQL 默认连接：

```text
host: 127.0.0.1
port: 13306
user: root
password: root
```

## 使用 Docker Compose 启动

### 1. 准备环境

推荐使用 Docker Desktop。

需要安装：

- Docker Desktop
- Java 17
- Maven 3.9+
- Node.js 20+

检查命令：

```bash
docker --version
docker compose version
java -version
mvn -version
node -v
npm -v
```

### 2. 构建后端 JAR

```bash
cd backend
mvn -DskipTests package
cd ..
```

### 3. 启动全部服务

```bash
docker compose up -d --build
```

### 4. 查看容器状态

```bash
docker compose ps
```

正常情况下应看到这些容器处于 `Up` 状态：

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

### 5. 打开系统

浏览器访问：

```text
http://localhost:30081
```

使用默认账号登录：

```text
admin / admin123
```

## 常用 Docker 命令

启动：

```bash
docker compose up -d
```

重新构建并启动：

```bash
docker compose up -d --build
```

查看日志：

```bash
docker compose logs -f
```

查看某个服务日志：

```bash
docker compose logs -f gateway-service
docker compose logs -f product-service
docker compose logs -f frontend-nginx
```

停止服务：

```bash
docker compose down
```

停止并删除数据库卷：

```bash
docker compose down -v
```

注意：`docker compose down -v` 会删除 MySQL 数据，慎用。

## API 快速验证

登录：

```bash
curl -s -X POST http://127.0.0.1:30081/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123"}'
```

如果返回里包含 `token`，说明登录和前后端代理正常。

商品列表需要带 Token：

```bash
TOKEN="替换成登录接口返回的 token"

curl -s http://127.0.0.1:30081/api/products \
  -H "Authorization: Bearer $TOKEN"
```

## 本地开发

### 后端开发

后端使用 Maven 多模块工程：

```bash
cd backend
mvn -DskipTests package
```

如果只想重新构建某个模块：

```bash
cd backend
mvn -pl product-service -am -DskipTests package
```

### 前端开发

```bash
cd frontend
npm install
npm run dev
```

前端生产构建：

```bash
cd frontend
npm run build
```

生产环境由 Nginx 容器托管前端静态文件，API 通过 `/api/*` 反向代理到 `gateway-service:8080`。

## 配置说明

Docker Compose 中主要配置项：

```yaml
JWT_SECRET: stockmaster-docker-secret
MYSQL_USER: root
MYSQL_PASSWORD: root
USER_DB_URL: jdbc:mysql://mysql:3306/stockmaster_user...
PRODUCT_DB_URL: jdbc:mysql://mysql:3306/stockmaster_product...
STOCK_DB_URL: jdbc:mysql://mysql:3306/stockmaster_stock...
ORDER_DB_URL: jdbc:mysql://mysql:3306/stockmaster_order...
```

配置中心使用本地目录：

```text
config-repo/
```

Compose 中挂载方式：

```yaml
./config-repo:/app/config-repo:ro
```

如果修改 `config-repo` 下的配置，建议重启相关服务：

```bash
docker compose restart config-service gateway-service user-service product-service stock-service order-service
```

## GitHub Actions CI/CD

仓库包含 3 个工作流：

- `.github/workflows/ci.yml`
  - push 或 pull request 时执行。
  - 构建后端 Maven 项目。
  - 构建前端 Vite 项目。

- `.github/workflows/images.yml`
  - push 到 `main` 或手动触发时执行。
  - 构建各微服务 Docker 镜像。
  - 推送到 GitHub Container Registry。

- `.github/workflows/compose-check.yml`
  - 手动触发。
  - 构建后端 JAR。
  - 校验 `docker compose config`。

私有仓库也支持 GitHub Actions。镜像推送使用仓库自带的 `GITHUB_TOKEN`，需要仓库 Actions 权限和 Packages 权限可用。

## Docker 镜像导出与导入

导出当前本地镜像：

```bash
mkdir -p docker-images

docker save \
  mysql:8.0 \
  stockmaster/eureka-service:local \
  stockmaster/config-service:local \
  stockmaster/gateway-service:local \
  stockmaster/user-service:local \
  stockmaster/product-service:local \
  stockmaster/stock-service:local \
  stockmaster/order-service:local \
  stockmaster/frontend-nginx:local \
  -o docker-images/stockmaster-images.tar
```

压缩离线包：

```bash
gzip -f docker-images/stockmaster-images.tar
```

导入镜像：

```bash
gunzip -c docker-images/stockmaster-images.tar.gz | docker load
```

导入后启动：

```bash
docker compose up -d
```

如果目标机器没有源码或没有 JAR 文件，则仍建议使用本仓库完整目录，因为 `docker-compose.yml` 需要读取 `config-repo` 和 MySQL 初始化 SQL。

## 常见问题

### 1. 前端登录 502

通常是 Nginx 或网关解析到了旧容器地址。执行：

```bash
docker compose restart frontend-nginx gateway-service
```

### 2. 入库/出库 500

先查看订单、商品、库存服务日志：

```bash
docker compose logs --tail=100 order-service
docker compose logs --tail=100 product-service
docker compose logs --tail=100 stock-service
```

### 3. 端口被占用

当前默认端口：

- 前端：`30081`
- 网关：`8080`
- MySQL：`13306`

如需修改，编辑 `docker-compose.yml` 中的 `ports`。

### 4. MySQL 数据想重置

```bash
docker compose down -v
docker compose up -d --build
```

这会清空数据库并重新执行 `k8s/mysql/init.sql`。

## 当前部署入口

```text
前端页面：http://localhost:30081
默认账号：admin / admin123
```
