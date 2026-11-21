#!/bin/bash
#
# diy-part1.sh — feeds update 之前执行
# 目标上游：immortalwrt/immortalwrt @ openwrt-24.10
#
# 说明：
#  * 不再 sed KERNEL_PATCHVER —— openwrt-24.10 原生就是 6.6。
#  * passwall / xray-core / sing-box / chinadns-ng / geoview / v2ray-plugin
#    / shadowsocks-rust / haproxy 全部由 ImmortalWrt 官方 feeds 提供，
#    不需要外挂 passwall 源。
#  * adguardhome 本体也在 ImmortalWrt 官方 packages 源里（0.107.57-r1）。
#  * 只有 AdGuardHome 的 LuCI 界面 luci-app-adguardhome 需要 kenzo 源。
#
set -e

echo "== 当前 feeds.conf.default =="
cat feeds.conf.default

# ---- kenzo 源：只为了 luci-app-adguardhome ----
if ! grep -q 'kenzok8/openwrt-packages' feeds.conf.default; then
    echo 'src-git kenzo https://github.com/kenzok8/openwrt-packages' >> feeds.conf.default
fi
if ! grep -q 'kenzok8/small' feeds.conf.default; then
    echo 'src-git small https://github.com/kenzok8/small' >> feeds.conf.default
fi

echo "== 追加后 =="
cat feeds.conf.default
