#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
# 参考：https://github.com/217heidai/OpenWrt-Builder

function config_del(){
    yes="CONFIG_$1=y"
    no="# CONFIG_$1 is not set"

    sed -i "s/$yes/$no/" .config

    if ! grep -q "$yes" .config; then
        echo "$no" >> .config
    fi
}

function config_add(){
    yes="CONFIG_$1=y"
    no="# CONFIG_$1 is not set"

    sed -i "s/${no}/${yes}/" .config

    if ! grep -q "$yes" .config; then
        echo "$yes" >> .config
    fi
}

function config_package_del(){
    package="PACKAGE_$1"
    config_del $package
}

function config_package_add(){
    package="PACKAGE_$1"
    config_add $package
}

function drop_package(){
    if [ "$1" != "golang" ];then
        # feeds/base -> package
        find package/ -follow -name $1 -not -path "package/custom/*" | xargs -rt rm -rf
        find feeds/ -follow -name $1 -not -path "feeds/base/custom/*" | xargs -rt rm -rf
    fi
}
function clean_packages(){
    path=$1
    dir=$(ls -l ${path} | awk '/^d/ {print $NF}')
    for item in ${dir}
        do
            drop_package ${item}
        done
}

# Git稀疏克隆，只克隆指定目录到本地
function git_sparse_clone() {
  branch="$1" repourl="$2" && shift 2
  git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl
  repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
  cd $repodir && git sparse-checkout set $@
  mv -f $@ ../package
  cd .. && rm -rf $repodir
}

##########################
#设置官方默认包https://downloads.immortalwrt.org/releases/25.12.0/targets/x86/64/profiles.json
default_packages=(
    "apk-openssl",
    "autocore",
    "automount",
    "base-files",
    "block-mount",
    "ca-bundle",
    "default-settings-chn",
    "dnsmasq-full",
    "dropbear",
    "fdisk",
    "firewall4",
    "fstools",
    "grub2-bios-setup",
    "i915-firmware-dmc",
    "kmod-8139cp",
    "kmod-8139too",
    "kmod-button-hotplug",
    "kmod-e1000e",
    "kmod-fs-f2fs",
    "kmod-i40e",
    "kmod-igb",
    "kmod-igbvf",
    "kmod-igc",
    "kmod-ixgbe",
    "kmod-ixgbevf",
    "kmod-nf-nathelper",
    "kmod-nft-offload",
    "kmod-pcnet32",
    "kmod-r8101",
    "kmod-r8125",
    "kmod-r8126",
    "kmod-r8168",
    "kmod-tulip",
    "kmod-usb-hid",
    "kmod-usb-net",
    "kmod-usb-net-asix",
    "kmod-usb-net-asix-ax88179",
    "kmod-usb-net-rtl8150",
    "kmod-usb-net-rtl8152-vendor",
    "kmod-vmxnet3",
    "libc",
    "libgcc",
    "libustream-openssl",
    "logd",
    "luci",
    "mkf2fs",
    "mtd",
    "netifd",
    "nftables",
    "odhcp6c",
    "odhcpd-ipv6only",
    "partx-utils",
    "ppp",
    "ppp-mod-pppoe",
    "procd-ujail",
    "uci",
    "uclient-fetch",
    "urandom-seed",
    "urngd"
)
# 循环调用 config_package_add 函数
for package in "${default_packages[@]}"; do
    config_package_add "$package"
done
################################################################

# 设置'root'密码为 'password'
sed -i 's/root:::0:99999:7:::/root:$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.::0:99999:7:::/g' package/base-files/files/etc/shadow
# 修改默认IP
sed -i 's/192.168.1.1/192.168.10.1/g' package/base-files/files/bin/config_generate
# 添加编译时间到 /etc/banner
sed -i '$ i\\ Build Time: '"$(date +%Y%m%d)"'' package/base-files/files/etc/banner

#### 镜像生成
# 修改分区大小
sed -i "/CONFIG_TARGET_KERNEL_PARTSIZE/d" .config
echo "CONFIG_TARGET_KERNEL_PARTSIZE=32" >> .config
sed -i "/CONFIG_TARGET_ROOTFS_PARTSIZE/d" .config
echo "CONFIG_TARGET_ROOTFS_PARTSIZE=2048" >> .config
# 调整 GRUB_TIMEOUT
sed -i "s/CONFIG_GRUB_TIMEOUT=\"3\"/CONFIG_GRUB_TIMEOUT=\"1\"/" .config
## 不生成 EXT4 硬盘格式镜像
config_del TARGET_ROOTFS_EXT4FS
## 不生成非 EFI 镜像
config_del GRUB_IMAGES

#### 删除
# Sound Support
config_package_del kmod-sound-core
# Video Support
config_package_del kmod-acpi-video
config_package_del kmod-backlight
config_package_del kmod-drm
config_package_del kmod-drm-buddy
config_package_del kmod-drm-display-helper
config_package_del kmod-drm-exec
config_package_del kmod-drm-i915
config_package_del kmod-drm-kms-helper
config_package_del kmod-drm-suballoc-helper
config_package_del kmod-drm-ttm
config_package_del kmod-drm-ttm-helper
config_package_del kmod-fb
config_package_del kmod-fb-cfb-copyarea
config_package_del kmod-fb-cfb-fillrect
config_package_del kmod-fb-cfb-imgblt
config_package_del kmod-fb-sys-fops
config_package_del kmod-fb-sys-ram
# Other
config_package_del luci-app-rclone_INCLUDE_rclone-webui
config_package_del luci-app-rclone_INCLUDE_rclone-ng

#### 新增
# Firmware
#config_package_add intel-microcode
# sing-box内核支持
config_package_add kmod-netlink-diag
# 设置 FULLCONENAT（全锥形 NAT）
config_package_add kmod-ipt-fullconenat
config_package_add iptables-mod-fullconenat
config_package_add ip6tables-mod-fullconenat
# luci
config_package_add luci
config_package_add default-settings-chn
# bbr
config_package_add kmod-tcp-bbr
# coremark cpu 跑分
config_package_add coremark
# autocore + lm-sensors-detect： cpu 频率、温度
config_package_add autocore
config_package_add lm-sensors-detect
# bash
config_package_add bash
# 更改默认 Shell 为 bash
sed -i 's|/bin/ash|/bin/bash|g' package/base-files/files/etc/passwd
# nano 替代 vim
config_package_add nano
# curl
config_package_add curl
# 解压工具 unzip
config_package_add unzip
# upnp
config_package_add luci-app-upnp
# tty 终端
config_package_add luci-app-ttyd
# tty 免登录
sed -i 's|/bin/login|/bin/login -f root|g' feeds/packages/utils/ttyd/files/ttyd.config

# 宽带聚合
#config_package_add luci-app-mwan3
# kms
config_package_add luci-app-vlmcsd
# smartdns
#config_package_add luci-app-smartdns
# 应用过滤
#config_package_add luci-app-appfilter
# 内网穿透
config_package_add luci-app-zerotier

#硬件及驱动
# 虚拟机支持
config_package_add qemu-ga
# usb 2.0 3.0 支持
config_package_add kmod-usb2
config_package_add kmod-usb3
# usb 网络支持
config_package_add usbmuxd
config_package_add usbutils
config_package_add usb-modeswitch
config_package_add kmod-usb-serial
config_package_add kmod-usb-serial-option
config_package_add kmod-usb-net-rndis
config_package_add kmod-usb-net-ipheth

#### 第三方软件包
mkdir -p package/custom
git clone -b OpenWrt-25.x --single-branch --depth 1 https://github.com/DoTheBetter/OpenWrt_Packages.git package/custom
clean_packages package/custom
# golang
rm -rf feeds/packages/lang/golang
mv package/custom/golang feeds/packages/lang/
# argon 主题
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile
config_package_add luci-theme-argon
config_package_add luci-app-argon-config

# 内网穿透
config_package_add luci-app-easytier
config_package_add easytier
# 软硬路由公网神器
config_package_add luci-app-lucky
# adguardhome
#config_package_add luci-app-adguardhome
# 上网时间控制NFT版
config_package_add luci-app-nft-timecontrol
# 定时任务
config_package_add luci-app-taskplan
# 分区管理
#config_package_add luci-app-partexp
# 文件管理
config_package_add luci-app-fileassistant
# 设置向导
#config_package_add luci-app-netwizard

############
# Mihomo on OpenWrt
#git clone https://github.com/nikkinikki-org/OpenWrt-nikki.git package/nikki
#config_package_add luci-app-nikki
# mosdns
rm -rf feeds/packages/net/v2ray-geodata
git clone https://github.com/sbwml/luci-app-mosdns -b v5 package/mosdns
git clone https://github.com/sbwml/v2ray-geodata package/v2ray-geodata
config_package_add luci-app-mosdns