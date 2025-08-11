# CLAUDE.md

本文件为 Claude Code (claude.ai/code) 在此代码仓库中工作时提供指导。

## 构建命令

### 标准构建流程
```bash
# 生成构建系统
./autogen.sh

# 配置构建（推荐开发配置）
./configure --enable-warnings --enable-unittests --enable-debug

# 并行构建
make -j$(nproc)

# 安装并包含配置和规则
sudo make install-full
```

### 平台特定依赖

**Ubuntu/Debian**:
```bash
sudo apt install -y autoconf automake build-essential cargo cbindgen \
    libjansson-dev libpcap-dev libpcre2-dev libtool libyaml-dev \
    make pkg-config rustc zlib1g-dev
```

**RHEL/CentOS/AlmaLinux**:
```bash
sudo dnf install -y rustc cargo cbindgen gcc gcc-c++ jansson-devel \
    libpcap-devel libyaml-devel make pcre2-devel zlib-devel
```

## 测试命令

### 单元测试
```bash
# 启用单元测试构建
./configure --enable-unittests --enable-debug
make

# 运行所有单元测试
./src/suricata -u -l ./qa/log

# 运行特定测试类别
./src/suricata -u -U http                    # HTTP 相关测试
./src/suricata -u -U "detect.*tcp"           # TCP 检测测试
```

### 集成测试
```bash
# CI 风格综合测试
./qa/travis.sh

# 代码格式化检查（需要 clang-format 9+）
./scripts/clang-format.sh check-branch       # 检查格式化
./scripts/clang-format.sh branch             # 自动格式化变更
```

### Rust 组件测试
```bash
cd rust/
cargo test                                   # 运行 Rust 单元测试
cargo fmt                                    # 格式化 Rust 代码
cargo clippy                                 # Rust 代码检查
```

## 开发工作流

### 运行 Suricata
```bash
# IDS 模式（被动监控）
sudo suricata -c /etc/suricata/suricata.yaml -i eth0

# IPS 模式（主动阻断）
sudo suricata -c /etc/suricata/suricata.yaml -q 0

# PCAP 分析
suricata -c /etc/suricata/suricata.yaml -r traffic.pcap

# 高性能模式
sudo suricata -c /etc/suricata/suricata.yaml --af-xdp    # AF_XDP
sudo suricata -c /etc/suricata/suricata.yaml --dpdk      # DPDK
```

### Docker 开发
```bash
# 构建本地 Docker 镜像
cd docker/
./build.sh --arch amd64

# 使用自定义配置运行
docker run -d --name suricata-ids \
  --net=host \
  --cap-add=net_admin --cap-add=net_raw --cap-add=sys_nice \
  -v /data/suricata/config:/etc/suricata \
  -v /data/suricata/rules/rules:/etc/suricata/rules \
  -v /data/suricata/logs:/var/log/suricata \
  suricata:8.0.0-amd64 -i eth0
```

## 代码架构

### 高层结构
Suricata 是一个 C/Rust 混合代码库，专为高性能网络安全监控设计：

- **C 核心** (`src/`): 约900个源文件，实现检测引擎、流管理和核心数据包处理
- **Rust 组件** (`rust/`): 内存安全的协议解析器和应用层分析
- **FFI 集成**: 通过精心设计的接口实现 C/Rust 无缝互操作

### 关键子系统

**检测引擎** (`src/detect-*`):
- 多模式匹配 (MPM) 算法: Aho-Corasick、Boyer-Moore、Hyperscan
- 规则解析器和签名匹配
- 性能优化的预过滤器系统
- 200+ 种针对各种协议和行为的检测关键词

**流管理** (`src/flow-*`, `src/stream-*`):
- TCP 流重组和连接跟踪
- 流超时和内存管理
- 连接生命周期状态机
- 支持数百万并发流

**协议解析器** (`src/app-layer-*`, `rust/src/`):
- 30+ 种应用层协议 (HTTP、TLS、SSH、DNS、SMB 等)
- 基于 nom 组合子库的 Rust 解析器
- 协议检测和深度包检测
- 支持现代协议如 HTTP/2、QUIC、TLS 1.3

**输出系统** (`src/output-*`):
- EVE JSON 格式用于结构化日志
- 多种输出类型: 告警、流量、DNS、HTTP、TLS、文件日志
- 实时流和批处理
- 与 SIEM 系统和日志聚合器集成

**数据包捕获** (`src/source-*`, `src/runmode-*`):
- 多种捕获方法: AF_PACKET、DPDK、PF_RING、Netmap、AF_XDP
- 多线程处理模型 (workers、autofp)
- 高性能零拷贝技术
- 硬件卸载支持

### 线程架构
Suricata 使用复杂的多线程模型:

1. **捕获线程**: 从网络接口读取数据包
2. **解码/流线程**: 解析数据包并重组流
3. **检测线程**: 运行签名匹配和检测逻辑
4. **输出线程**: 写入日志和告警
5. **管理线程**: 处理流超时和维护任务

线程数量和 CPU 亲和性可根据系统资源和性能要求进行配置。

### Rust 集成策略
- **新协议**: 在 Rust 中实现以确保内存安全
- **传统协议**: 逐步将 C 解析器迁移到 Rust
- **性能关键路径**: 保持在优化的 C 中
- **共享数据结构**: 使用谨慎的 FFI 设计和适当的生命周期管理

### 内存管理
- **C 代码**: 手动内存管理，使用自定义分配器和内存池
- **Rust 代码**: 自动内存管理，零成本抽象
- **跨语言**: 在 FFI 边界处谨慎的所有权转移
- **流缓存**: LRU 缓存和内存压力处理

## 开发指南

### 代码质量要求
- 所有变更必须通过 CI 检查，包括单元测试、静态分析和格式化
- Valgrind/AddressSanitizer 检测到的内存泄漏将阻止合并
- 新协议应尽可能在 Rust 中实现
- 维护配置和规则的向后兼容性

### Rust 依赖
添加新 Rust 代码时，优先复用现有依赖:
- **解析**: nom7、regex
- **序列化**: serde、serde_json、base64
- **加密**: sha2、sha1、md-5、aes-gcm
- **压缩**: flate2、brotli、lzma-rs
- **协议**: 使用现有的 *-parser 库模式
- **CLI 工具**: clap、tracing

### 性能考虑
- Suricata 处理 10+ Gbps 流量，每微秒都很重要
- 使用真实流量负载对新代码路径进行性能分析
- 考虑多插槽系统的 NUMA 拓扑
- 应最小化快速路径中的内存分配
- 使用预过滤减少检测引擎负载

### 配置架构
主配置采用 YAML 格式 (`suricata.yaml`):
- **vars**: 网络地址和端口组
- **outputs**: EVE 日志配置和类型
- **app-layer**: 协议解析器设置
- **detect**: 检测引擎调优
- **threading**: CPU 亲和性和线程数量
- **capture**: 接口和捕获方法设置

规则从单独文件加载，可使用 suricata-update 通过威胁情报源自动更新进行管理。

## 数据外发模块

Suricata 支持多种数据外发方式，可将告警和日志数据发送到外部系统进行集中化分析和存储。

### 远程 Syslog 外发

远程 syslog 外发模块允许将 EVE 日志通过 UDP 或 TCP 协议发送到远程 syslog 服务器。

**配置示例**:
```yaml
- eve-log:
    enabled: yes
    filetype: remote-syslog
    remote-host: "192.168.1.100"
    remote-port: 514
    protocol: udp              # udp 或 tcp
    facility: daemon           # syslog 设施
    severity: warning          # syslog 严重级别
    identity: "suricata"       # syslog 标识
    event-types:              # 日志类型过滤器
      - alert
      - dns
      - http
    types:
      - alert
      - dns
      - http
```

**支持的协议**: UDP, TCP
**支持的设施**: kern, user, mail, daemon, auth, syslog, lpr, news, uucp, cron, authpriv, ftp, local0-local7
**支持的严重级别**: emerg, alert, crit, err, warning, notice, info, debug

### Kafka 外发

Kafka 外发模块使用简化的 Kafka 协议客户端，将 EVE 日志发送到 Kafka 消息队列系统。

**配置示例**:
```yaml
- eve-log:
    enabled: yes
    filetype: kafka
    brokers:
      - host: "192.168.1.101"
        port: 9092
      - host: "192.168.1.102"
        port: 9092
    topic: "suricata-alerts"
    client-id: "suricata-ids"
    compression: none          # none, gzip, snappy
    partition: -1              # -1 为自动分区
    event-types:              # 日志类型过滤器
      - alert
      - flow
      - tls
      - fileinfo
    types:
      - alert
      - flow
      - tls
      - fileinfo
```

**特性**:
- 支持多个 Kafka broker（自动故障转移）
- 支持 GZIP 和 Snappy 压缩
- 自动或手动分区选择
- 可配置的事件类型过滤

### 日志类型过滤

两种外发模块都支持 `event-types` 配置参数，用于筛选要发送的日志类型：

**可用的日志类型**:
- `alert`: 告警日志（安全事件）
- `flow`: 网络流量日志
- `dns`: DNS 查询和响应日志
- `http`: HTTP 事务日志
- `tls`: TLS/SSL 连接日志
- `fileinfo`: 文件传输日志
- `ssh`: SSH 连接日志
- `smtp`: SMTP 邮件日志
- `ftp`: FTP 连接日志
- `smb`: SMB/CIFS 协议日志

**配置说明**:
- 如果不配置 `event-types`，将发送所有类型的日志
- `event-types` 数组中列出的类型会被包含在外发中
- `types` 部分仍需配置相应的日志类型以确保生成这些日志

### 性能考虑

- **远程 Syslog**: 适用于低到中等流量环境，UDP 协议性能更好但可能丢包
- **Kafka**: 适用于高流量环境，支持批处理和压缩以提高性能
- 使用事件类型过滤可以显著减少网络流量和存储需求
- TCP 连接会在网络故障时自动重连