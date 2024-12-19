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
#

function config_del(){
    yes="CONFIG_$1=y"
    no="# CONFIG_$1 is not set"

    sed -i "s/$yes/$no/" .config
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
#设置官方默认包https://downloads.immortalwrt.org/releases/23.05.4/targets/x86/64/profiles.json
default_packages=(
        "alsa-utils"
        "autocore"
        "automount"
        "base-files"
        "block-mount"
        "busybox"
        "ca-bundle"
        "default-settings-chn"
        "dnsmasq-full"
        "dropbear"
        "fdisk"
        "firewall4"
        "fstools"
        "grub2-bios-setup"
        "intel-igpu-firmware-dmc"
        "ipv6helper"
        "kmod-8139cp"
        "kmod-8139too"
        "kmod-ac97"
        "kmod-button-hotplug"
        "kmod-e1000e"
        "kmod-fs-f2fs"
        "kmod-i40e"
        "kmod-igb"
        "kmod-igbvf"
        "kmod-igc"
        "kmod-ixgbe"
        "kmod-ixgbevf"
        "kmod-nf-nathelper"
        "kmod-nf-nathelper-extra"
        "kmod-nft-offload"
        "kmod-pcnet32"
        "kmod-r8101"
        "kmod-r8125"
        "kmod-r8126"
        "kmod-r8168"
        "kmod-sound-hda-codec-hdmi"
        "kmod-sound-hda-codec-realtek"
        "kmod-sound-hda-codec-via"
        "kmod-sound-hda-core"
        "kmod-sound-hda-intel"
        "kmod-sound-i8x0"
        "kmod-sound-via82xx"
        "kmod-tulip"
        "kmod-usb-audio"
        "kmod-usb-hid"
        "kmod-usb-net"
        "kmod-usb-net-asix"
        "kmod-usb-net-asix-ax88179"
        "kmod-usb-net-rtl8150"
        "kmod-usb-net-rtl8152-vendor"
        "kmod-vmxnet3"
        "libc"
        "libgcc"
        "libustream-openssl"
        "logd"
        "luci"
        "luci-app-opkg"
        "luci-compat"
        "luci-lib-base"
        "luci-lib-ipkg"
        "mkf2fs"
        "mtd"
        "netifd"
        "nftables"
        "opkg"
        "partx-utils"
        "ppp"
        "ppp-mod-pppoe"
        "procd"
        "procd-seccomp"
        "procd-ujail"
        "uci"
        "uclient-fetch"
        "urandom-seed"
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

# 镜像生成
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

# 删除
# Sound Support
config_package_del kmod-sound-core
config_package_del kmod-ac97
config_package_del kmod-sound-hda-core
config_package_del kmod-sound-hda-codec-hdmi
config_package_del kmod-sound-hda-codec-realtek
config_package_del kmod-sound-hda-codec-via
config_package_del kmod-sound-hda-intel
config_package_del kmod-sound-i8x0
config_package_del kmod-sound-mpu401
config_package_del kmod-sound-via82xx
config_package_del kmod-usb-audio

# 新增
# Firmware
config_package_add intel-microcode
# luci
config_package_add luci
config_package_add default-settings-chn
# bbr
config_package_add kmod-tcp-bbr
# autocore + lm-sensors-detect： cpu 频率、温度
config_package_add autocore
config_package_add lm-sensors-detect
# bash
config_package_add bash
# 更改默认 Shell 为 bash
sed -i 's|/bin/ash|/usr/bin/bash|g' package/base-files/files/etc/passwd
# nano 替代 vim
config_package_add nano
# curl
config_package_add curl
# upnp
config_package_add luci-app-upnp
# tty 终端
config_package_add luci-app-ttyd
# tty 免登录
sed -i 's|/bin/login|/bin/login -f root|g' feeds/packages/utils/ttyd/files/ttyd.config
# kms
config_package_add luci-app-vlmcsd
# socat端口映射
config_package_add luci-app-socat

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

# 第三方软件包
mkdir -p package/custom
git clone --depth 1 https://github.com/DoTheBetter/OpenWrt-Packages.git package/custom
clean_packages package/custom

# golang
rm -rf feeds/packages/lang/golang
mv package/custom/golang feeds/packages/lang/

# argon 主题
config_package_add luci-theme-argon
# 修改默认主题
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile


## 定时任务。重启、关机、重启网络、释放内存、系统清理、网络共享、关闭网络、自动检测断网重连、MWAN3负载均衡检测重连、自定义脚本等10多个功能
config_package_add luci-app-autotimeset
config_package_add luci-lib-ipkg
## 分区扩容。一键自动格式化分区、扩容、自动挂载插件，专为OPENWRT设计，简化OPENWRT在分区挂载上烦锁的操作
config_package_add luci-app-partexp
#家长控制
config_package_add luci-app-parentcontrol

## iStore 应用市场 只支持 x86_64 和 arm64 设备
#git_sparse_clone main https://github.com/Lienol/openwrt-package luci-app-filebrowser luci-app-ssr-mudb-server
git_sparse_clone main https://github.com/linkease/istore-ui app-store-ui
git_sparse_clone main https://github.com/linkease/istore luci
config_package_add luci-app-store