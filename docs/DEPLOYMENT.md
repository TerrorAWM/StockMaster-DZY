# StockMaster 部署说明

## 本地构建验证

```bash
cd backend
mvn -DskipTests package

cd ../frontend
npm install
npm run build
```

## Kubernetes 部署顺序

```bash
cd k8s
kubectl apply -f namespace.yaml
kubectl apply -f mysql/mysql.yaml
kubectl apply -f services/base-config.yaml
kubectl apply -f services/apps.yaml
```

访问地址：

- 前端后台：`http://<任意节点IP>:30081`
- Gateway：`http://<任意节点IP>:30080`
- Eureka：`http://<任意节点IP>:30761`

默认账号：

- `admin / admin123`

## GitHub Actions CI/CD

项目使用 GitHub Actions，不再需要 Jenkins。

- `.github/workflows/ci.yml`：push/PR 时构建后端和前端。
- `.github/workflows/images.yml`：push 到 `main` 时构建镜像并推送到 GHCR。
- `.github/workflows/deploy.yml`：手动触发部署，运行在 `k8s-master` 上的 self-hosted runner。

私有库支持 GitHub Actions，但会消耗 GitHub 账号的 Actions 分钟数。镜像推送使用仓库自带的 `GITHUB_TOKEN`，不需要额外配置 Docker 密码。

## 镜像说明

K8s 文件默认使用这些镜像名：

- `ghcr.io/terrorawm/stockmaster-eureka-service:latest`
- `ghcr.io/terrorawm/stockmaster-config-service:latest`
- `ghcr.io/terrorawm/stockmaster-gateway-service:latest`
- `ghcr.io/terrorawm/stockmaster-user-service:latest`
- `ghcr.io/terrorawm/stockmaster-product-service:latest`
- `ghcr.io/terrorawm/stockmaster-stock-service:latest`
- `ghcr.io/terrorawm/stockmaster-order-service:latest`
- `ghcr.io/terrorawm/stockmaster-frontend-nginx:latest`

如果 GHCR package 是私有的，Kubernetes 集群需要配置 `imagePullSecret` 才能拉取镜像。最简单做法是在 GitHub Packages 中把这些镜像改为 public；如果保持 private，则需要创建 GHCR token 并在集群中创建拉取密钥。

## Self-hosted runner

部署 workflow 需要在 `k8s-master` 上安装 GitHub self-hosted runner，并保证：

- runner 标签包含默认的 `self-hosted`。
- `kubectl` 可用。
- 当前用户能访问 Kubernetes 集群。
- `k8s-master` 能访问 `ghcr.io` 拉取镜像。

## Config 配置中心

`config-service` 从当前 GitHub 仓库读取 `config-repo/` 下的配置文件：

```text
CONFIG_GIT_URI=https://github.com/TerrorAWM/StockMaster-DZY.git
CONFIG_GIT_SEARCH_PATHS=config-repo
```

如果 GitHub 私有仓库在集群内无法直接拉取，需要给 Config Server 配置 Git 用户名和 Token，或者把配置仓库改成集群可访问的内部 Git 地址。
