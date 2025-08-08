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

# Modify default IP
# sed -i 's/192.168.1.1/192.168.31.1/g' package/base-files/files/bin/config_generate

# Modify default theme
# sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# 修改默认主机名
# sed -i '/uci commit system/i\uci set system.@system[0].hostname='Mengluo_Router'' package/lean/default-settings/files/zzz-default-settings
 
# 加入编译者信息
# sed -i "s/OpenWrt /meng-luo build $(TZ=UTC-8 date "+%Y.%m.%d") @ OpenWrt /g" package/lean/default-settings/files/zzz-default-settings

# 自定义连接数
echo 'net.netfilter.nf_conntrack_max=262144' >> package/base-files/files/etc/sysctl.conf

## 更新 luci-theme-argon
# rm -rf feeds/luci/themes/luci-theme-argon
# rm -rf package/downloads/luci-theme-argon
# git clone -b 18.06 https://github.com/jerrykuku/luci-theme-argon.git package/downloads/luci-theme-argon
# git clone -b 18.06 https://github.com/jerrykuku/luci-theme-argon.git feeds/luci/themes/luci-theme-argon