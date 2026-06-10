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
config_del TARGET_MULTI_PROFILE
config_del TARGET_DEVICE_mediatek_mt7986_DEVICE_glinet_gl-mt6000
config_del TARGET_DEVICE_mediatek_mt7986_DEVICE_tplink_tl-xdr6086
config_del TARGET_DEVICE_mediatek_mt7986_DEVICE_tplink_tl-xdr6088
config_del TARGET_DEVICE_mediatek_mt7986_DEVICE_xiaomi_redmi-router-ax6000-stock
config_del TARGET_ROOTFS_INITRAMFS
config_del TARGET_INITRAMFS_COMPRESSION_NONE

config_add TARGET_mediatek_mt7986_DEVICE_xiaomi_redmi-router-ax6000

# 设置'root'密码为 'password'
sed -i 's/root:::0:99999:7:::/root:$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.::0:99999:7:::/g' package/base-files/files/etc/shadow
# 修改默认IP
sed -i 's/192.168.6.1/192.168.31.1/g' package/base-files/files/bin/config_generate
# 添加编译时间到版本信息
sed -i "s/DISTRIB_DESCRIPTION='.*'/DISTRIB_DESCRIPTION='${REPO_NAME} ${OpenWrt_VERSION} ${OpenWrt_ARCH} Built on $(date +%Y%m%d)'/" package/base-files/files/etc/openwrt_release
# 修改wifi名称（mtwifi-cfg）
sed -i 's/ImmortalWrt-2.4G/Home-2.4G/g' package/mtk/applications/mtwifi-cfg/files/mtwifi.sh
sed -i 's/ImmortalWrt-5G/Home-5G/g' package/mtk/applications/mtwifi-cfg/files/mtwifi.sh
# 修改wifi默认密码'password'（mtwifi-cfg）
sed -i 's/encryption=none/encryption=psk2/' package/mtk/applications/mtwifi-cfg/files/mtwifi.sh
sed -i "/encryption=psk2/a\\\t\t\t\t\tset wireless.default_\${dev}.key=password" package/mtk/applications/mtwifi-cfg/files/mtwifi.sh

#### 新增
# sing-box内核支持
config_package_add kmod-netlink-diag
# bbr
config_package_add kmod-tcp-bbr
# autocore + lm-sensors-detect： cpu 频率、温度
config_package_add autocore-arm
config_package_add lm-sensors-detect
# bash
config_package_add bash
# 更改默认 Shell 为 bash
sed -i 's|/bin/ash|/bin/bash|g' package/base-files/files/etc/passwd
# nano 替代 vim
config_package_add nano
# curl
config_package_add curl
# tty 终端
config_package_add luci-app-ttyd
# tty 免登录
sed -i 's|/bin/login|/bin/login -f root|g' feeds/packages/utils/ttyd/files/ttyd.config
# kms
config_package_add luci-app-vlmcsd
# smartdns
#config_package_add luci-app-smartdns

#### 第三方软件包
mkdir -p package/custom
git clone -b OpenWrt-24.x --single-branch --depth 1 https://github.com/DoTheBetter/OpenWrt_Packages.git package/custom
clean_packages package/custom
# golang
rm -rf feeds/packages/lang/golang
mv package/custom/golang feeds/packages/lang/
# argon 主题
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile
config_package_add luci-theme-argon
config_package_add luci-app-argon-config
# Mihomo on OpenWrt
#config_package_add luci-app-nikki
# 内网穿透
config_package_add luci-app-easytier
# 软硬路由公网神器
config_package_add luci-app-lucky
# adguardhome
#config_package_add luci-app-adguardhome
# mosdns
config_package_add luci-app-mosdns
# 上网时间控制NFT版
config_package_add luci-app-nft-timecontrol
# 定时任务
config_package_add luci-app-taskplan
# 分区管理
#config_package_add luci-app-partexp
# 文件管理
config_package_add luci-app-fileassistant
# 设置向导
config_package_add luci-app-netwizard
