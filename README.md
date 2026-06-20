# OpenWrt-Builder
基于ImmortalWrt定制编译的主路由、旁路网关，跟随稳定分支更新自动编译。

本仓库地址：[https://github.com/DoTheBetter/OpenWrt-Builder](https://github.com/DoTheBetter/OpenWrt-Builder)

官方仓库地址：[https://github.com/immortalwrt/immortalwrt](https://github.com/immortalwrt/immortalwrt)

官方固件下载地址：
- [ImmortalWrt Firmware Download](https://downloads.immortalwrt.org/)
- [ImmortalWrt Firmware Selector](https://firmware-selector.immortalwrt.org/)

## 主路由

| 编译架构 | X86-64 | mt7986（红米redmi-ax6000） |
|---------|:-------|:-----------------|
| 编译信息 | 基于官方ImmortalWrt稳定分支 | 使用 [padavanonly/immortalwrt-mt798x-24.10](https://github.com/padavanonly/immortalwrt-mt798x-24.10) 仓库，搭配 [H大的不死u-boot](https://github.com/hanwckf/bl-mt798x) (immortalwrt-110m分区) |
| 精简内容 | 精简全部音频组件 | - |
| 软件配置 | • 升级golang版本<br>• 添加bash、nano、curl | • 升级golang版本<br>• 添加bash、nano、curl |
| 服务配置 | • upnp服务<br>• ttyd服务<br>• kms服务<br>• nikki服务<br>• easytier内网穿透<br>• lucky端口转发及反向代理<br>• DNS工具(adguardhome/smartdns/mosdns)<br>• nft-timecontrol上网时间控制<br>• taskplan多功能定时任务<br>• partexp分区扩容工具<br>• fileassistant文件管理 | • upnp服务<br>• ttyd服务<br>• kms服务<br>• nikki服务<br>• easytier内网穿透<br>• lucky端口转发及反向代理<br>• DNS工具(adguardhome/smartdns/mosdns)<br>• nft-timecontrol上网时间控制<br>• taskplan多功能定时任务<br>• fileassistant文件管理<br>• eqos-mtk网速控制（仓库默认）<br>• turboacc-mtk网络加速（仓库默认） |
| 硬件驱动 | • 虚拟机支持<br>• USB 2.0/3.0驱动<br>• USB网卡驱动 | • 使用[mtk-openwrt-feeds](https://git01.mediatek.com/plugins/gitiles/openwrt/feeds/mtk-openwrt-feeds/)提供的有线驱动、hnat驱动、内核补丁及配置工具，支持所有硬件加速特性<br />• mtwifi原厂无线驱动，支持warp在内的所有加速特性 |
| 默认配置 | • 账号：root<br>• 密码：password<br>• LAN口IP：192.168.10.1 | • 账号：root<br>• 密码：password<br>• WiFi密码：password<br>• LAN口IP：192.168.31.1 |

### IP地址修改说明
通过命令行修改，重启后生效。在路由终端上按回车键，激活命令行。以下以将路由IP修改为192.168.5.1为例。

1. 修改路由LAN的IP：
```
uci set network.lan.ipaddr='192.168.5.1/24' 
uci commit network
```

2. 修改路由DHCP公开网关地址：
```
uci delete dhcp.lan.dhcp_option
uci add_list dhcp.lan.dhcp_option='6,192.168.5.1'
uci commit dhcp
```

3. 重启路由使配置生效（等待约10s）：
```
reboot
```