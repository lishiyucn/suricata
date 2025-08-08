# Suricata Docker 镜像

高性能网络入侵检测和防护引擎的官方 Docker 容器化部署方案。

## 🏷️ 镜像标签 (Suricata 版本)

### 主要版本标签
- **latest**: 最新稳定版本 (当前 8.0)
- **8.0**: 最新 8.0 补丁版本  
- **7.0**: 最新 7.0 补丁版本
- **master**: Git 主分支最新代码 (开发版)

### 特定版本标签
支持 4.1.5 及更新版本的具体版本标签。

**拉取示例**:
```bash
docker pull jasonish/suricata:latest
docker pull jasonish/suricata:8.0
docker pull jasonish/suricata:7.0.11
```

### 多架构支持
默认标签为多架构镜像清单，Docker 会自动选择合适的架构。如需指定架构：

```bash
# AMD64 架构
docker pull jasonish/suricata:latest-amd64

# ARM64 架构  
docker pull jasonish/suricata:latest-arm64v8
```

**支持的架构**:
- **AMD64** (x86_64): 包含 Hyperscan 高性能模式匹配
- **ARM64** (aarch64): 针对 ARM 处理器优化

## 📦 镜像仓库

除 Docker Hub 外，镜像还发布到以下注册中心：

```bash
# Quay.io
docker pull quay.io/jasonish/suricata:latest

# GitHub Container Registry
docker pull ghcr.io/jasonish/suricata:latest
```

## 🚀 快速使用

### 基本网络监控
监控主机网络接口（推荐方式）：

```bash
# 基本 IDS 模式
docker run --rm -it --net=host \
    --cap-add=net_admin --cap-add=net_raw --cap-add=sys_nice \
    jasonish/suricata:latest -i eth0
```

### 带日志挂载
将日志目录挂载到主机以便查看：

```bash
docker run --rm -it --net=host \
    --cap-add=net_admin --cap-add=net_raw --cap-add=sys_nice \
    -v $(pwd)/logs:/var/log/suricata \
    jasonish/suricata:latest -i eth0
```

### IPS 模式（实时阻断）
```bash
# NFQueue 模式 (需要 iptables 规则配合)
docker run --rm -it --net=host \
    --cap-add=net_admin --cap-add=net_raw --cap-add=sys_nice \
    jasonish/suricata:latest -q 0

# AF_PACKET 模式
docker run --rm -it --net=host \
    --cap-add=net_admin --cap-add=net_raw --cap-add=sys_nice \
    jasonish/suricata:latest --af-packet
```

### PCAP 文件分析
```bash
# 离线分析 PCAP 文件
docker run --rm -it \
    -v $(pwd):/data \
    jasonish/suricata:latest -r /data/traffic.pcap
```

## 🔒 容器权限和安全

### 权限说明
容器会尝试以非 root 用户运行 Suricata 以提高安全性。监控网络接口需要以下权限：

- **net_admin**: 网络管理权限
- **net_raw**: 原始套接字访问权限  
- **sys_nice**: 进程优先级调整权限

如果检测到缺少权限，Suricata 将回退为 root 用户运行（带警告）。

### Docker 示例
```bash
docker run --rm -it --net=host \
    --cap-add=net_admin --cap-add=net_raw --cap-add=sys_nice \
    jasonish/suricata:latest -i eth0
```

### Podman 示例
```bash
# Podman 必须显式添加权限
sudo podman run --rm -it --net=host \
    --cap-add=net_admin,net_raw,sys_nice \
    jasonish/suricata:latest -i eth0
```

### 用户权限映射
支持通过环境变量设置容器内用户的 UID/GID：

```bash
docker run --rm -it --net=host \
    -e PUID=$(id -u) -e PGID=$(id -g) \
    --cap-add=net_admin --cap-add=net_raw --cap-add=sys_nice \
    jasonish/suricata:latest -i eth0
```

## 📝 日志管理

### 日志目录
`/var/log/suricata` 目录作为卷挂载点暴露，可供其他容器访问：

**基本日志挂载**：
```bash
# 日志挂载到主机
docker run --rm -it --net=host \
    -v $(pwd)/logs:/var/log/suricata \
    --cap-add=net_admin --cap-add=net_raw --cap-add=sys_nice \
    jasonish/suricata:latest -i eth0
```

**容器间日志共享**：
```bash
# 启动 Suricata 容器（指定名称）
docker run -it --net=host --name=suricata \
    --cap-add=net_admin --cap-add=net_raw --cap-add=sys_nice \
    jasonish/suricata:latest -i eth0

# 启动分析容器共享日志卷
docker run -it --volumes-from=suricata \
    logstash /bin/bash
```

### 日志轮转
内置 `logrotate` 支持自动日志轮转：

**手动轮转**：
```bash
# 执行日志轮转
docker exec CONTAINER_ID logrotate /etc/logrotate.d/suricata

# 测试日志轮转（强制执行+详细输出）
docker exec CONTAINER_ID logrotate -vf /etc/logrotate.d/suricata
```

**自动轮转**：
设置 `ENABLE_CRON=yes` 环境变量并创建 cron 脚本：

```bash
# 启用 cron 服务
docker run -e ENABLE_CRON=yes \
    --cap-add=net_admin --cap-add=net_raw --cap-add=sys_nice \
    jasonish/suricata:latest -i eth0
```

**轮转配置** (`/etc/logrotate.d/suricata`):
```bash
/var/log/suricata/*.log /var/log/suricata/*.json {
    daily
    missingok
    rotate 3
    nocompress
    sharedscripts
    postrotate
        suricatasc -c reopen-log-files
    endscript
}
```

## 📂 卷挂载

### 标准卷目录
Suricata 容器暴露以下卷挂载点：

| 目录 | 用途 | 说明 |
|------|------|------|
| `/var/log/suricata` | 日志目录 | 存储告警、流量日志等 |
| `/var/lib/suricata` | 运行时数据 | 规则缓存、Suricata-Update 数据 |
| `/etc/suricata` | 配置目录 | 主配置文件和规则文件 |

### 配置目录初始化
首次挂载 `/etc/suricata` 时，会自动填充默认配置：

```bash
# 初始化配置目录
mkdir ./etc
docker run --rm -it -v $(pwd)/etc:/etc/suricata \
    jasonish/suricata:latest -V

# 配置文件将生成在 ./etc 目录中
ls ./etc/
# suricata.yaml  rules/  update.yaml  ...
```

### 完整卷挂载示例
```bash
# 创建本地目录
mkdir -p logs lib etc

# 完整挂载运行
docker run --rm -it --net=host \
    -v $(pwd)/logs:/var/log/suricata \
    -v $(pwd)/lib:/var/lib/suricata \
    -v $(pwd)/etc:/etc/suricata \
    -e PUID=$(id -u) -e PGID=$(id -g) \
    --cap-add=net_admin --cap-add=net_raw --cap-add=sys_nice \
    jasonish/suricata:latest -i eth0
```

## ⚙️ 配置管理

### 自定义配置
使用主机绑定挂载提供自定义配置是最简单的方法：

```bash
# 1. 生成默认配置
mkdir ./etc
docker run --rm -it -v $(pwd)/etc:/etc/suricata \
    jasonish/suricata:latest -V

# 2. 编辑配置文件
sudo nano ./etc/suricata.yaml

# 3. 使用自定义配置运行
docker run --rm -it --net=host \
    -v $(pwd)/etc:/etc/suricata \
    --cap-add=net_admin --cap-add=net_raw --cap-add=sys_nice \
    jasonish/suricata:latest -i eth0
```

### 配置文件权限
默认配置文件可能不属于主机用户，需要调整权限：

```bash
# 解决权限问题
sudo chown -R $(id -u):$(id -g) ./etc/

# 或使用 PUID/PGID 环境变量
docker run -e PUID=$(id -u) -e PGID=$(id -g) \
    -v $(pwd)/etc:/etc/suricata \
    jasonish/suricata:latest -V
```

### 关键配置文件

| 文件 | 用途 |
|------|------|
| `suricata.yaml` | 主配置文件 |
| `rules/` | 规则目录 |
| `threshold.config` | 阈值配置 |
| `classification.config` | 分类配置 |
| `reference.config` | 参考配置 |

## 🔧 环境变量

### SURICATA_OPTIONS
通过环境变量传递 Suricata 命令行参数：

```bash
# 详细日志输出
docker run --net=host \
    -e SURICATA_OPTIONS="-i eno1 -vvv" \
    --cap-add=net_admin --cap-add=net_raw --cap-add=sys_nice \
    jasonish/suricata:latest

# 多个参数
docker run --net=host \
    -e SURICATA_OPTIONS="--af-packet=eth0 --runmode=workers" \
    --cap-add=net_admin --cap-add=net_raw --cap-add=sys_nice \
    jasonish/suricata:latest
```

### 其他环境变量

| 变量 | 用途 | 示例 |
|------|------|------|
| `PUID` | 容器内 Suricata 用户 UID | `PUID=$(id -u)` |
| `PGID` | 容器内 Suricata 用户 GID | `PGID=$(id -g)` |
| `ENABLE_CRON` | 启用 cron 服务 | `ENABLE_CRON=yes` |

## 🔄 Suricata-Update 规则更新

### 在线规则更新
在容器运行时更新规则是推荐的方法：

```bash
# 1. 启动 Suricata 容器（终端1）
docker run --name=suricata --rm -it --net=host \
    --cap-add=net_admin --cap-add=net_raw --cap-add=sys_nice \
    jasonish/suricata:latest -i eth0

# 2. 更新规则（终端2）
docker exec -it --user suricata suricata suricata-update -f

# 3. 重新加载规则（自动执行）
# suricatasc -c reload-rules 将自动执行
```

### 规则更新配置
容器内置 Suricata-Update 配置 (`/etc/suricata/update.yaml`):

```yaml
reload-command: suricatasc -c reload-rules
```

### 手动规则管理
```bash
# 列出可用规则源
docker exec -it suricata suricata-update list-sources

# 启用特定规则源
docker exec -it suricata suricata-update enable-source emerging-threats

# 更新并强制重新下载
docker exec -it suricata suricata-update -f --force

# 检查规则更新状态
docker exec -it suricata suricata-update check-versions
```

## 🍓 Raspberry Pi 支持

Raspberry Pi OS 可以使用此镜像，但由于系统兼容性问题，日志时间戳可能不正确。

**解决方案**：
```bash
# 方案1：使用特权模式
docker run --privileged --net=host \
    --cap-add=net_admin --cap-add=net_raw --cap-add=sys_nice \
    jasonish/suricata:latest -i eth0

# 方案2：升级 libseccomp2（推荐）
sudo apt update
sudo apt install -t buster-backports libseccomp2
```

## 📋 使用指南

### 配置初始化
生成默认配置文件到本地目录：

```bash
# 初始化配置
docker run --rm -it -v $(pwd)/etc:/etc/suricata \
    jasonish/suricata:latest -V

# 检查生成的配置文件
ls -la ./etc/
# suricata.yaml  classification.config  reference.config  rules/  ...
```

### 常见使用场景

**企业网络监控**：
```bash
# 多接口监控
docker run -d --name suricata-monitor --net=host \
    --cap-add=net_admin --cap-add=net_raw --cap-add=sys_nice \
    -v /opt/suricata/logs:/var/log/suricata \
    -v /opt/suricata/rules:/var/lib/suricata \
    -e SURICATA_OPTIONS="--af-packet=eth0,eth1 --runmode=workers" \
    jasonish/suricata:latest
```

**IPS 部署**：
```bash
# NFQueue IPS 模式
docker run -d --name suricata-ips --net=host \
    --cap-add=net_admin --cap-add=net_raw --cap-add=sys_nice \
    -v /var/log/suricata:/var/log/suricata \
    jasonish/suricata:latest -q 0
```

## 🔨 构建镜像

### 本地构建
本仓库的 Dockerfile 设计用于多架构自动化构建：

```bash
# 构建 AMD64 镜像
docker build --build-arg VERSION=$(cat VERSION) \
    --build-arg CORES=$(nproc) \
    -f Dockerfile.amd64 \
    -t suricata:local .

# 构建 ARM64 镜像（需要 QEMU 模拟）
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
docker build --build-arg VERSION=$(cat VERSION) \
    --build-arg CORES=$(nproc) \
    -f Dockerfile.arm64 \
    -t suricata:local-arm64 .
```

### 自动化构建脚本
```bash
# 使用构建脚本
./build.sh                    # 仅构建
./build.sh --push            # 构建并推送
./build.sh --push --manifest # 构建、推送并创建清单
```

### 构建要求

**系统依赖**：
- Docker 20.10+ 或 Podman 3.0+
- 多架构支持需要 QEMU
- 网络访问（下载源码和依赖）

**构建参数**：
| 参数 | 说明 | 默认值 |
|------|------|--------|
| `VERSION` | Suricata 版本 | 来自 VERSION 文件 |
| `CORES` | 编译并行数 | 2 |
| `CONFIGURE_ARGS` | 配置参数 | 空 |

## 🏗️ 镜像架构

### 多阶段构建
- **Builder 阶段**: AlmaLinux 9 + 完整编译环境
- **Runtime 阶段**: 精简运行时镜像 + 必要依赖

### 特性支持

| 特性 | AMD64 | ARM64 | 说明 |
|------|-------|-------|------|
| 基础检测 | ✅ | ✅ | 标准检测引擎 |
| Hyperscan | ✅ | ❌ | 高性能模式匹配（仅x86） |
| DPDK | ✅ | ✅ | 高速数据包处理 |
| eBPF | ✅ | ✅ | 内核旁路和过滤 |
| Redis | ✅ | ✅ | 外部数据存储 |
| GeoIP | ✅ | ✅ | 地理位置检测 |

## 📄 许可证

构建脚本、Dockerfile 和相关文件使用 MIT 许可证。Suricata 本身使用 GPL v2 许可证。

---

**维护者**: [Jason Ish](https://github.com/jasonish)  
**项目主页**: [Suricata](https://suricata.io)  
**源码仓库**: [OISF/suricata](https://github.com/OISF/suricata)
