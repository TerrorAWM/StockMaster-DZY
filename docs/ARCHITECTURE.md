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
- Kubernetes：Pod 编排、Service 暴露、MySQL 持久化。
- GitHub Actions：CI、镜像构建发布、触发 K8s 部署。

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
