# 路由器 OpenClash 配置指南

> 在 OpenWrt 路由器上使用 OpenClash 插件实现全局代理，让家里所有设备自动科学上网，无需每台设备单独配置。

---

## 适用场景

| 场景 | 效果 |
|:----|:----|
| 家人不会配置 | 路由器配好，全家设备自动走代理 |
| 游戏机/智能电视 | PS5、Switch、Apple TV 等无法安装客户端的设备 |
| 物联网设备 | 智能家居设备统一走指定线路 |
| 多设备管理 | 一次配置，全屋生效 |

---

## 前置条件

- ✅ 路由器已刷 **OpenWrt** 固件（或原生支持 OpenWrt）
- ✅ 路由器有足够的存储空间（建议 256MB+）
- ✅ 已准备好机场订阅链接（[还没机场？](../README.md#-热门推荐)）

---

## 第一步：安装 OpenClash

### 方法一：在线安装（推荐）

SSH 连接路由器后执行：

```bash
# 更新软件源
opkg update

# 安装依赖
opkg install coreutils-nohup bash iptables dnsmasq-full curl ca-bundle ca-certificates openssl-util ipset ip-full iptables-mod-tproxy iptables-mod-extra libcap libcap-bin ruby ruby-yaml kmod-tun luci-compat luci luci-base

# 下载并安装 OpenClash
cd /tmp
wget https://github.com/vernesong/OpenClash/releases/latest/download/luci-app-openclash_X.X.X_all.ipk
opkg install luci-app-openclash_*.ipk
```

### 方法二：固件自带

部分 OpenWrt 固件（如 Koolshare LEDE、ImmortalWrt）已内置 OpenClash，在 **「服务」** 菜单中可直接找到。

---

## 第二步：上传内核

OpenClash 需要 Clash 内核才能运行。安装后首次打开会自动提示下载内核：

1. 进入 **OpenWrt 管理后台** → **服务** → **OpenClash**
2. 如果提示「未检测到内核」，点击 **「自动下载」**
3. 选择对应架构的内核（路由器的 CPU 架构可以在 **系统** → **概览** 中查看）

> 💡 常见架构：x86_64（软路由）、ARMv8（红米AX6等）、ARMv7（K2P等）

---

## 第三步：导入订阅

1. 进入 **OpenClash** → **订阅设置**
2. 在 **「您的订阅链接」** 中粘贴机场订阅链接
3. 点击 **「添加」**
4. 点击 **「更新订阅」** 按钮拉取节点列表
5. 更新成功后，在 **「节点列表」** 中可以看到所有节点

---

## 第四步：基本配置

### 运行模式

进入 **OpenClash** → **全局设置** → **运行模式**：

| 模式 | 说明 | 推荐度 |
|:----|:----|:----:|
| **Fake-IP 混合** | 默认模式，兼容性最好 | ⭐⭐⭐⭐⭐ |
| Redir 模式 | 传统模式，较稳定 | ⭐⭐⭐⭐ |
| TUN 模式 | 最高兼容性，占用稍高 | ⭐⭐⭐⭐ |
| 绕过中国大陆 IP | 仅代理海外，国内直连 | ⭐⭐⭐⭐ |

**推荐新人选择：Fake-IP 混合模式**

### 策略组

进入 **「策略组」** 设置：

1. **默认策略组** → 选择手动或自动
2. **自动选择策略组** → 延迟测试 URL 保持默认
3. **流媒体策略组** → 指定使用解锁节点（如果有）

### DNS 设置

进入 **全局设置** → **DNS 设置**：

```
启用 DNS 劫持: ✅
DNS 模式: fake-ip
自定义上游 DNS:
  223.5.5.5          # 阿里
  114.114.114.114    # 114
  https://doh.pub/dns-query   # 腾讯 DoH
```

---

## 第五步：启动与验证

1. 回到 **OpenClash** 首页
2. 点击 **「启动」** 或 **「重启」** 按钮
3. 状态变为 **「运行中」** 即表示成功

**验证方法：**

| 操作 | 预期结果 |
|:----|:--------|
| 手机连接 Wi-Fi 后访问 google.com | ✅ 成功打开 |
| 访问 ip.sb 查看 IP | ✅ 显示代理节点 IP |
| 访问 baidu.com | ✅ 正常访问，直连 |
| 打开 Netflix App | ✅ 可正常播放 |
| 家人正常使用微信/抖音 | ✅ 不受影响 |

---

## 可选：精准分流规则

OpenClash 内置了规则集，也可以手动优化：

### 推荐配置

进入 **全局设置** → **规则设置**：

```
规则模式: 规则集
规则集提供: ACL4SSR
规则集:
  - 国内域名直连
  - 海外域名代理
  - 广告拦截（可选）
```

### 自定义规则

如果内置规则不够精确，可以在 **「自定义规则」** 中添加：

```yaml
# 加入购物车规则
- DOMAIN-SUFFIX,tmall.com,DIRECT
- DOMAIN-SUFFIX,jd.com,DIRECT

# ChatGPT 走指定节点
- DOMAIN-SUFFIX,chatgpt.com,🇯🇵 日本节点
- DOMAIN-SUFFIX,openai.com,🇯🇵 日本节点
```

---

## 常见问题

### ❓ 开启后部分国内网站打不开

- 尝试修改 **DNS 模式** 为 **redir-host**
- 检查规则集是否更新到最新
- 将出问题的域名添加到「白名单」

### ❓ 网速变慢

- 可能是选择了延迟高的节点，切换试试
- 关闭不必要的加密 DNS（如 DNS over HTTPS）
- 检查路由器的 CPU 占用是否过高

### ❓ 无法更新订阅

- 确认订阅链接未过期
- 检查路由器时间是否正确
- 手动在电脑上打开订阅链接验证是否可用

### ❓ 需求：仅部分设备走代理

在 **「访问控制」** → **「访问控制列表」** 中添加设备 MAC 地址，选择「仅代理列表中的设备」。

---

## 进阶：多线负载均衡

```yaml
proxy-groups:
  - name: "⚖️ 负载均衡"
    type: load-balance
    proxies:
      - 节点A
      - 节点B
    url: http://www.gstatic.com/generate_204
    interval: 300
```

适用于多条线路叠加，提高总带宽。

---

## 总结

```
路由器装 OpenClash ≈ 全屋设备无感科学上网
                        ↓
                一次配置，永久省心
                        ↓
         家人用微信/抖音 → 直连不绕路
         你看 Netflix/Google → 自动走代理
```

> 💡 **还没买机场？** 看看我们的 [热门推荐 →](../README.md#-热门推荐)
