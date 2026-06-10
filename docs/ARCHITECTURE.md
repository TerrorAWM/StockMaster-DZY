# StockMaster 架构说明

## 项目架构

```text
Vue3 管理后台
  ↓
Nginx
  ↓ /api
Spring Cloud Gateway
  ↓
user-service / product-service / order-service / stock-service
  ↓
MySQL
```

基础设施：

- Eureka：服务注册与发现。
- Config Server：从 Git 仓库拉取配置。
- OpenFeign：服务间调用。
- Docker Compose：本地或单服务器编排全部容器。
- GitHub Actions：CI 和 Docker 镜像构建发布。
- GHCR：保存带 Git commit SHA 标签的镜像。
- Kubernetes：在虚拟机集群中运行、恢复和滚动更新服务。
- Gateway 令牌桶：按客户端执行入口限流并返回 HTTP 429。
- Resilience4j：保护订单服务到商品、库存服务的远程调用。

## 自动部署流程

```text
git push
  → GitHub Actions 测试和打包
  → 构建 Docker 镜像并推送 GHCR
  → 使用 KUBE_CONFIG 连接虚拟机 Kubernetes
  → 更新 Deployment 到当前 Git commit SHA 镜像
  → 等待 Rollout 并输出 Node、Pod、Service 状态
```

## 服务职责

- `user-service`：登录、JWT、用户管理、`admin/staff` 双角色。
- `product-service`：商品资料、分类、单位、预警阈值。
- `order-service`：入库单、出库单、库存流水。
- `stock-service`：库存数量、库存变更、库存预警。

## 典型流程

入库：

```text
前端提交入库单 → Gateway → order-service
order-service → product-service 校验商品
order-service → stock-service 增加库存
order-service 保存入库流水
```

出库：

```text
前端提交出库单 → Gateway → order-service
order-service → product-service 校验商品
order-service → stock-service 扣减库存
库存不足则返回业务错误
order-service 保存出库流水
```
