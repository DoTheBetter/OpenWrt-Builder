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

# 设置'root'密码为 'password'
sed -i 's/root:::0:99999:7:::/root:$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.::0:99999:7:::/g' package/base-files/files/etc/shadow
# 修改默认IP
sed -i 's/192.168.1.1/192.168.10.10/g' package/base-files/files/bin/config_generate
# 添加编译时间到版本信息
sed -i "s/DISTRIB_DESCRIPTION='.*'/DISTRIB_DESCRIPTION='${REPO_NAME} ${OpenWrt_VERSION} ${OpenWrt_ARCH} Built on $(date +%Y%m%d)'/" package/base-files/files/etc/openwrt_release

## 新增
## bbr
#config_package_add kmod-tcp-bbr
## autocore + lm-sensors-detect： cpu 频率、温度
#config_package_add autocore
#config_package_add lm-sensors-detect
## bash
#config_package_add bash
## 更改默认 Shell 为 bash
#sed -i 's|/bin/ash|/bin/bash|g' package/base-files/files/etc/passwd
## nano 替代 vim
#config_package_add nano
## curl
#config_package_add curl
## upnp
#config_package_add luci-app-upnp
## ipv6
#config_package_add ipv6helper
## tty 终端
#config_package_add luci-app-ttyd
## tty 免登录
#sed -i 's|/bin/login|/bin/login -f root|g' feeds/packages/utils/ttyd/files/ttyd.config
#
## kms
#config_package_add luci-app-vlmcsd
## socat端口映射
#config_package_add luci-app-socat
## ddns-go
#config_package_add luci-app-ddns-go
## openclash
#config_package_add luci-app-openclash
## homeproxy
#config_package_add luci-app-homeproxy
## smartdns
#config_package_add luci-app-smartdns
## adguardhome
#config_package_add adguardhome
#
##### 第三方软件包
#mkdir -p package/custom
#git clone --depth 1 https://github.com/DoTheBetter/OpenWrt-Packages.git package/custom
#clean_packages package/custom
#
## golang
#rm -rf feeds/packages/lang/golang
#mv package/custom/golang feeds/packages/lang/
#
## argon 主题
#config_package_add luci-theme-argon
## 修改默认主题
#sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile
#
### 定时任务。重启、关机、重启网络、释放内存、系统清理、网络共享、关闭网络、自动检测断网重连、MWAN3负载均衡检测重连、自定义脚本等10多个功能
#config_package_add luci-app-autotimeset
#config_package_add luci-lib-ipkg
#
##设置向导
#config_package_add luci-app-netwizard
##网络速度测试
#config_package_add luci-app-netspeedtest
