# Clash Meta 进阶配置指南

> 学会配置分流规则、策略组、DNS 和 TUN 模式，让你的 Clash 体验更上一层楼。

---

## 前置准备

- 已安装 Clash Meta 内核（或 Clash Verge / CFW 等图形化客户端）
- 已导入有效的机场订阅链接
- 了解基础操作（节点切换、开启代理）

---

## 一、理解分流规则

Clash 的核心能力是 **分流**——根据访问目标自动选择不同出口：

```
规则匹配流程（从上到下）：
 
  用户请求 → 遍历规则列表
     ├── 匹配到 DIRECT → 直连（国内网站）
     ├── 匹配到 Proxy  → 走代理（海外网站）
     ├── 匹配到 REJECT → 拒绝访问（广告）
     └── 无匹配 → 走默认策略（通常是 Proxy）
```

### 常见规则集

| 规则用途 | 说明 |
|:--------|:----|
| **国内直连** | 百度、淘宝、银行等走直连，不消耗流量 |
| **海外代理** | Google、YouTube、Netflix、ChatGPT 走代理 |
| **广告拦截** | 广告域名和 IP 直接拒绝 |
| **国际直连** | 部分 CDN 域名直连更快 |
| **国内 IP** | 目标 IP 是国内地址则直连 |

---

## 二、配置推荐

以下是一个经过优化的配置（可直接复制到 `config.yaml` 使用）：

### 2.1 基础配置

```yaml
mixed-port: 7890          # HTTP/SOCKS 混合代理端口
allow-lan: true           # 允许局域网连接
mode: Rule                # 规则模式（Rule/Script/Global/Direct）
log-level: info           # 日志级别

# 外部控制（用于面板管理）
external-controller: 0.0.0.0:9090
external-ui: /path/to/yacd  # 可选：YACD 面板路径
```

### 2.2 DNS 配置（防 DNS 泄露）

```yaml
dns:
  enable: true
  listen: 0.0.0.0:53
  default-nameserver:
    - 223.5.5.5    # 阿里 DNS
    - 114.114.114.114  # 114 DNS
  nameserver:
    - https://doh.pub/dns-query   # 腾讯 DNS over HTTPS
    - https://dns.alidns.com/dns-query  # 阿里 DoH
  fallback:                # 国外 DNS（用于判断是否为海外域名）
    - https://dns.google/dns-query
    - https://cloudflare-dns.com/dns-query
  fallback-filter:
    geoip: true            # 配合 GeoIP 判断
    ip-cidr:
      - 240.0.0.0/4        # 回退条件：返回了公网保留 IP
```

> 💡 **防 DNS 泄露**：国内域名用国内 DNS 解析，海外域名用海外 DNS 解析，避免 DNS 查询暴露你的代理行为。

### 2.3 代理组策略组

```yaml
proxy-groups:
  # 自动选择（延迟最低的节点）
  - name: 🚀 自动选择
    type: url-test
    proxies:
      - 你的机场节点名称（可填 * 通配）
    url: http://www.gstatic.com/generate_204
    interval: 300
    tolerance: 50

  # 手动选择
  - name: 🌍 手动切换
    type: select
    proxies:
      - 🚀 自动选择
      - 节点1
      - 节点2
      - DIRECT

  # 流媒体专用（解锁节点）
  - name: 🎬 流媒体
    type: select
    proxies:
      - 🚀 自动选择
      - 解锁节点名称
      - DIRECT

  # 全球直连
  - name: 🎯 全球直连
    type: select
    proxies:
      - DIRECT
      - 🌍 手动切换

  # 广告拦截
  - name: 🛑 广告拦截
    type: select
    proxies:
      - REJECT
      - DIRECT
```

### 2.4 规则配置（黑白名单）

```yaml
rules:
  # === 广告拦截 ===
  - DOMAIN-SUFFIX,doubleclick.net,🛑 广告拦截
  - DOMAIN-SUFFIX,googleadservices.com,🛑 广告拦截
  - DOMAIN-KEYWORD,adservice,🛑 广告拦截

  # === 流媒体 ===
  - DOMAIN-SUFFIX,netflix.com,🎬 流媒体
  - DOMAIN-SUFFIX,disneyplus.com,🎬 流媒体
  - DOMAIN-SUFFIX,hbo.com,🎬 流媒体
  - DOMAIN-SUFFIX,youtube.com,🎬 流媒体

  # === AI 工具 ===
  - DOMAIN-SUFFIX,chatgpt.com,🌍 手动切换
  - DOMAIN-SUFFIX,openai.com,🌍 手动切换
  - DOMAIN-SUFFIX,claude.ai,🌍 手动切换
  - DOMAIN-SUFFIX,anthropic.com,🌍 手动切换

  # === 常用海外服务 ===
  - DOMAIN-SUFFIX,google.com,🌍 手动切换
  - DOMAIN-SUFFIX,github.com,🌍 手动切换
  - DOMAIN-SUFFIX,twitter.com,🌍 手动切换

  # === 国内直连 ===
  - DOMAIN-SUFFIX,baidu.com,🎯 全球直连
  - DOMAIN-SUFFIX,taobao.com,🎯 全球直连
  - DOMAIN-SUFFIX,qq.com,🎯 全球直连
  - DOMAIN-SUFFIX,weixin.qq.com,🎯 全球直连

  # === IP 规则 ===
  - GEOIP,CN,🎯 全球直连  # 中国大陆 IP 直连

  # === 最终默认 ===
  - MATCH,🌍 手动切换      # 未匹配的走代理
```

---

## 三、启用 TUN 模式（全局代理）

TUN 模式可以让 **所有网络流量** 都经过 Clash，包括命令行、游戏、UWP 应用等非浏览器流量。

```yaml
tun:
  enable: true
  stack: system            # Windows 用 system，macOS/Linux 用 gvisor
  dns-hijack:
    - any:53               # 劫持所有 DNS 请求
  auto-route: true         # 自动路由
  auto-detect-interface: true  # 自动检测网卡
```

> ⚠️ TUN 模式会和 VPN 冲突，开启后不要同时使用其他 VPN 软件。

---

## 四、进阶技巧

### 4.1 节点延迟测试自动切换

```yaml
proxy-groups:
  - name: 🚀 故障转移
    type: fallback
    proxies:
      - 主节点
      - 备用节点1
      - 备用节点2
    url: http://www.gstatic.com/generate_204
    interval: 60
```

### 4.2 按时间自动切换

Clash Meta 支持 crontab 语法，可以设置白天用低延迟节点、晚上用大流量节点。

### 4.3 本地规则文件分类

建议将规则文件拆分为多个文件，方便维护：

```
rules/
├── direct.list         # 直连规则
├── proxy.list          # 代理规则
├── reject.list         # 广告拦截
└── streaming.list      # 流媒体
```

---

## 五、验证配置

配置生效后，用以下方式验证：

1. **DNS 检测**：访问 https://ipleak.net 确认 DNS 无泄露
2. **分流测试**：访问 `ip.sb` 看 IP 是否为代理节点 IP
3. **流媒体检测**：打开 Netflix 试看能否播放
4. **国内直连**：打开百度，速度应和不开代理一样

---

## 参考资源

- [Clash Meta 官方文档](https://docs.metacubex.one)
- [Clash 规则集推荐](https://github.com/Loyalsoldier/clash-rules)
- [机场推荐](../README.md#-热门推荐)

> 💡 配置过于复杂？选一家配置好订阅链接就能用的机场更省心 → [看看推荐](../README.md#-热门推荐)
