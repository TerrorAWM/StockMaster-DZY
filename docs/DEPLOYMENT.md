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

## 镜像说明

K8s 文件默认使用这些镜像名：

- `stockmaster/eureka-service:latest`
- `stockmaster/config-service:latest`
- `stockmaster/gateway-service:latest`
- `stockmaster/user-service:latest`
- `stockmaster/product-service:latest`
- `stockmaster/stock-service:latest`
- `stockmaster/order-service:latest`
- `stockmaster/frontend-nginx:latest`

如果推送到 Harbor 或 Docker Hub，需要替换 `k8s/services/apps.yaml` 中的镜像地址。

## Config 配置中心

`config-service` 从当前 GitHub 仓库读取 `config-repo/` 下的配置文件：

```text
CONFIG_GIT_URI=https://github.com/TerrorAWM/StockMaster-DZY.git
CONFIG_GIT_SEARCH_PATHS=config-repo
```

如果 GitHub 私有仓库在集群内无法直接拉取，需要给 Config Server 配置 Git 用户名和 Token，或者把配置仓库改成集群可访问的内部 Git 地址。

