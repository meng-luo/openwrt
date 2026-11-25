#!/bin/bash
#
# diy-part1.sh — feeds update 之前执行
# 目标上游：immortalwrt/immortalwrt @ tag v25.12.2（内核 6.12 LTS）
# 注意：从 release tag 构建，不是 openwrt-25.12 分支。
# 分支的 version.mk 默认值是 25.12-SNAPSHOT，且 apk 源会指向滚动目录。
#
# 说明：
#  * 不再 sed KERNEL_PATCHVER —— v25.12.2 原生就是 6.12。
#  * passwall / xray-core / sing-box / chinadns-ng / geoview / v2ray-plugin
#    / shadowsocks-rust / haproxy 全部由 ImmortalWrt 官方 feeds 提供，
#    不需要外挂 passwall 源。
#  * adguardhome 本体 + LuCI 界面（luci-app-adguardhome）在 25.12 里
#    全部由 ImmortalWrt 官方源提供 —— **不再需要任何外挂源**。
#
set -e

echo "== 当前 feeds.conf.default =="
cat feeds.conf.default

echo "== 追加后 =="
cat feeds.conf.default

# 说明：v25.12.2 的官方 feeds 已经覆盖全部所需包（87/87 已核对），
# 因此不再追加 kenzo / small 等外部源。
# 少一个外部源 = 少一个构建失败面。
