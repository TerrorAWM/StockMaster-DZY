# StockMaster 部署说明

## 本地构建验证

```bash
cd backend
mvn -DskipTests package

cd ../frontend
npm install
npm run build
```

## Docker Compose 部署顺序

```bash
cd backend
mvn -DskipTests package

cd ..
docker compose up -d --build
```

访问地址：

- 前端后台：`http://localhost:30081`
- Gateway：`http://localhost:8080`
- Eureka：`http://localhost:8761`
- Config：`http://localhost:8888`
- MySQL：`127.0.0.1:13306`，用户 `root`，密码 `root`

默认账号：

- `admin / admin123`

## GitHub Actions CI/CD

项目使用 GitHub Actions，不需要 Jenkins，也不要求虚拟机 Kubernetes。

- `.github/workflows/ci.yml`：push/PR 时构建后端和前端。
- `.github/workflows/images.yml`：push 到 `main` 时构建镜像并推送到 GHCR。
- `.github/workflows/compose-check.yml`：手动触发，校验 Docker Compose 配置。

私有库支持 GitHub Actions，但会消耗 GitHub 账号的 Actions 分钟数。镜像推送使用仓库自带的 `GITHUB_TOKEN`，不需要额外配置 Docker 密码。

## 镜像说明

GitHub Actions 会构建并推送这些 Docker 镜像：

- `ghcr.io/terrorawm/stockmaster-eureka-service:latest`
- `ghcr.io/terrorawm/stockmaster-config-service:latest`
- `ghcr.io/terrorawm/stockmaster-gateway-service:latest`
- `ghcr.io/terrorawm/stockmaster-user-service:latest`
- `ghcr.io/terrorawm/stockmaster-product-service:latest`
- `ghcr.io/terrorawm/stockmaster-stock-service:latest`
- `ghcr.io/terrorawm/stockmaster-order-service:latest`
- `ghcr.io/terrorawm/stockmaster-frontend-nginx:latest`

如果 GHCR package 是私有的，其他机器 `docker pull` 前需要先登录：

```bash
echo <GITHUB_TOKEN> | docker login ghcr.io -u <GITHUB_USERNAME> --password-stdin
```

## Docker Compose 说明

`docker-compose.yml` 会启动：

- MySQL 8.0
- Eureka
- Config Server
- Gateway
- user/product/order/stock 微服务
- Vue 前端 Nginx

Config Server 在 Docker Compose 中使用 `native` 模式，直接挂载本仓库的 `config-repo/` 目录，不需要额外创建 Git 配置仓库。

## Config 配置中心

Docker Compose 部署时，`config-service` 通过挂载目录读取 `config-repo/` 下的配置文件：

```text
SPRING_PROFILES_ACTIVE=native
SPRING_CLOUD_CONFIG_SERVER_NATIVE_SEARCH_LOCATIONS=file:/app/config-repo
```

这样不依赖额外的 Git 配置仓库，也不需要在容器里配置 GitHub Token。
