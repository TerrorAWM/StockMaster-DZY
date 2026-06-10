# 云原生实践验收清单

## 验收前检查

```bash
kubectl get nodes -o wide
bash k8s/verify.sh
```

通过标准：

- 至少 2 个虚拟机 Kubernetes 节点为 `Ready`。
- `stockmaster` 命名空间所有 Pod 为 `Running` 且 Ready。
- Gateway、前端、用户、商品、库存、订单服务均为 2 副本。
- 同一服务的副本尽量分布在不同节点。
- MySQL PVC 为 `Bound`。

## CI/CD 展示

在 GitHub Actions 手动运行 `StockMaster CI CD`，依次展开并展示：

1. `1 Test and Package`
2. `2 Build and Push Images`
3. `3 Deploy and Verify Kubernetes`

最后一个阶段需要展示 `kubectl get nodes` 和 `kubectl get pods,deployments,statefulsets,services` 的输出。

## 功能展示

打开 `http://节点IP:30081`，使用 `admin / admin123` 登录并展示：

1. 用户管理。
2. 商品新增、修改和查询。
3. 入库操作。
4. 出库操作。
5. 库存查询、流水和库存预警。
6. Eureka 页面中的微服务注册状态。

## 限流展示

```bash
GATEWAY_URL=http://节点IP:30080 bash scripts/demo-rate-limit.sh
```

连续请求后出现 HTTP `429`，说明 Gateway 限流生效。

## 熔断降级展示

先保证系统中至少存在一个商品，然后执行：

```bash
GATEWAY_URL=http://节点IP:30080 bash scripts/demo-circuit-breaker.sh
```

脚本会临时停止 `product-service`，重复调用订单服务，并展示“商品服务暂时不可用，已触发熔断降级”，随后自动恢复服务。

## 建议的 8 分钟视频顺序

| 时间 | 内容 |
| --- | --- |
| 0:00-0:40 | 本人出镜，介绍项目目标与整体架构 |
| 0:40-1:30 | 展示 2-3 个虚拟机节点和 Kubernetes 资源 |
| 1:30-3:20 | 执行并展开 GitHub Actions 完整流水线 |
| 3:20-4:00 | 展示自动部署后的 Pod、Service 和镜像版本 |
| 4:00-6:30 | 通过前端展示全部业务功能 |
| 6:30-7:10 | 展示 Gateway 限流 |
| 7:10-7:50 | 展示订单服务熔断降级 |
| 7:50-8:00 | 总结项目亮点 |
