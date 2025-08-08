# Suricata

[![Fuzzing Status](https://oss-fuzz-build-logs.storage.googleapis.com/badges/suricata.svg)](https://bugs.chromium.org/p/oss-fuzz/issues/list?sort=-opened&can=1&q=proj:suricata)
[![codecov](https://codecov.io/gh/OISF/suricata/branch/master/graph/badge.svg?token=QRyyn2BSo1)](https://codecov.io/gh/OISF/suricata)

## 项目简介

[Suricata](https://suricata.io) 是由[开源信息安全基金会 (OISF)](https://oisf.net) 和 Suricata 社区开发的高性能网络入侵检测系统 (IDS)、入侵防护系统 (IPS) 和网络安全监控 (NSM) 引擎。

### 🚀 核心特性

- **多线程架构**: 支持多核处理器，实现高性能数据包处理
- **实时威胁检测**: 基于签名的检测引擎，支持数万条规则并行匹配  
- **应用层深度检测**: 支持 HTTP、TLS、SSH、DNS、SMB 等 30+ 协议深度分析
- **灵活部署模式**: 支持 IDS（被动监控）、IPS（实时阻断）、NSM（安全监控）模式
- **丰富输出格式**: JSON (EVE)、传统日志、数据库、SIEM 集成等多种输出
- **高速网络接口**: 支持 DPDK、AF_XDP、PF_RING、Netmap 等高性能捕获技术

### 🔧 技术架构

**混合语言设计**：
- **C 语言核心**: 高性能数据包处理、流管理、检测引擎框架
- **Rust 组件**: 内存安全的协议解析器和应用层分析
- **现代化集成**: 通过 FFI 实现 C/Rust 无缝协作，兼顾性能与安全

**关键组件**：
- **检测引擎**: 多模式匹配 (MPM) + 预过滤器系统
- **流重组**: TCP 流跟踪和片段重组
- **应用层解析**: HTTP/2、QUIC、TLS 1.3、Kerberos 等现代协议支持
- **输出系统**: 结构化日志和告警，支持实时分析

### 📊 性能表现

- **吞吐量**: 在现代硬件上可处理 10+ Gbps 网络流量
- **延迟**: 微秒级检测响应时间
- **内存效率**: 优化的内存池和零拷贝技术
- **扩展性**: 支持数千个并发连接和大规模规则集

## 🏗️ 快速开始

### 系统要求

**支持的操作系统**:
- Linux (Ubuntu, CentOS, RHEL, Debian)
- FreeBSD, OpenBSD
- macOS (开发/测试)
- Windows (实验性支持)

**最低硬件配置**:
- CPU: 多核处理器（推荐 4+ 核心）
- RAM: 4GB+（大规模部署推荐 16GB+）
- 网络: 支持混杂模式的网卡

### 安装构建

#### Ubuntu/Debian 快速安装
```bash
# 安装依赖
sudo apt install -y autoconf automake build-essential cargo cbindgen \
    libjansson-dev libpcap-dev libpcre2-dev libtool libyaml-dev \
    make pkg-config rustc zlib1g-dev

# 从源码构建
git clone https://github.com/OISF/suricata.git
cd suricata
./autogen.sh
./configure --enable-warnings --enable-unittests
make -j$(nproc)
sudo make install-full
```

#### RHEL/CentOS/AlmaLinux
```bash
# 安装依赖
sudo dnf install -y rustc cargo cbindgen gcc gcc-c++ jansson-devel \
    libpcap-devel libyaml-devel make pcre2-devel zlib-devel

# 构建安装
./configure --enable-nfqueue --enable-warnings
make && sudo make install-full
```

### 基本使用

#### IDS 模式（被动监控）
```bash
# 从网络接口监控
sudo suricata -c /etc/suricata/suricata.yaml -i eth0

# 分析 PCAP 文件  
suricata -c /etc/suricata/suricata.yaml -r traffic.pcap
```

#### IPS 模式（实时阻断）
```bash
# NFQueue 模式（Linux）
sudo suricata -c /etc/suricata/suricata.yaml -q 0

# AF_PACKET 模式
sudo suricata -c /etc/suricata/suricata.yaml --af-packet
```

#### 高性能模式
```bash
# 使用 DPDK
sudo suricata -c /etc/suricata/suricata.yaml --dpdk

# 使用 AF_XDP  
sudo suricata -c /etc/suricata/suricata.yaml --af-xdp
```

## 📖 文档资源

- [官方主页](https://suricata.io)
- [用户指南](https://docs.suricata.io)
- [开发者指南](https://docs.suricata.io/en/latest/devguide/index.html)
- [安装手册](https://docs.suricata.io/en/latest/install.html)
- [配置参考](https://docs.suricata.io/en/latest/configuration/suricata-yaml.html)
- [规则编写](https://docs.suricata.io/en/latest/rules/index.html)
- [用户论坛](https://forum.suricata.io)
- [问题跟踪](https://redmine.openinfosecfoundation.org/projects/suricata)

## 🔧 开发与测试

### 开发环境搭建

#### 单元测试
```bash
# 启用单元测试构建
./configure --enable-unittests --enable-debug
make

# 运行所有单元测试
./src/suricata -u -l ./qa/log

# 运行特定测试
./src/suricata -u -U http                    # HTTP 相关测试
./src/suricata -u -U "detect.*tcp"           # TCP 检测测试
```

#### 代码格式化
```bash
# C 代码格式化（需要 clang-format 9+）
./scripts/clang-format.sh branch             # 格式化分支变更
./scripts/clang-format.sh check-branch       # 检查格式化

# Rust 代码格式化
cd rust/ && cargo fmt
```

#### 性能测试
```bash
# 使用 Suricata-Verify 集成测试套件
git clone https://github.com/OISF/suricata-verify.git verify
python ./verify/run.py

# CI 风格测试
./qa/travis.sh
```

### 代码架构概览

**目录结构**:
```
suricata/
├── src/                 # C 核心代码 (~900 个源文件)
│   ├── detect-*         # 检测引擎和规则处理
│   ├── app-layer-*      # 应用层协议解析
│   ├── decode-*         # 数据包解码器
│   ├── stream-*         # TCP 流重组
│   └── output-*         # 日志输出系统
├── rust/                # Rust 组件和协议解析器
│   ├── src/             # 核心 Rust 库
│   ├── htp/             # HTTP 解析器
│   └── derive/          # 代码生成宏
├── rules/               # 默认检测规则集
├── plugins/             # 插件系统
└── doc/                 # 完整文档
```

**关键技术栈**:
- **多模式匹配**: Aho-Corasick、Boyer-Moore、Hyperscan
- **协议解析**: nom (Rust)、自定义解析器
- **线程模型**: Workers、AutoFP、Single 模式
- **数据包捕获**: AF_PACKET、DPDK、PF_RING、Netmap
- **输出格式**: JSON (EVE)、传统日志、数据库

## 🤝 参与贡献

我们欢迎补丁和其他形式的贡献！请参阅我们的[贡献流程](https://docs.suricata.io/en/latest/devguide/contributing/contribution-process.html)了解如何开始。

### 质量保证流程

Suricata 是处理大量不可信输入的复杂软件，错误处理可能导致严重后果：

- **IPS 模式**: 崩溃可能导致网络中断
- **被动模式**: IDS 被攻破可能导致关键数据泄露  
- **检测遗漏**: 可能导致网络入侵未被发现

因此我们建立了严格的 QA 流程：

**自动化测试**:
- GitHub CI 自动检查
- 多平台构建测试（不同操作系统、编译器、优化级别）
- 静态代码分析（cppcheck、scan-build）
- 运行时分析（Valgrind、AddressSanitizer、LeakSanitizer）
- 回归测试套件

**深度测试**:
- 多 GB 级流量重放测试
- TB 级 PCAP 文件处理
- 长期模糊测试（数天到数周）
- 实时性能测试
- Unix 套接字测试

**审查流程**:
1. GitHub CI 自动检查
2. 团队和社区代码审查  
3. 私有 QA 环境测试（由于测试流量敏感性）
4. Coverity 扫描（合并后）

### 贡献者许可协议

我们要求签署贡献者许可协议以保持 Suricata 的所有权统一归属于开源信息安全基金会。详见：
- [开源信息](http://suricata.io/about/open-source/)
- [贡献协议](http://suricata.io/about/contribution-agreement/)

## 🌟 应用场景

### 网络安全监控
- **企业网络**: 监控内网异常流量和恶意活动
- **数据中心**: 保护云基础设施和虚拟化环境
- **工业控制系统**: 监控 OT/ICS 网络的专用协议
- **服务提供商**: 为客户提供网络安全服务

### 威胁检测能力  
- **恶意软件通信**: 检测 C&C 通信、数据外泄
- **网络扫描**: 识别端口扫描、漏洞探测
- **协议异常**: 发现协议滥用和隐蔽通道
- **加密流量分析**: 基于 TLS JA3/JA4 指纹识别

### 集成生态
- **SIEM 集成**: Splunk、ELK Stack、QRadar
- **威胁情报**: 支持 IOC 导入和威胁情报平台
- **自动化响应**: 与 SOAR 平台集成
- **可视化分析**: Grafana、Kibana 仪表板

## ❓ 常见问题

**问：我的 PR 会被接受吗？**

答：这取决于多个因素，包括代码质量。对于新功能，还取决于团队和社区是否认为该功能有用、对其他代码的影响程度、性能回退风险等。

**问：我的 PR 何时会被合并？**

答：这取决于具体情况。如果是重大功能或被认为是高风险变更，可能会进入下个主要版本。

**问：为什么我的 PR 被关闭了？**

答：如[Suricata GitHub 工作流](https://docs.suricata.io/en/latest/devguide/contributing/github-pr-workflow.html)所述，我们期望每个变更都提交新的 PR。

通常团队会对 PR 提供反馈，然后期望用改进的 PR 替换。请查看评论。如果没有评论就被关闭，可能是由于 QA 失败。

**问：编译器/代码分析工具报错了怎么办？**

答：为了协助 QA 自动化，我们不接受保留警告或错误。在某些情况下，我们可能会添加抑制（如 valgrind、DrMemory）。虽然有时令人沮丧，但我们更愿意重构代码来解决静态检查器的误报，而不是在输出中留下警告。

**问：我认为你们的 QA 测试有问题**

答：如果你真的这样认为，我们可以讨论如何改进。但不要过早下结论，更多时候是代码出了问题。

## 📊 项目统计

- **开发历史**: 2009年至今，15年持续开发
- **代码规模**: 200万+ 行代码（C + Rust）
- **协议支持**: 30+ 应用层协议深度解析
- **性能基准**: 10+ Gbps 处理能力
- **社区规模**: 全球数千家企业和组织使用
- **更新频率**: 定期发布安全更新和功能增强

---

**许可证**: GNU GPL v2.0  
**维护者**: [开源信息安全基金会 (OISF)](https://oisf.net)  
**最新版本**: 8.0.1-dev
