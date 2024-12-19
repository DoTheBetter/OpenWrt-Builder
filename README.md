# OpenWrt-Builder
基于 [ImmortalWrt](https://github.com/immortalwrt/immortalwrt) 定制编译的主路由、旁路网关，跟随 23.05 分支更新自动编译。

- [ImmortalWrt Firmware Download](https://downloads.immortalwrt.org/)
- [ImmortalWrt Firmware Selector](https://firmware-selector.immortalwrt.org/)

# 主路由 X86-64
## 定制内容
### 精简
1. 精简全部音频组件

### 添加

#### 软件：

1. 升级 golang 版本（geodata、xray 等依赖高版本 go）
2. 添加常用软件：bash、nano、curl

#### 服务：

1. 添加 upnp 服务
2. 添加 ttyd 服务
3. 添加 kms 服务
4. 添加 socat 服务
5. 添加家长控制parentcontrol
6. 添加多功能定时任务autotimeset
7. 添加分区扩容工具partexp
8. 添加 iStore 应用市场

#### 硬件驱动：

1. 添加虚拟机支持
2. 添加usb 2.0 3.0驱动
3. 添加usb网卡驱动

## 配置
1. 默认账号 `root`，密码 `password`。

2. 默认 LAN 口 IP 为 `192.168.10.1`。

通过命令行修改，重启后生效。在路由终端上按回车键，激活命令行。以下以将路由IP修改为192.168.5.1为例。

+ 首先，修改路由LAN的IP，输入命令如下：
```
uci set network.lan.ipaddr='192.168.5.1' 
uci commit network
```

+ 修改路由DHCP公开网关地址：

```
uci delete dhcp.lan.dhcp_option
uci add_list dhcp.lan.dhcp_option='6,192.168.5.1'
uci commit dhcp
```

+ 最后，重启路由。输入重启命令后等待约10s，路由会自动重启，全部步骤完成。

```
reboot
```