# 虚拟机 Kubernetes 集群部署指南

## 推荐拓扑

准备 3 台 Ubuntu 22.04/24.04 虚拟机，保证主机名和 IP 不重复，并且节点之间网络互通。

| 节点 | 示例 IP | 角色 | 建议资源 |
| --- | --- | --- | --- |
| k8s-control | 192.168.1.101 | control-plane | 2 CPU / 4 GB |
| k8s-worker-1 | 192.168.1.102 | worker | 2 CPU / 4 GB |
| k8s-worker-2 | 192.168.1.103 | worker | 2 CPU / 4 GB |

资源不足时，可以只使用一个 control-plane 和一个 worker。

## 1. 安装所有节点

将仓库放到每台虚拟机，在三台机器分别执行：

```bash
cd StockMaster
sudo bash scripts/k8s/install-node.sh
```

脚本会关闭 swap，安装并配置 containerd、kubelet、kubeadm 和 kubectl。

## 2. 初始化控制节点

只在 `k8s-control` 执行：

```bash
sudo CONTROL_PLANE_IP=192.168.1.101 bash scripts/k8s/init-control-plane.sh
```

保存脚本最后输出的 `kubeadm join ...` 命令。

## 3. 加入工作节点

在每台 worker 上使用 root 权限执行上一步输出的 `kubeadm join ...` 命令。

然后在控制节点确认：

```bash
kubectl get nodes -o wide
```

所有节点必须为 `Ready`。

## 4. 准备存储和镜像

项目默认提供 `stockmaster-local` 本地 PersistentVolume，使裸 `kubeadm` 集群无需额外存储插件也能完成课程演示：

```bash
kubectl get pv,pvc -A
```

本地卷数据位于 MySQL Pod 所在节点的 `/var/lib/stockmaster-mysql`。它适合课程验收，但不是生产级高可用存储；生产环境应替换为 Longhorn、Ceph 或云盘 CSI。

确保 GHCR 中的 `stockmaster-*` 镜像为公开镜像。若使用私有镜像，执行：

```bash
GHCR_USERNAME=你的GitHub用户名 \
GHCR_TOKEN=具有read:packages权限的Token \
bash k8s/create-ghcr-secret.sh
```

## 5. 首次部署

```bash
bash k8s/apply-all.sh
```

验证：

```bash
bash k8s/verify.sh
```

访问地址：

- 前端：`http://任意节点IP:30081`
- Gateway：`http://任意节点IP:30080`
- Eureka：`http://任意节点IP:30761`

## 6. 配置 GitHub Actions 自动部署

在控制节点生成 kubeconfig 的 Base64 值：

```bash
bash scripts/k8s/export-kubeconfig-secret.sh
```

在 GitHub 仓库中创建：

1. Environment：`production`
2. Environment secret：`KUBE_CONFIG`
3. Secret 内容：脚本输出的完整 Base64 字符串

GitHub Actions 执行器必须能够访问 Kubernetes API Server。可以让 API Server 安全地对 GitHub Hosted Runner 可达，或在控制节点安装带 `k8s` 标签的 GitHub Actions Self-hosted Runner，并将部署任务的 `runs-on` 改为 `[self-hosted, linux, k8s]`。不要直接将 `6443` 端口无访问控制地暴露到公网。

推送到 `main` 后，`StockMaster CI CD` 流水线会依次执行：

```text
测试与打包 → 构建并推送镜像 → 部署到 Kubernetes → 等待 Rollout → 输出节点和 Pod 状态
```

部署阶段使用 Git commit SHA 作为镜像标签，确保每次部署的版本可追踪且不会继续使用旧镜像。
